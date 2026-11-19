-- Q1. Overdue books today (uses view)
SELECT * FROM v_overdue_loans ORDER BY days_overdue DESC;

-- Q2. Overdue, same result without the view: members + contact to chase
SELECT m.full_name, m.email, r.title, l.due_date,
       CAST(julianday('now') - julianday(l.due_date) AS INTEGER) AS days_overdue
FROM loan l
JOIN member m ON m.member_id = l.member_id
JOIN item i ON i.item_id = l.item_id
JOIN resource r ON r.resource_id = i.resource_id
WHERE l.return_date IS NULL AND l.due_date < date('now');

-- Q3. Frequently borrowed resources (top 5)
SELECT title, resource_type, category, times_borrowed
FROM v_resource_popularity
ORDER BY times_borrowed DESC, title
LIMIT 5;

-- Q4. Members with unpaid fines
SELECT member_id, full_name, unpaid_fines FROM v_member_activity
WHERE unpaid_fines > 0 ORDER BY unpaid_fines DESC;

-- Q5. CTE: monthly circulation with running total
WITH monthly AS (
    SELECT strftime('%Y-%m', issue_date) AS month, COUNT(*) AS loans
    FROM loan GROUP BY month
)
SELECT month, loans, SUM(loans) OVER (ORDER BY month) AS running_total
FROM monthly ORDER BY month;

-- Q6. CTE: most borrowed resource in each category
WITH counts AS (
    SELECT category, title, times_borrowed,
           RANK() OVER (PARTITION BY category ORDER BY times_borrowed DESC) AS rnk
    FROM v_resource_popularity
)
SELECT category, title, times_borrowed FROM counts WHERE rnk = 1 AND times_borrowed > 0;

-- Q7. CTE: late-return behaviour per membership type
WITH late AS (
    SELECT m.type_id, COUNT(f.fine_id) AS late_returns, AVG(f.days_late) AS avg_days_late
    FROM fine f JOIN loan l ON l.loan_id = f.loan_id JOIN member m ON m.member_id = l.member_id
    GROUP BY m.type_id
), total AS (
    SELECT m.type_id, COUNT(*) AS all_loans
    FROM loan l JOIN member m ON m.member_id = l.member_id GROUP BY m.type_id
)
SELECT mt.type_name, t.all_loans, COALESCE(l.late_returns,0) AS late_returns,
       ROUND(100.0 * COALESCE(l.late_returns,0) / t.all_loans, 1) AS late_pct,
       ROUND(l.avg_days_late, 1) AS avg_days_late
FROM membership_type mt JOIN total t ON t.type_id = mt.type_id LEFT JOIN late l ON l.type_id = mt.type_id;

-- Q8. Physical vs digital usage
SELECT resource_type, COUNT(*) AS loans FROM v_loan_detail GROUP BY resource_type;

-- Q9. Resources never borrowed (collection review)
SELECT title FROM v_resource_popularity WHERE times_borrowed = 0;

-- Q10. Reservations waiting where no copy is available
SELECT r.reservation_id, m.full_name, rs.title
FROM reservation r
JOIN member m ON m.member_id = r.member_id
JOIN resource rs ON rs.resource_id = r.resource_id
WHERE r.status = 'PENDING'
  AND NOT EXISTS (SELECT 1 FROM item i WHERE i.resource_id = r.resource_id AND i.status = 'AVAILABLE');

-- Q11. Repeat borrowers (3+ loans) - CTE
WITH freq AS (SELECT member_id, COUNT(*) AS n FROM loan GROUP BY member_id)
SELECT m.full_name, f.n AS loans FROM freq f JOIN member m ON m.member_id = f.member_id
WHERE f.n >= 3 ORDER BY f.n DESC;

-- Q12. Proof the index is used for the overdue search
EXPLAIN QUERY PLAN
SELECT loan_id FROM loan WHERE return_date IS NULL AND due_date < date('now');
