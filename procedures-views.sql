-- 3. PROCEDURES

--a. Insert a return record using issued_id
CREATE OR REPLACE PROCEDURE add_return_record(
    p_return_id VARCHAR,
    p_issued_id VARCHAR,
    p_condition TEXT DEFAULT 'Good'
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO return_status(return_id, issued_id, return_book_name, return_date, return_book_isbn, return_condition)
    SELECT 
        p_return_id,
        i.issued_id,
        i.issued_book_name,
        CURRENT_DATE,
        i.issued_book_isbn,
        p_condition
    FROM issued_status i
    WHERE i.issued_id = p_issued_id;
END;
$$;

CALL add_return_record('RS300', 'IS200');

--b. Delete members who haven't issued any book
CREATE OR REPLACE PROCEDURE delete_inactive_members()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM members
    WHERE member_id NOT IN (
        SELECT DISTINCT issued_member_id FROM issued_status
    );
END;
$$;

CALL delete_inactive_members();

--c. Update book status (e.g. set to 'no' if returned)
CREATE OR REPLACE PROCEDURE update_book_status_on_return(p_isbn VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE books
    SET status = 'no'
    WHERE isbn = p_isbn;
END;
$$;

CALL update_book_status_on_return('978-0-14-044913-6');

--d. Procedure to Mark a Book as Returned
CREATE OR REPLACE PROCEDURE mark_book_returned(p_isbn VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE books
    SET status = 'yes'
    WHERE isbn = p_isbn;
END;
$$;

CALL mark_book_returned('RS140');

--e. Procedure to Assign Employee to a Branch
CREATE OR REPLACE PROCEDURE assign_employee_branch(p_emp_id VARCHAR, p_branch_id VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees
    SET branch_id = p_branch_id
    WHERE emp_id = p_emp_id;
END;
$$;

CALL assign_employee_branch('E105', 'B02');

--4. VIEWS

--a.View of Members with Currently Issued Books
CREATE VIEW currently_issued_books AS
SELECT 
    m.member_id,
    m.member_name,
    i.issued_id,
    i.issued_date,
    b.book_title
FROM issued_status i
JOIN members m ON i.issued_member_id = m.member_id
JOIN books b ON i.issued_book_isbn = b.isbn
WHERE b.status = 'no';

SELECT * FROM currently_issued_books;

--b. Active members view (issued books in last 30 days)
CREATE OR REPLACE VIEW active_members_view AS
SELECT DISTINCT m.*
FROM members m
JOIN issued_status i ON m.member_id = i.issued_member_id
WHERE i.issued_date >= CURRENT_DATE - INTERVAL '30 days';

SELECT * FROM active_members_view;

--c. Return summary view
CREATE OR REPLACE VIEW return_summary_view AS
SELECT 
    r.return_id,
    r.return_date,
    r.return_condition,
    m.member_name,
    b.book_title
FROM return_status r
JOIN issued_status i ON r.issued_id = i.issued_id
JOIN members m ON i.issued_member_id = m.member_id
JOIN books b ON i.issued_book_isbn = b.isbn;

SELECT * FROM return_summary_view;

--d. View of Employee Issuance Stats
CREATE VIEW employee_issue_count AS
SELECT 
    e.emp_id,
    e.emp_name,
    COUNT(i.issued_id) AS total_issued
FROM employees e
LEFT JOIN issued_status i ON e.emp_id = i.issued_emp_id
GROUP BY e.emp_id, e.emp_name;

SELECT * FROM employee_issue_count;

--e. Detailed Issued Book Info
CREATE VIEW issued_books_details AS
SELECT
    ist.issued_id,
    m.member_name,
    b.book_title,
    ist.issued_date,
    e.emp_name AS issued_by,
    br.branch_address
FROM issued_status ist
JOIN books b ON ist.issued_book_isbn = b.isbn
JOIN members m ON ist.issued_member_id = m.member_id
JOIN employees e ON ist.issued_emp_id = e.emp_id
JOIN branch br ON e.branch_id = br.branch_id;

SELECT * FROM issued_books_details;
