/* ============================================================================
   FILE    : 03_insert_sample_data.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Insert realistic sample data and verify every table.
   ENV     : Oracle FreeSQL
   RUN     : THIRD (after 01 and 02)
   ============================================================================
   IMPORTANT ORDER
   Parent rows are inserted before child rows so every FOREIGN KEY is valid:
   DEPARTMENTS -> STUDENTS / COURSES -> ENROLLMENTS -> ATTENDANCE
                                              -> EXAMINATIONS -> MARKS
                                              -> FEES
   NOTE ON IDs
   Explicit IDs (1, 2, 3 ...) are used here so the relationships are easy to
   follow. At the end of this script the sequences are re-synchronised to
   MAX(id)+1, so later procedure calls continue from a safe number.
   NOTE ON FEES
   This script runs BEFORE triggers are created, so due_amount and
   payment_status are supplied explicitly. After 06_create_triggers.sql runs,
   the trigger keeps them correct automatically.
   ============================================================================ */

/* ---------------------------------------------------------------------------
   1. DEPARTMENTS (4 rows)
   --------------------------------------------------------------------------- */
INSERT INTO departments VALUES (1,'Computer Science','CS','Dr. Rajesh Kumar',DATE '2023-01-10');
INSERT INTO departments VALUES (2,'Information Technology','IT','Dr. Sunita Mehta',DATE '2023-01-10');
INSERT INTO departments VALUES (3,'Commerce','COM','Prof. Anil Deshmukh',DATE '2023-01-15');
INSERT INTO departments VALUES (4,'Electronics Engineering','ECE','Dr. Priya Raghavan',DATE '2023-01-15');

/* ---------------------------------------------------------------------------
   2. STUDENTS (15 rows)
   --------------------------------------------------------------------------- */
