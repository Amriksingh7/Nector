-- Intelligent Library and Digital Resource Management System
-- Dialect: SQLite 3.25+ (tested). MySQL/PostgreSQL notes are in README.md
PRAGMA foreign_keys = ON;

CREATE TABLE publisher (
    publisher_id  INTEGER PRIMARY KEY,
    name          TEXT NOT NULL UNIQUE,
    city          TEXT,
    email         TEXT UNIQUE
);

CREATE TABLE author (
    author_id   INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    country     TEXT,
    UNIQUE (first_name, last_name, country)
);

CREATE TABLE category (
    category_id  INTEGER PRIMARY KEY,
    name         TEXT NOT NULL UNIQUE
);

-- A "resource" is the title (book / e-book). Physical copies and digital
-- licences are stored separately in ITEM.
CREATE TABLE resource (
    resource_id      INTEGER PRIMARY KEY,
    title            TEXT NOT NULL,
    isbn             TEXT UNIQUE,                       -- candidate key
    resource_type    TEXT NOT NULL CHECK (resource_type IN ('PHYSICAL','DIGITAL')),
    publisher_id     INTEGER NOT NULL REFERENCES publisher(publisher_id),
    category_id      INTEGER NOT NULL REFERENCES category(category_id),
    publication_year INTEGER CHECK (publication_year BETWEEN 1400 AND 2100),
    language         TEXT NOT NULL DEFAULT 'English'
);

-- M:N between resource and author
CREATE TABLE resource_author (
    resource_id   INTEGER NOT NULL REFERENCES resource(resource_id) ON DELETE CASCADE,
    author_id     INTEGER NOT NULL REFERENCES author(author_id),
    author_order  INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (resource_id, author_id)
);

-- One row per physical copy (barcode) or digital access licence (access_url)
CREATE TABLE item (
    item_id         INTEGER PRIMARY KEY,
    resource_id     INTEGER NOT NULL REFERENCES resource(resource_id),
    barcode         TEXT UNIQUE,                         -- candidate key (physical)
    shelf_location  TEXT,
    access_url      TEXT UNIQUE,                         -- candidate key (digital)
    status          TEXT NOT NULL DEFAULT 'AVAILABLE'
                    CHECK (status IN ('AVAILABLE','ON_LOAN','LOST','DAMAGED')),
    CHECK (barcode IS NOT NULL OR access_url IS NOT NULL)
);

CREATE TABLE membership_type (
    type_id       INTEGER PRIMARY KEY,
    type_name     TEXT NOT NULL UNIQUE,
    max_loans     INTEGER NOT NULL CHECK (max_loans > 0),
    loan_days     INTEGER NOT NULL CHECK (loan_days > 0),
    fine_per_day  REAL    NOT NULL CHECK (fine_per_day >= 0),
    annual_fee    REAL    NOT NULL DEFAULT 0
);

CREATE TABLE member (
    member_id    INTEGER PRIMARY KEY,
    full_name    TEXT NOT NULL,
    email        TEXT NOT NULL UNIQUE,                   -- candidate key
    phone        TEXT UNIQUE,                            -- candidate key
    join_date    TEXT NOT NULL,
    expiry_date  TEXT NOT NULL,
    type_id      INTEGER NOT NULL REFERENCES membership_type(type_id),
    status       TEXT NOT NULL DEFAULT 'ACTIVE'
                 CHECK (status IN ('ACTIVE','EXPIRED','SUSPENDED')),
    CHECK (expiry_date >= join_date)
);

-- Circulation (issue / return)
CREATE TABLE loan (
    loan_id      INTEGER PRIMARY KEY,
    member_id    INTEGER NOT NULL REFERENCES member(member_id),
    item_id      INTEGER NOT NULL REFERENCES item(item_id),
    issue_date   TEXT NOT NULL,
    due_date     TEXT NOT NULL,
    return_date  TEXT,                                   -- NULL = still out
    CHECK (due_date >= issue_date),
    CHECK (return_date IS NULL OR return_date >= issue_date)
);

CREATE TABLE reservation (
    reservation_id  INTEGER PRIMARY KEY,
    member_id       INTEGER NOT NULL REFERENCES member(member_id),
    resource_id     INTEGER NOT NULL REFERENCES resource(resource_id),
    reserved_on     TEXT NOT NULL,
    expires_on      TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING','FULFILLED','CANCELLED','EXPIRED')),
    CHECK (expires_on >= reserved_on)
);

