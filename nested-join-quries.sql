--5. BASIC SELECT QUERIES

-- List all books issued in the last 30 days
SELECT * FROM issued_status
WHERE issued_date >= CURRENT_DATE - INTERVAL '30 days';

-- List employees working at a specific branch
SELECT emp_name FROM employees
WHERE branch_id = 'B001';

-- Count number of books per category
SELECT category, COUNT(*) FROM books
GROUP BY category;

-- List members who have returned damaged books
SELECT DISTINCT m.member_name
FROM members m
JOIN issued_status i ON m.member_id = i.issued_member_id
JOIN return_status r ON i.issued_id = r.issued_id
WHERE r.return_condition = 'Damaged';


--6. NESTED QUERIES

--a. Members Who Issued More Than Average Number of Books
SELECT member_id, member_name
FROM members
WHERE member_id IN (
    SELECT issued_member_id
    FROM issued_status
    GROUP BY issued_member_id
    HAVING COUNT(*) > (
        SELECT AVG(book_count)
        FROM (
            SELECT COUNT(*) AS book_count
            FROM issued_status
            GROUP BY issued_member_id
        ) AS avg_books
    )
);

--b. Books Never Issued
SELECT *
FROM books
WHERE isbn NOT IN (
    SELECT DISTINCT issued_book_isbn FROM issued_status
);

--c. Top 3 Most Frequently Issued Books
SELECT book_title, COUNT(*) AS times_issued
FROM issued_status i
JOIN books b ON i.issued_book_isbn = b.isbn
GROUP BY book_title
ORDER BY times_issued DESC
LIMIT 3;

--d. Find employees who issued books only to members who live on 'Main St'
SELECT emp_id
FROM employees
WHERE emp_id IN (
    SELECT issued_emp_id
    FROM issued_status
    WHERE issued_member_id IN (
        SELECT member_id
        FROM members
        WHERE member_address LIKE '%Main St%'
    )
);

--e. Get members who returned 'Damaged' books more than once
SELECT m.member_id, m.member_name
FROM members m
WHERE (
    SELECT COUNT(*)
    FROM return_status r
    JOIN issued_status i ON r.issued_id = i.issued_id
    WHERE i.issued_member_id = m.member_id AND r.return_condition = 'Damaged'
) > 1;



--7. JOIN-BASED QUERIES

--a. All Returns with Member and Book Info
SELECT
    rs.return_id,
    m.member_name,
    b.book_title,
    rs.return_date
FROM return_status rs
JOIN issued_status ist ON rs.issued_id = ist.issued_id
JOIN books b ON rs.return_book_isbn = b.isbn
JOIN members m ON ist.issued_member_id = m.member_id;

--b. Branch-wise Book Issue Count
SELECT
    br.branch_id,
    br.branch_address,
    COUNT(*) AS total_issued
FROM issued_status ist
JOIN employees e ON ist.issued_emp_id = e.emp_id
JOIN branch br ON e.branch_id = br.branch_id
GROUP BY br.branch_id, br.branch_address;

--c. List of Damaged Books Returned by Members
SELECT
    m.member_id,
    m.member_name,
    b.book_title,
    rs.return_date
FROM return_status rs
JOIN issued_status ist ON rs.issued_id = ist.issued_id
JOIN books b ON rs.return_book_isbn = b.isbn
JOIN members m ON ist.issued_member_id = m.member_id
WHERE rs.return_condition = 'Damaged';

--d. Books Issued and Their Return Status
SELECT 
    i.issued_id,
    m.member_name,
    b.book_title,
    i.issued_date,
    r.return_date,
    r.return_condition
FROM issued_status i
LEFT JOIN return_status r ON i.issued_id = r.issued_id
JOIN members m ON i.issued_member_id = m.member_id
JOIN books b ON i.issued_book_isbn = b.isbn;

--e. Branch-wise Member Registrations
SELECT 
    br.branch_id,
    br.branch_address,
    COUNT(DISTINCT m.member_id) AS total_members
FROM members m
JOIN issued_status i ON m.member_id = i.issued_member_id
JOIN employees e ON i.issued_emp_id = e.emp_id
JOIN branch br ON e.branch_id = br.branch_id
GROUP BY br.branch_id, br.branch_address;
