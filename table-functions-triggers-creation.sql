-- Library Management System Project

-- Create table "Branch"
DROP TABLE IF EXISTS branch;
CREATE TABLE branch
(
            branch_id VARCHAR(10) PRIMARY KEY,
            manager_id VARCHAR(10),
            branch_address VARCHAR(30),
            contact_no VARCHAR(15)
);

-- Create table "Employee"
DROP TABLE IF EXISTS employees;
CREATE TABLE employees
(
            emp_id VARCHAR(10) PRIMARY KEY,
            emp_name VARCHAR(30),
            position VARCHAR(30),
            salary DECIMAL(10,2),
            branch_id VARCHAR(10),
            FOREIGN KEY (branch_id) REFERENCES  branch(branch_id)
);

-- Create table "Members"
DROP TABLE IF EXISTS members;
CREATE TABLE members
(
            member_id VARCHAR(10) PRIMARY KEY,
            member_name VARCHAR(30),
            member_address VARCHAR(30),
            reg_date DATE
);

-- Create table "Books"
DROP TABLE IF EXISTS books;
CREATE TABLE books
(
            isbn VARCHAR(50) PRIMARY KEY,
            book_title VARCHAR(80),
            category VARCHAR(30),
            rental_price DECIMAL(10,2),
            status VARCHAR(10),
            author VARCHAR(30),
            publisher VARCHAR(30)
);

-- Create table "IssueStatus"
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status
(
            issued_id VARCHAR(10) PRIMARY KEY,
            issued_member_id VARCHAR(30),
            issued_book_name VARCHAR(80),
            issued_date DATE,
            issued_book_isbn VARCHAR(50),
            issued_emp_id VARCHAR(10),
            FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
            FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
            FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn) 
);

-- Create table "ReturnStatus"
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status
(
            return_id VARCHAR(10) PRIMARY KEY,
            issued_id VARCHAR(30),
            return_book_name VARCHAR(80),
            return_date DATE,
            return_book_isbn VARCHAR(50),
            FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);

--Task 1. Create a New Book Record -- "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

--Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

--Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE   issued_id =   'IS121';

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT
    issued_emp_id,
    COUNT(*)
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1;