-- Penalty for a late return (one fine per loan)
CREATE TABLE fine (
    fine_id      INTEGER PRIMARY KEY,
    loan_id      INTEGER NOT NULL UNIQUE REFERENCES loan(loan_id),
    days_late    INTEGER NOT NULL CHECK (days_late > 0),
    amount       REAL    NOT NULL CHECK (amount >= 0),
    assessed_on  TEXT NOT NULL,
    paid_on      TEXT                                    -- NULL = unpaid
);

-- ---------- Indexes (support the analytics queries) ----------
CREATE INDEX idx_loan_member      ON loan(member_id);
CREATE INDEX idx_loan_item        ON loan(item_id);
CREATE INDEX idx_loan_return_due  ON loan(return_date, due_date);   -- overdue search
CREATE INDEX idx_item_resource    ON item(resource_id);
CREATE INDEX idx_resource_cat     ON resource(category_id);
CREATE INDEX idx_resauthor_author ON resource_author(author_id);
CREATE INDEX idx_reservation_res  ON reservation(resource_id, status);
CREATE INDEX idx_fine_unpaid      ON fine(paid_on);

-- ---------- Triggers: automate circulation rules ----------
-- Issue: physical copy becomes ON_LOAN
CREATE TRIGGER trg_loan_issue AFTER INSERT ON loan
WHEN NEW.return_date IS NULL
BEGIN
    UPDATE item SET status = 'ON_LOAN'
    WHERE item_id = NEW.item_id AND barcode IS NOT NULL;
END;

-- Return: copy becomes AVAILABLE; late return creates a fine
CREATE TRIGGER trg_loan_return AFTER UPDATE OF return_date ON loan
WHEN OLD.return_date IS NULL AND NEW.return_date IS NOT NULL
BEGIN
    UPDATE item SET status = 'AVAILABLE'
    WHERE item_id = NEW.item_id AND status = 'ON_LOAN';

    INSERT INTO fine (loan_id, days_late, amount, assessed_on)
    SELECT NEW.loan_id,
           CAST(julianday(NEW.return_date) - julianday(NEW.due_date) AS INTEGER),
           CAST(julianday(NEW.return_date) - julianday(NEW.due_date) AS INTEGER) * mt.fine_per_day,
           NEW.return_date
    FROM member m JOIN membership_type mt ON mt.type_id = m.type_id
    WHERE m.member_id = NEW.member_id
      AND NEW.return_date > NEW.due_date;
END;

-- ---------- Views for analytics ----------
CREATE VIEW v_loan_detail AS
SELECT l.loan_id, l.member_id, m.full_name, l.item_id, r.resource_id, r.title,
       r.resource_type, c.name AS category, l.issue_date, l.due_date, l.return_date
FROM loan l
JOIN member   m ON m.member_id   = l.member_id
JOIN item     i ON i.item_id     = l.item_id
JOIN resource r ON r.resource_id = i.resource_id
JOIN category c ON c.category_id = r.category_id;

CREATE VIEW v_overdue_loans AS
SELECT d.loan_id, d.full_name, d.title, d.resource_type, d.due_date,
       CAST(julianday('now') - julianday(d.due_date) AS INTEGER) AS days_overdue,
       CAST(julianday('now') - julianday(d.due_date) AS INTEGER) * mt.fine_per_day AS fine_so_far
FROM v_loan_detail d
JOIN member m ON m.member_id = d.member_id
JOIN membership_type mt ON mt.type_id = m.type_id
WHERE d.return_date IS NULL AND d.due_date < date('now');

CREATE VIEW v_resource_popularity AS
SELECT r.resource_id, r.title, r.resource_type, c.name AS category,
       COUNT(l.loan_id) AS times_borrowed
FROM resource r
JOIN category c ON c.category_id = r.category_id
LEFT JOIN item i ON i.resource_id = r.resource_id
LEFT JOIN loan l ON l.item_id = i.item_id
GROUP BY r.resource_id;

CREATE VIEW v_member_activity AS
SELECT m.member_id, m.full_name, mt.type_name,
       COUNT(l.loan_id) AS total_loans,
       SUM(CASE WHEN l.return_date IS NULL THEN 1 ELSE 0 END) AS loans_open,
       COALESCE((SELECT SUM(f.amount) FROM fine f JOIN loan l2 ON l2.loan_id = f.loan_id
                 WHERE l2.member_id = m.member_id AND f.paid_on IS NULL), 0) AS unpaid_fines
FROM member m
JOIN membership_type mt ON mt.type_id = m.type_id
LEFT JOIN loan l ON l.member_id = m.member_id
GROUP BY m.member_id;