INSERT INTO students VALUES (1,'Aarav','Sharma','aarav.sharma@college.edu','9876500001',DATE '2004-05-14','Male','12 MG Road, Pune',1,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (2,'Diya','Patel','diya.patel@college.edu','9876500002',DATE '2004-08-22','Female','45 FC Road, Pune',1,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (3,'Vivaan','Reddy','vivaan.reddy@college.edu','9876500003',DATE '2003-12-09','Male','7 Banjara Hills, Hyderabad',1,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (4,'Ananya','Iyer','ananya.iyer@college.edu','9876500004',DATE '2004-03-30','Female','23 Anna Nagar, Chennai',1,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (5,'Arjun','Nair','arjun.nair@college.edu','9876500005',DATE '2004-11-11','Male','89 Marine Drive, Kochi',1,DATE '2023-07-01','GRADUATED',DATE '2023-07-01');
INSERT INTO students VALUES (6,'Ishaan','Gupta','ishaan.gupta@college.edu','9876500006',DATE '2004-01-19','Male','56 Sector 15, Noida',2,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (7,'Saanvi','Joshi','saanvi.joshi@college.edu','9876500007',DATE '2004-06-27','Female','34 JM Road, Pune',2,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (8,'Aditya','Menon','aditya.menon@college.edu','9876500008',DATE '2003-09-05','Male','12 Brigade Road, Bengaluru',2,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (9,'Kavya','Desai','kavya.desai@college.edu','9876500009',DATE '2004-04-16','Female','78 CG Road, Ahmedabad',2,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (10,'Rohan','Kulkarni','rohan.kulkarni@college.edu','9876500010',DATE '2004-02-08','Male','90 Laxmi Road, Pune',3,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (11,'Meera','Pillai','meera.pillai@college.edu','9876500011',DATE '2004-07-21','Female','15 MG Road, Thiruvananthapuram',3,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (12,'Kabir','Singh','kabir.singh@college.edu','9876500012',DATE '2003-10-02','Male','66 Civil Lines, Jaipur',3,DATE '2023-07-01','INACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (13,'Ananya','Verma','ananya.verma@college.edu','9876500013',DATE '2004-09-13','Female','21 Park Street, Kolkata',4,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (14,'Vihaan','Rao','vihaan.rao@college.edu','9876500014',DATE '2004-12-25','Male','43 MG Road, Visakhapatnam',4,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');
INSERT INTO students VALUES (15,'Riya','Chatterjee','riya.chatterjee@college.edu','9876500015',DATE '2004-05-03','Female','88 Salt Lake, Kolkata',4,DATE '2023-07-01','ACTIVE',DATE '2023-07-01');

/* ---------------------------------------------------------------------------
   3. COURSES (8 rows)
   --------------------------------------------------------------------------- */
INSERT INTO courses VALUES (1,'Data Structures','CS101',4,1,'Arrays, linked lists, trees, graphs and algorithms');
INSERT INTO courses VALUES (2,'Database Management Systems','CS102',4,1,'Relational model, SQL, normalization and transactions');
INSERT INTO courses VALUES (3,'Operating Systems','CS103',4,1,'Processes, scheduling, memory and file systems');
INSERT INTO courses VALUES (4,'Web Technologies','IT201',3,2,'HTML, CSS, JavaScript and server side basics');
INSERT INTO courses VALUES (5,'Computer Networks','IT202',4,2,'OSI model, TCP/IP, routing and network security');
INSERT INTO courses VALUES (6,'Financial Accounting','COM301',3,3,'Journal, ledger, trial balance and final accounts');
INSERT INTO courses VALUES (7,'Business Statistics','COM302',3,3,'Descriptive statistics, probability and hypothesis testing');
INSERT INTO courses VALUES (8,'Digital Electronics','ECE401',4,4,'Logic gates, combinational and sequential circuits');

/* ---------------------------------------------------------------------------
   4. ENROLLMENTS (20 rows)
   --------------------------------------------------------------------------- */
INSERT INTO enrollments VALUES (1, 1,1,'2024-2025',1,'ENROLLED',DATE '2024-07-05');
INSERT INTO enrollments VALUES (2, 1,2,'2024-2025',1,'ENROLLED',DATE '2024-07-05');
INSERT INTO enrollments VALUES (3, 2,1,'2024-2025',1,'ENROLLED',DATE '2024-07-05');
INSERT INTO enrollments VALUES (4, 2,3,'2024-2025',1,'ENROLLED',DATE '2024-07-05');
INSERT INTO enrollments VALUES (5, 3,2,'2024-2025',1,'ENROLLED',DATE '2024-07-06');
INSERT INTO enrollments VALUES (6, 4,1,'2024-2025',1,'ENROLLED',DATE '2024-07-06');
INSERT INTO enrollments VALUES (7, 4,2,'2024-2025',1,'ENROLLED',DATE '2024-07-06');
INSERT INTO enrollments VALUES (8, 5,3,'2024-2025',1,'COMPLETED',DATE '2024-07-06');
INSERT INTO enrollments VALUES (9, 6,4,'2024-2025',1,'ENROLLED',DATE '2024-07-07');
INSERT INTO enrollments VALUES (10,6,5,'2024-2025',1,'ENROLLED',DATE '2024-07-07');
INSERT INTO enrollments VALUES (11,7,4,'2024-2025',1,'ENROLLED',DATE '2024-07-07');
INSERT INTO enrollments VALUES (12,8,5,'2024-2025',1,'ENROLLED',DATE '2024-07-07');
INSERT INTO enrollments VALUES (13,9,4,'2024-2025',1,'ENROLLED',DATE '2024-07-08');
INSERT INTO enrollments VALUES (14,10,6,'2024-2025',1,'ENROLLED',DATE '2024-07-08');
INSERT INTO enrollments VALUES (15,10,7,'2024-2025',1,'ENROLLED',DATE '2024-07-08');
INSERT INTO enrollments VALUES (16,11,6,'2024-2025',1,'ENROLLED',DATE '2024-07-09');
INSERT INTO enrollments VALUES (17,12,7,'2024-2025',1,'DROPPED',DATE '2024-07-09');
INSERT INTO enrollments VALUES (18,13,8,'2024-2025',1,'ENROLLED',DATE '2024-07-09');
INSERT INTO enrollments VALUES (19,14,8,'2024-2025',1,'ENROLLED',DATE '2024-07-10');
INSERT INTO enrollments VALUES (20,15,8,'2024-2025',1,'ENROLLED',DATE '2024-07-10');

/* ---------------------------------------------------------------------------
   5. ATTENDANCE (34 rows across several dates)
   Two students (id 2 and 6) are deliberately kept below 75% to test reports.
   --------------------------------------------------------------------------- */
/* --- Student 1 in course 1 : 7 Present + 1 Absent = 87.5% --- */
INSERT INTO attendance VALUES (1, 1,1,DATE '2024-08-01','Present',NULL);
INSERT INTO attendance VALUES (2, 1,1,DATE '2024-08-02','Present',NULL);
INSERT INTO attendance VALUES (3, 1,1,DATE '2024-08-03','Present',NULL);
INSERT INTO attendance VALUES (4, 1,1,DATE '2024-08-05','Absent','Medical leave');
INSERT INTO attendance VALUES (5, 1,1,DATE '2024-08-06','Present',NULL);
INSERT INTO attendance VALUES (6, 1,1,DATE '2024-08-07','Present',NULL);
INSERT INTO attendance VALUES (7, 1,1,DATE '2024-08-08','Present',NULL);
INSERT INTO attendance VALUES (8, 1,1,DATE '2024-08-09','Present',NULL);

/* --- Student 2 in course 1 : 5 Present + 2 Absent + 1 Leave = 62.5% --- */
INSERT INTO attendance VALUES (9, 2,1,DATE '2024-08-01','Present',NULL);
INSERT INTO attendance VALUES (10,2,1,DATE '2024-08-02','Absent',NULL);
INSERT INTO attendance VALUES (11,2,1,DATE '2024-08-03','Present',NULL);
INSERT INTO attendance VALUES (12,2,1,DATE '2024-08-05','Absent',NULL);
INSERT INTO attendance VALUES (13,2,1,DATE '2024-08-06','Present',NULL);
INSERT INTO attendance VALUES (14,2,1,DATE '2024-08-07','Leave','Family function');
INSERT INTO attendance VALUES (15,2,1,DATE '2024-08-08','Present',NULL);
INSERT INTO attendance VALUES (16,2,1,DATE '2024-08-09','Present',NULL);

/* --- Student 3 in course 2 : 6 Present = 100% --- */
INSERT INTO attendance VALUES (17,3,2,DATE '2024-08-01','Present',NULL);
INSERT INTO attendance VALUES (18,3,2,DATE '2024-08-02','Present',NULL);
INSERT INTO attendance VALUES (19,3,2,DATE '2024-08-03','Present',NULL);
INSERT INTO attendance VALUES (20,3,2,DATE '2024-08-05','Present',NULL);
INSERT INTO attendance VALUES (21,3,2,DATE '2024-08-06','Present',NULL);
INSERT INTO attendance VALUES (22,3,2,DATE '2024-08-07','Present',NULL);

/* --- Student 6 in course 4 : 4 Present + 2 Absent = 66.7% --- */
INSERT INTO attendance VALUES (23,6,4,DATE '2024-08-01','Present',NULL);
INSERT INTO attendance VALUES (24,6,4,DATE '2024-08-02','Absent',NULL);
INSERT INTO attendance VALUES (25,6,4,DATE '2024-08-03','Present',NULL);
INSERT INTO attendance VALUES (26,6,4,DATE '2024-08-05','Absent',NULL);
INSERT INTO attendance VALUES (27,6,4,DATE '2024-08-06','Present',NULL);
INSERT INTO attendance VALUES (28,6,4,DATE '2024-08-07','Present',NULL);

/* --- Student 10 in course 6 : 5 Present + 1 Leave = 83.3% --- */
INSERT INTO attendance VALUES (29,10,6,DATE '2024-08-01','Present',NULL);
INSERT INTO attendance VALUES (30,10,6,DATE '2024-08-02','Present',NULL);
INSERT INTO attendance VALUES (31,10,6,DATE '2024-08-03','Present',NULL);
INSERT INTO attendance VALUES (32,10,6,DATE '2024-08-05','Leave','Sports meet');
INSERT INTO attendance VALUES (33,10,6,DATE '2024-08-06','Present',NULL);
INSERT INTO attendance VALUES (34,10,6,DATE '2024-08-07','Present',NULL);

/* ---------------------------------------------------------------------------
   6. EXAMINATIONS (6 rows)
   --------------------------------------------------------------------------- */
INSERT INTO examinations VALUES (1,1,'Data Structures Mid-Term',DATE '2024-09-15',100,40,1);
INSERT INTO examinations VALUES (2,1,'Data Structures Final',DATE '2024-11-20',100,40,1);
INSERT INTO examinations VALUES (3,2,'DBMS Mid-Term',DATE '2024-09-18',100,40,1);
INSERT INTO examinations VALUES (4,4,'Web Technologies Mid-Term',DATE '2024-09-20',50,20,1);
INSERT INTO examinations VALUES (5,6,'Financial Accounting Mid-Term',DATE '2024-09-22',100,35,1);
INSERT INTO examinations VALUES (6,8,'Digital Electronics Mid-Term',DATE '2024-09-25',100,40,1);

/* ---------------------------------------------------------------------------
   7. MARKS (16 rows)
   grade / result_status are supplied here because triggers do not exist yet.
   After 06_create_triggers.sql they are computed automatically.
   --------------------------------------------------------------------------- */
INSERT INTO marks VALUES (1, 1,1,82.00,'A','PASS',NULL);
INSERT INTO marks VALUES (2, 2,1,35.00,'F','FAIL',NULL);
INSERT INTO marks VALUES (3, 4,1,76.00,'B','PASS',NULL);
INSERT INTO marks VALUES (4, 1,2,88.00,'A','PASS',NULL);
INSERT INTO marks VALUES (5, 2,2,42.00,'D','PASS',NULL);
INSERT INTO marks VALUES (6, 4,2,81.00,'A','PASS',NULL);
INSERT INTO marks VALUES (7, 1,3,91.00,'A','PASS',NULL);
INSERT INTO marks VALUES (8, 3,3,67.00,'C','PASS',NULL);
INSERT INTO marks VALUES (9, 6,4,38.00,'A','PASS',NULL);
INSERT INTO marks VALUES (10,7,4,44.00,'A','PASS',NULL);
INSERT INTO marks VALUES (11,9,4,18.00,'F','FAIL',NULL);
INSERT INTO marks VALUES (12,10,5,72.00,'C','PASS',NULL);
INSERT INTO marks VALUES (13,11,5,58.00,'D','PASS',NULL);
INSERT INTO marks VALUES (14,15,5,63.00,'C','PASS',NULL);
INSERT INTO marks VALUES (15,13,6,85.00,'A','PASS',NULL);
INSERT INTO marks VALUES (16,14,6,47.00,'D','PASS',NULL);

/* ---------------------------------------------------------------------------
   8. FEES (15 rows - one account per student)
   --------------------------------------------------------------------------- */
INSERT INTO fees VALUES (1, 1,50000,50000,0,     DATE '2024-07-10','PAID',   'UPI');
INSERT INTO fees VALUES (2, 2,50000,30000,20000, DATE '2024-07-12','PARTIAL','CARD');
INSERT INTO fees VALUES (3, 3,50000,50000,0,     DATE '2024-07-10','PAID',   'NETBANKING');
INSERT INTO fees VALUES (4, 4,50000,25000,25000, DATE '2024-07-15','PARTIAL','CASH');
INSERT INTO fees VALUES (5, 5,50000,0,    50000, DATE '2024-07-01','PENDING',NULL);
INSERT INTO fees VALUES (6, 6,50000,50000,0,     DATE '2024-07-11','PAID',   'UPI');
INSERT INTO fees VALUES (7, 7,50000,40000,10000, DATE '2024-07-14','PARTIAL','CHEQUE');
INSERT INTO fees VALUES (8, 8,50000,0,    50000, DATE '2024-07-01','PENDING',NULL);
INSERT INTO fees VALUES (9, 9,50000,50000,0,     DATE '2024-07-13','PAID',   'UPI');
INSERT INTO fees VALUES (10,10,45000,45000,0,     DATE '2024-07-10','PAID',   'CASH');
INSERT INTO fees VALUES (11,11,45000,20000,25000, DATE '2024-07-16','PARTIAL','UPI');
INSERT INTO fees VALUES (12,12,45000,0,    45000, DATE '2024-07-01','PENDING',NULL);
INSERT INTO fees VALUES (13,13,55000,55000,0,     DATE '2024-07-10','PAID',   'NETBANKING');
INSERT INTO fees VALUES (14,14,55000,30000,25000, DATE '2024-07-17','PARTIAL','CARD');
INSERT INTO fees VALUES (15,15,55000,0,    55000, DATE '2024-07-01','PENDING',NULL);

COMMIT;

/* ---------------------------------------------------------------------------
   9. RE-SYNCHRONISE THE SEQUENCES
   Sample data used explicit IDs, so each sequence must jump to MAX(id)+1.
   (ALTER SEQUENCE ... RESTART is available in Oracle 12c and later.)
   --------------------------------------------------------------------------- */
DECLARE
  PROCEDURE bump (p_seq VARCHAR2, p_table VARCHAR2, p_col VARCHAR2) IS
    v_max NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT NVL(MAX('||p_col||'),0) FROM '||p_table INTO v_max;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE '||p_seq||' RESTART START WITH '||(v_max+1);
  END bump;
BEGIN
  bump('SEQ_DEPARTMENT_ID','DEPARTMENTS','DEPARTMENT_ID');
  bump('SEQ_STUDENT_ID',   'STUDENTS',   'STUDENT_ID');
  bump('SEQ_COURSE_ID',    'COURSES',    'COURSE_ID');
  bump('SEQ_ENROLLMENT_ID','ENROLLMENTS','ENROLLMENT_ID');
  bump('SEQ_ATTENDANCE_ID','ATTENDANCE', 'ATTENDANCE_ID');
  bump('SEQ_EXAM_ID',      'EXAMINATIONS','EXAM_ID');
  bump('SEQ_MARKS_ID',     'MARKS',      'MARKS_ID');
  bump('SEQ_FEE_ID',       'FEES',       'FEE_ID');
  bump('SEQ_LOG_ID',       'AUDIT_LOG',  'LOG_ID');
  DBMS_OUTPUT.PUT_LINE('Sequences re-synchronised with sample data.');
END;
/

/* ---------------------------------------------------------------------------
   10. VERIFICATION QUERIES - run each to confirm the row counts
   --------------------------------------------------------------------------- */
SELECT 'DEPARTMENTS' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'STUDENTS',    COUNT(*) FROM students
UNION ALL SELECT 'COURSES',     COUNT(*) FROM courses
UNION ALL SELECT 'ENROLLMENTS', COUNT(*) FROM enrollments
UNION ALL SELECT 'ATTENDANCE',  COUNT(*) FROM attendance
UNION ALL SELECT 'EXAMINATIONS',COUNT(*) FROM examinations
UNION ALL SELECT 'MARKS',       COUNT(*) FROM marks
UNION ALL SELECT 'FEES',        COUNT(*) FROM fees
UNION ALL SELECT 'AUDIT_LOG',   COUNT(*) FROM audit_log
ORDER BY table_name;

/* Re-read the data of each table (run one at a time if you prefer) */
SELECT * FROM departments ORDER BY department_id;
SELECT * FROM students    ORDER BY student_id;
SELECT * FROM courses     ORDER BY course_id;
SELECT * FROM enrollments ORDER BY enrollment_id;
SELECT * FROM attendance  ORDER BY attendance_id;
SELECT * FROM examinations ORDER BY exam_id;
SELECT * FROM marks       ORDER BY marks_id;
SELECT * FROM fees        ORDER BY fee_id;

/* ============================================================================
   END OF 03_insert_sample_data.sql
   ============================================================================ */
