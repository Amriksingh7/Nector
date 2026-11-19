# Intelligent Library and Digital Resource Management System

## Files
| File | Purpose |
|---|---|
| `ER_diagram.mermaid` | ER diagram (paste into https://mermaid.live to export PNG/SVG for the report) |
| `01_schema.sql` | Tables, keys, constraints, indexes, triggers, views |
| `02_sample_data.sql` | Sample publishers, authors, resources, members, loans, fines |
| `03_queries.sql` | Overdue, frequently-borrowed and analytics queries (views + CTEs) |
| `run_all.py` | Builds the DB in SQLite and prints every query result |

Run: `python3 run_all.py`  (or `sqlite3 library.db < 01_schema.sql` then the other two files).

## Entities and relationships
- Publisher 1:N Resource, Category 1:N Resource
- Resource M:N Author (resolved by `resource_author`)
- Resource 1:N Item (a physical copy has a barcode, a digital licence has an access URL)
- MembershipType 1:N Member; Member 1:N Loan; Item 1:N Loan
- Member 1:N Reservation; Resource 1:N Reservation
- Loan 1:0..1 Fine

## Keys
| Table | Primary key | Foreign keys | Candidate (alternate) keys |
|---|---|---|---|
| publisher | publisher_id | - | name, email |
| author | author_id | - | (first_name, last_name, country) |
| category | category_id | - | name |
| resource | resource_id | publisher_id, category_id | isbn |
| resource_author | (resource_id, author_id) | resource_id, author_id | - |
| item | item_id | resource_id | barcode, access_url |
| membership_type | type_id | - | type_name |
| member | member_id | type_id | email, phone |
| loan | loan_id | member_id, item_id | - |
| reservation | reservation_id | member_id, resource_id | - |
| fine | fine_id | loan_id | loan_id (UNIQUE: one fine per loan) |

## Normalization (to 3NF)
**Unnormalized idea:** one big sheet `Library(book_title, isbn, authors, publisher, publisher_city, category, copy_barcode, member_name, member_email, membership_type, max_loans, fine_per_day, issue_date, due_date, return_date, fine_amount)`.

- **1NF:** `authors` held several values in one cell, so authors moved to their own table, linked by `resource_author`. Every column is now atomic.
- **2NF:** in `resource_author` the key is (resource_id, author_id); the only extra column, `author_order`, depends on the whole key. Book details (title, isbn) depend only on `resource_id`, so they stay in `resource`, not in the loan or author tables.
- **3NF:** transitive dependencies removed:
  - `publisher_city` depends on publisher, not on the book, so `publisher` is a separate table.
  - `max_loans, loan_days, fine_per_day` depend on the membership type, not on the member, so `membership_type` is separate.
  - `loan` stores only `item_id`; the title is reached through `item -> resource` instead of being repeated in each loan row.
  - `fine` is separate from `loan` because it exists only for late returns (avoids many NULL columns).
- Result: each fact is stored once, so updating a publisher city or a fine rate changes exactly one row.

## Analytics design
- **Views:** `v_loan_detail`, `v_overdue_loans`, `v_resource_popularity`, `v_member_activity`.
- **CTEs:** monthly circulation with running total (Q5), top resource per category (Q6), late-return rate per membership type (Q7), repeat borrowers (Q11).
- **Indexes:** `idx_loan_return_due (return_date, due_date)` serves the overdue search (Q12 shows `SEARCH ... USING COVERING INDEX`); `idx_loan_item`, `idx_loan_member`, `idx_item_resource` serve the popularity and member joins.
- **Triggers:** issuing a loan marks the copy `ON_LOAN`; returning it marks it `AVAILABLE` and creates a fine automatically if the return is late (days late x the member type's fine_per_day).

## Using MySQL or PostgreSQL instead
- `INTEGER PRIMARY KEY` -> `INT AUTO_INCREMENT PRIMARY KEY` (MySQL) / `SERIAL` or `GENERATED ... AS IDENTITY` (PostgreSQL); `TEXT` dates -> `DATE`.
- `date('now')` -> `CURDATE()` / `CURRENT_DATE`; `julianday(a)-julianday(b)` -> `DATEDIFF(a,b)` / `a - b`; `strftime('%Y-%m', d)` -> `DATE_FORMAT(d,'%Y-%m')` / `TO_CHAR(d,'YYYY-MM')`.
- Triggers use each system's own syntax (`DELIMITER`, `FOR EACH ROW`).