-- 1. FUNCTIONS
--a. Get total books issued by a member
CREATE OR REPLACE FUNCTION total_books_issued(p_member_id VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    total INTEGER;
BEGIN
    SELECT COUNT(*) INTO total
    FROM issued_status
    WHERE issued_member_id = p_member_id;
    RETURN total;
END;
$$ LANGUAGE plpgsql;
SELECT total_books_issued('C102');

--b. Get most issued book
CREATE OR REPLACE FUNCTION get_most_issued_book()
RETURNS TABLE(book_title VARCHAR, times_issued INT) AS $$
BEGIN
  RETURN QUERY
  SELECT issued_book_name, COUNT(*) AS times_issued
  FROM issued_status
  GROUP BY issued_book_name
  ORDER BY times_issued DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;
SELECT get_most_issued_book();

--c. Get total salary paid per branch
CREATE OR REPLACE FUNCTION total_salary_by_branch(p_branch_id VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    total_salary NUMERIC;
BEGIN
    SELECT SUM(salary)
    INTO total_salary
    FROM employees
    WHERE branch_id = p_branch_id;

    RETURN COALESCE(total_salary, 0);
END;
$$ LANGUAGE plpgsql;
SELECT * FROM total_salary_by_branch();

--d. Get Total Books Issued by an Employee
CREATE OR REPLACE FUNCTION total_books_by_employee(emp_id_input VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    total INTEGER;
BEGIN
    SELECT COUNT(*) INTO total
    FROM issued_status
    WHERE issued_emp_id = emp_id_input;

    RETURN total;
END;
$$ LANGUAGE plpgsql;
SELECT total_books_by_employee('E101');

--e. Function to Calculate Late Return Days
CREATE OR REPLACE FUNCTION late_days(p_issued_id VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    days_late INTEGER;
BEGIN
    SELECT GREATEST(0, RETURN_DATE - i.issued_date - 14)
    INTO days_late
    FROM return_status r
    JOIN issued_status i ON r.issued_id = i.issued_id
    WHERE r.issued_id = p_issued_id;

    RETURN days_late;
END;
$$ LANGUAGE plpgsql;
SELECT late_days('2025-06-01', '2025-06-17');

--2. TRIGGERS
--1. Trigger to auto-update book status to 'No' when issued
CREATE OR REPLACE FUNCTION update_book_status_on_issue()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE books SET status = 'No' WHERE isbn = NEW.issued_book_isbn;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_book_status_on_issue
AFTER INSERT ON issued_status
FOR EACH ROW
EXECUTE FUNCTION update_book_status_on_issue();

-- Check current book status
SELECT status FROM books WHERE isbn = '978-0-14-044913-6';

-- Issue the book
INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES ('IS200', 'C101', 'The Odyssey', CURRENT_DATE, '978-0-14-044913-6', 'E101');

-- Check updated status
SELECT status FROM books WHERE isbn = '978-0-14-044913-6';

--2. Trigger to auto-update book status to 'Yes' when returned
CREATE OR REPLACE FUNCTION update_book_status_on_return()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE books SET status = 'Yes' WHERE isbn = NEW.return_book_isbn;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_book_status_on_return
AFTER INSERT ON return_status
FOR EACH ROW
EXECUTE FUNCTION update_book_status_on_return();

-- Return the book
INSERT INTO return_status (return_id, issued_id, return_book_name, return_date, return_book_isbn)
VALUES ('RS200', 'IS200', 'The Odyssey', CURRENT_DATE, '978-0-14-044913-6');

-- Check updated status
SELECT status FROM books WHERE isbn = '978-0-14-044913-6';


--3. Trigger to log new member registrations
CREATE TABLE member_log (
    log_id SERIAL PRIMARY KEY,
    member_id VARCHAR(10),
    reg_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_new_member()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO member_log (member_id) VALUES (NEW.member_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_new_member
AFTER INSERT ON members
FOR EACH ROW
EXECUTE FUNCTION log_new_member();

-- Add a new member
INSERT INTO members (member_id, member_name, member_address, reg_date)
VALUES ('C999', 'Test User', '101 Sample Rd', CURRENT_DATE);

-- Check log table
SELECT * FROM member_log WHERE member_id = 'C999';

--4. Trigger to prevent issuing if the book is unavailable
CREATE OR REPLACE FUNCTION prevent_unavailable_issuing()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM books WHERE isbn = NEW.issued_book_isbn AND status = 'No'
    ) THEN
        RAISE EXCEPTION 'Book is currently unavailable for issue';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_unavailable_issuing
BEFORE INSERT ON issued_status
FOR EACH ROW
EXECUTE FUNCTION prevent_unavailable_issuing();

-- Set book to 'No' (unavailable)
UPDATE books SET status = 'No' WHERE isbn = '978-0-14-044913-6';

-- Try to issue it again (should raise an error)
INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES ('IS201', 'C101', 'The Odyssey', CURRENT_DATE, '978-0-14-044913-6', 'E101');

--5. Trigger to auto-fill return date if not provided
CREATE OR REPLACE FUNCTION default_return_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.return_date IS NULL THEN
        NEW.return_date := CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_default_return_date
BEFORE INSERT ON return_status
FOR EACH ROW
EXECUTE FUNCTION default_return_date();

-- Insert a return without specifying return_date
INSERT INTO return_status (return_id, issued_id, return_book_name, return_book_isbn)
VALUES ('RS201', 'IS200', 'The Odyssey', '978-0-14-044913-6');

-- Check inserted row
SELECT * FROM return_status WHERE return_id = 'RS201';
