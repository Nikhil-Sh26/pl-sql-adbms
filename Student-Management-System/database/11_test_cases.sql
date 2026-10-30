/* ============================================================================
   FILE    : 11_test_cases.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Complete test suite - successful and failing scenarios.
   ENV     : Oracle FreeSQL
   RUN     : LAST (after 01-10). Run the blocks ONE AT A TIME.
   ============================================================================
   READ THIS FIRST - HOW TO SEE THE OUTPUT
   The procedures print their result with DBMS_OUTPUT.PUT_LINE.
   1. In the FreeSQL worksheet, enable the DBMS_OUTPUT / output panel
      (usually a toggle or a separate "DBMS Output" tab).
      If the environment accepts it, you may also try:   SET SERVEROUTPUT ON
      followed by "/" - but do not rely on it.
   2. Because the output panel is not always available, EVERY test below is
      followed by a "VERIFY" SELECT query. Run that query to prove what really
      happened inside the tables. This is also the safest way to demonstrate
      the project during a viva.
   EXPECTED RESULTS are written as comments above every block.
   ============================================================================ */


/* ###########################################################################
   SECTION A - SUCCESSFUL OPERATIONS
   ########################################################################### */

/* ---------------------------------------------------------------------------
   TEST 1 - Register a new student successfully
   EXPECTED : SUCCESS message with a new student id (should be 16).
   --------------------------------------------------------------------------- */
BEGIN
  add_student(
    p_first_name    => 'Test',
    p_last_name     => 'Student',
    p_email         => 'test.student@college.edu',
    p_phone         => '9876599999',
    p_date_of_birth => DATE '2005-01-15',
    p_gender        => 'Male',
    p_address       => '1 Test Lane, Pune',
    p_department_id => 1,
    p_status        => 'ACTIVE');
END;
/

/* VERIFY */
SELECT student_id, first_name, last_name, email, department_id, student_status
  FROM students
 WHERE email = 'test.student@college.edu';


/* ---------------------------------------------------------------------------
   TEST 2 - Update the student just created
   EXPECTED : SUCCESS message.
   --------------------------------------------------------------------------- */
BEGIN
  update_student(
    p_student_id => 16,
    p_phone      => '9000000000',
    p_address    => '99 Updated Street, Pune');
END;
/

/* VERIFY */
SELECT student_id, phone, address FROM students WHERE student_id = 16;


/* ---------------------------------------------------------------------------
   TEST 3 - Enroll a student in a course
   EXPECTED : SUCCESS message with a new enrollment id (should be 21).
   --------------------------------------------------------------------------- */
BEGIN
  enroll_student(
    p_student_id    => 16,
    p_course_id     => 1,
    p_academic_year => '2024-2025',
    p_semester      => 1);
END;
/

/* VERIFY */
SELECT enrollment_id, student_id, course_id, academic_year, semester, enrollment_status
  FROM enrollments
 WHERE student_id = 16;


/* ---------------------------------------------------------------------------
   TEST 4 - Record attendance
   EXPECTED : SUCCESS message.
   --------------------------------------------------------------------------- */
BEGIN
  mark_attendance(
    p_student_id        => 16,
    p_course_id         => 1,
    p_attendance_date   => DATE '2025-01-10',
    p_attendance_status => 'Present',
    p_remarks           => 'First class of the term');
END;
/

/* VERIFY */
SELECT attendance_id, student_id, course_id, attendance_date, attendance_status
  FROM attendance
 WHERE student_id = 16;


/* ---------------------------------------------------------------------------
   TEST 5 - Calculate the attendance percentage of the new student
   EXPECTED : 100 (one session, one Present).
   --------------------------------------------------------------------------- */
SELECT calculate_attendance_percentage(16, 1) AS student16_course1_percent FROM dual;
SELECT calculate_attendance_percentage(2)     AS student2_overall_percent   FROM dual;

/* VERIFY with plain SQL (same result must be produced by the query) */
SELECT s.student_id,
       ROUND(SUM(CASE WHEN a.attendance_status='Present' THEN 1 ELSE 0 END)
             / COUNT(a.attendance_id) * 100, 2) AS attendance_percentage
  FROM students s JOIN attendance a ON a.student_id = s.student_id
 WHERE s.student_id IN (2,16)
 GROUP BY s.student_id;


/* ---------------------------------------------------------------------------
   TEST 6 - Enter examination marks
   EXPECTED : SUCCESS message. The trigger computes grade and result_status.
   --------------------------------------------------------------------------- */
BEGIN
  enter_student_marks(
    p_student_id     => 16,
    p_exam_id        => 1,
    p_marks_obtained => 85,
    p_remarks        => 'Good performance');
END;
/

/* VERIFY - result_status and grade must have been filled automatically */
SELECT marks_id, student_id, exam_id, marks_obtained, grade, result_status
  FROM marks
 WHERE student_id = 16;


/* ---------------------------------------------------------------------------
   TEST 7 - Record a fee payment
   EXPECTED : fee account created, then updated to PAID after the full amount.
   --------------------------------------------------------------------------- */
BEGIN
  record_fee_payment(p_student_id => 16, p_payment_amount => 20000,
                     p_payment_method => 'UPI', p_total_fee => 50000);
END;
/

BEGIN
  record_fee_payment(p_student_id => 16, p_payment_amount => 30000,
                     p_payment_method => 'CARD');
END;
/

/* VERIFY - due_amount and payment_status maintained by the trigger */
SELECT fee_id, student_id, total_fee, paid_amount, due_amount, payment_status, payment_method
  FROM fees
 WHERE student_id = 16;


/* ---------------------------------------------------------------------------
   TEST 8 - Check an outstanding fee balance
   EXPECTED : student 16 = 0 (fully paid), student 2 = 20000.
   --------------------------------------------------------------------------- */
SELECT get_student_fee_balance(16) AS student16_balance FROM dual;
SELECT get_student_fee_balance(2)  AS student2_balance  FROM dual;


/* ---------------------------------------------------------------------------
   TEST 9 - Academic performance and results
   --------------------------------------------------------------------------- */
SELECT get_student_details(16)                AS student_details       FROM dual;
SELECT calculate_student_cgpa_or_average(16)   AS average_percent_16    FROM dual;
SELECT get_student_result(16, 1)               AS result_exam_1_for_16  FROM dual;
SELECT get_student_result(16, 99)              AS result_missing_exam   FROM dual;


/* ###########################################################################
   SECTION B - FAILING OPERATIONS (the system must reject them)
   ########################################################################### */

/* ---------------------------------------------------------------------------
   TEST 10 - Register a student with an email that already exists
   EXPECTED : ERROR - email already exists (DUP_VAL_ON_INDEX).
   --------------------------------------------------------------------------- */
BEGIN
  add_student(
    p_first_name    => 'Duplicate',
    p_last_name     => 'Email',
    p_email         => 'aarav.sharma@college.edu',   -- already used by student 1
    p_date_of_birth => DATE '2005-02-02',
    p_gender        => 'Male',
    p_department_id => 1);
END;
/

/* VERIFY - the count must still be 0 (nothing was inserted) */
SELECT COUNT(*) AS should_be_zero
  FROM students
 WHERE email = 'aarav.sharma@college.edu' AND first_name = 'Duplicate';


/* ---------------------------------------------------------------------------
   TEST 11 - Register a student in a department that does not exist
   EXPECTED : ERROR - department does not exist (custom exception).
   --------------------------------------------------------------------------- */
BEGIN
  add_student(
    p_first_name    => 'Ghost',
    p_last_name     => 'Student',
    p_email         => 'ghost.student@college.edu',
    p_date_of_birth => DATE '2005-03-03',
    p_gender        => 'Female',
    p_department_id => 999);
END;
/

/* VERIFY */
SELECT COUNT(*) AS should_be_zero FROM students WHERE email = 'ghost.student@college.edu';


/* ---------------------------------------------------------------------------
   TEST 12 - Attempt a duplicate enrollment
   EXPECTED : ERROR - already enrolled (custom exception).
   --------------------------------------------------------------------------- */
BEGIN
  enroll_student(p_student_id => 16, p_course_id => 1,
                 p_academic_year => '2024-2025', p_semester => 1);
END;
/

/* VERIFY - only one enrollment row must exist for that combination */
SELECT COUNT(*) AS should_be_one
  FROM enrollments
 WHERE student_id = 16 AND course_id = 1
   AND academic_year = '2024-2025' AND semester = 1;


/* ---------------------------------------------------------------------------
   TEST 13 - Enroll an INACTIVE student
   EXPECTED : ERROR - student status INACTIVE cannot be enrolled (rule 8).
   --------------------------------------------------------------------------- */
BEGIN
  enroll_student(p_student_id => 12, p_course_id => 6,
                 p_academic_year => '2024-2025', p_semester => 1);
END;
/

/* VERIFY - student 12 must still have only the original enrollment */
SELECT COUNT(*) AS student12_enrollments FROM enrollments WHERE student_id = 12;


/* ---------------------------------------------------------------------------
   TEST 14 - Record attendance for a student who is NOT enrolled in the course
   EXPECTED : ERROR - not enrolled (business rule 3).
   --------------------------------------------------------------------------- */
BEGIN
  mark_attendance(p_student_id => 16, p_course_id => 8,
                  p_attendance_date => DATE '2025-01-11',
                  p_attendance_status => 'Present');
END;
/

/* VERIFY */
SELECT COUNT(*) AS should_be_zero
  FROM attendance WHERE student_id = 16 AND course_id = 8;


/* ---------------------------------------------------------------------------
   TEST 15 - Enter marks greater than the maximum marks
   EXPECTED : ERROR - marks exceed the maximum.
   --------------------------------------------------------------------------- */
BEGIN
  enter_student_marks(p_student_id => 16, p_exam_id => 2, p_marks_obtained => 150);
END;
/

/* VERIFY - no row must exist for student 16 in exam 2 */
SELECT COUNT(*) AS should_be_zero FROM marks WHERE student_id = 16 AND exam_id = 2;


/* ---------------------------------------------------------------------------
   TEST 16 - The TRIGGER blocks invalid marks even when the procedure is bypassed
   EXPECTED : ORA-20005 "Marks ... exceed the maximum ...".
   --------------------------------------------------------------------------- */
BEGIN
  INSERT INTO marks (student_id, exam_id, marks_obtained)
  VALUES (16, 1, 200);        -- exam 1 maximum is 100
END;
/

/* VERIFY */
SELECT COUNT(*) AS should_be_zero FROM marks WHERE student_id = 16 AND exam_id = 1 AND marks_obtained = 200;


/* ---------------------------------------------------------------------------
   TEST 17 - Enter duplicate marks for the same student and examination
   EXPECTED : ERROR - marks already exist (custom exception).
   --------------------------------------------------------------------------- */
BEGIN
  enter_student_marks(p_student_id => 16, p_exam_id => 1, p_marks_obtained => 70);
END;
/

/* VERIFY - still exactly one row */
SELECT COUNT(*) AS should_be_one FROM marks WHERE student_id = 16 AND exam_id = 1;


/* ---------------------------------------------------------------------------
   TEST 18 - Pay more than the total fee (trigger protection)
   EXPECTED : ERROR / ORA-20006 - payment exceeds the outstanding balance.
   --------------------------------------------------------------------------- */
BEGIN
  record_fee_payment(p_student_id => 16, p_payment_amount => 100);
END;
/

/* VERIFY - the fee row must still be fully PAID with due_amount 0 */
SELECT total_fee, paid_amount, due_amount, payment_status FROM fees WHERE student_id = 16;


/* ---------------------------------------------------------------------------
   TEST 19 - Record a fee payment for a non-existent student
   EXPECTED : ERROR - student not found.
   --------------------------------------------------------------------------- */
BEGIN
  record_fee_payment(p_student_id => 999, p_payment_amount => 1000);
END;
/


/* ---------------------------------------------------------------------------
   TEST 20 - Delete a student who has related records
   EXPECTED : ERROR - has related records, cannot be deleted.
   --------------------------------------------------------------------------- */
BEGIN
  delete_student(1);      -- student 1 has enrollments, marks, fees
END;
/

/* VERIFY - student 1 must still exist */
SELECT COUNT(*) AS student1_still_there FROM students WHERE student_id = 1;


/* ---------------------------------------------------------------------------
   TEST 21 - Delete a student who has NO related records (successful delete)
   A brand new student is created first (no enrollments / marks / fees), so the
   delete is allowed. Note that student 16 cannot be deleted here because the
   earlier tests gave it enrollments, marks and fees.
   EXPECTED : SUCCESS - the student is removed.
   --------------------------------------------------------------------------- */
BEGIN
  add_student(
    p_first_name    => 'Delete',
    p_last_name     => 'Me',
    p_email         => 'delete.me@college.edu',
    p_date_of_birth => DATE '2005-06-06',
    p_gender        => 'Male',
    p_department_id => 1);
END;
/

DECLARE
  v_new_id NUMBER;
BEGIN
  SELECT student_id INTO v_new_id
    FROM students WHERE email = 'delete.me@college.edu';
  delete_student(v_new_id);
END;
/

/* VERIFY - must be 0 */
SELECT COUNT(*) AS should_be_zero FROM students WHERE email = 'delete.me@college.edu';


/* ###########################################################################
   SECTION C - INVALID IDS AND CUSTOM / BUILT-IN EXCEPTIONS
   ########################################################################### */

/* ---------------------------------------------------------------------------
   TEST 22 - Invalid student ids in the functions
   EXPECTED : -1 for numeric functions, ERROR text for the string function.
   --------------------------------------------------------------------------- */
SELECT calculate_attendance_percentage(9999) AS invalid_attendance FROM dual;
SELECT calculate_student_cgpa_or_average(9999) AS invalid_average  FROM dual;
SELECT get_student_fee_balance(9999)           AS invalid_balance  FROM dual;
SELECT get_student_details(9999)               AS invalid_details  FROM dual;


/* ---------------------------------------------------------------------------
   TEST 23 - NO_DATA_FOUND demonstration
   EXPECTED : "NO_DATA_FOUND caught" message.
   --------------------------------------------------------------------------- */
DECLARE
  v_name students.first_name%TYPE;
BEGIN
  SELECT first_name INTO v_name FROM students WHERE student_id = 9999;
  DBMS_OUTPUT.PUT_LINE('This line is never reached.');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('NO_DATA_FOUND caught: no student with id 9999.');
END;
/


/* ---------------------------------------------------------------------------
   TEST 24 - TOO_MANY_ROWS demonstration
   EXPECTED : "TOO_MANY_ROWS caught" message.
   --------------------------------------------------------------------------- */
DECLARE
  v_name students.first_name%TYPE;
BEGIN
  SELECT first_name INTO v_name FROM students WHERE department_id = 1;
  DBMS_OUTPUT.PUT_LINE('This line is never reached.');
EXCEPTION
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('TOO_MANY_ROWS caught: department 1 has more than one student.');
END;
/


/* ---------------------------------------------------------------------------
   TEST 25 - DUP_VAL_ON_INDEX demonstration
   EXPECTED : "DUP_VAL_ON_INDEX caught" message.
   --------------------------------------------------------------------------- */
BEGIN
  INSERT INTO students (first_name, last_name, email, date_of_birth, department_id)
  VALUES ('Copy','Cat','aarav.sharma@college.edu', DATE '2005-04-04', 1);
  DBMS_OUTPUT.PUT_LINE('This line is never reached.');
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('DUP_VAL_ON_INDEX caught: email aarav.sharma@college.edu is already used.');
END;
/


/* ---------------------------------------------------------------------------
   TEST 26 - VALUE_ERROR demonstration (value too large for the variable)
   EXPECTED : "VALUE_ERROR caught" message.
   --------------------------------------------------------------------------- */
DECLARE
  v_small VARCHAR2(5);
BEGIN
  v_small := 'THIS STRING IS TOO LONG';
  DBMS_OUTPUT.PUT_LINE('This line is never reached.');
EXCEPTION
  WHEN VALUE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('VALUE_ERROR caught: the value is too large for the variable.');
END;
/


/* ---------------------------------------------------------------------------
   TEST 27 - ZERO_DIVIDE demonstration
   EXPECTED : "ZERO_DIVIDE caught" message.
   --------------------------------------------------------------------------- */
DECLARE
  v_result NUMBER;
  v_zero   NUMBER := 0;
BEGIN
  v_result := 100 / v_zero;
  DBMS_OUTPUT.PUT_LINE('This line is never reached.');
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('ZERO_DIVIDE caught: cannot divide by zero.');
END;
/


/* ---------------------------------------------------------------------------
   TEST 28 - User defined exception with a meaningful message
   EXPECTED : "Custom exception caught" message.
   --------------------------------------------------------------------------- */
DECLARE
  e_below_minimum_attendance EXCEPTION;
  v_percentage NUMBER;
BEGIN
  v_percentage := calculate_attendance_percentage(2, 1);   -- student 2 is low
  IF v_percentage < 75 THEN
    RAISE e_below_minimum_attendance;
  END IF;
  DBMS_OUTPUT.PUT_LINE('Attendance is fine: '||v_percentage||'%');
EXCEPTION
  WHEN e_below_minimum_attendance THEN
    DBMS_OUTPUT.PUT_LINE('Custom exception caught: attendance '||v_percentage||
                         '% is below the required 75%.');
END;
/


/* ---------------------------------------------------------------------------
   TEST 29 - WHEN OTHERS as the final safety net
   EXPECTED : "Unexpected error" message together with the Oracle error code.
   --------------------------------------------------------------------------- */
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM no_such_table;   -- deliberate error
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error caught: '||SQLERRM||
                         ' (code '||SQLCODE||')');
END;
/


/* ---------------------------------------------------------------------------
   TEST 30 - Calling the packages (the bundled API)
   EXPECTED : the messages of the wrapped procedures.
   --------------------------------------------------------------------------- */
BEGIN
  student_management_pkg.add_student_record(
    p_first_name    => 'Package',
    p_last_name     => 'Demo',
    p_email         => 'package.demo@college.edu',
    p_date_of_birth => DATE '2005-05-05',
    p_gender        => 'Female',
    p_department_id => 2);
END;
/

SELECT student_management_pkg.get_student_information(student_id) AS info
  FROM students
 WHERE email = 'package.demo@college.edu';

SELECT academic_management_pkg.get_attendance_percentage(2, 1)    AS pkg_attendance FROM dual;
SELECT academic_management_pkg.calculate_academic_performance(1)   AS pkg_performance FROM dual;


/* ###########################################################################
   SECTION D - FINAL STATE / AUDIT VERIFICATION
   ########################################################################### */

/* The audit trigger must have logged all the changes made to STUDENTS */
SELECT log_id, table_name, operation_type, record_id,
       TO_CHAR(operation_date,'DD-MON-YYYY HH24:MI:SS') AS log_time, description
  FROM audit_log
 ORDER BY log_id;

/* Final row counts of every table */
SELECT 'DEPARTMENTS' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'STUDENTS',     COUNT(*) FROM students
UNION ALL SELECT 'COURSES',      COUNT(*) FROM courses
UNION ALL SELECT 'ENROLLMENTS',  COUNT(*) FROM enrollments
UNION ALL SELECT 'ATTENDANCE',   COUNT(*) FROM attendance
UNION ALL SELECT 'EXAMINATIONS', COUNT(*) FROM examinations
UNION ALL SELECT 'MARKS',        COUNT(*) FROM marks
UNION ALL SELECT 'FEES',         COUNT(*) FROM fees
UNION ALL SELECT 'AUDIT_LOG',    COUNT(*) FROM audit_log
ORDER BY table_name;

/* ---------------------------------------------------------------------------
   OPTIONAL CLEANUP
   Uncomment and run these lines if you want to remove the data created by the
   tests and return the database to its sample-data state.
   --------------------------------------------------------------------------- */
-- DELETE FROM attendance  WHERE student_id IN (SELECT student_id FROM students WHERE email LIKE '%demo@college.edu');
-- DELETE FROM enrollments WHERE student_id IN (SELECT student_id FROM students WHERE email LIKE '%demo@college.edu');
-- DELETE FROM fees        WHERE student_id IN (SELECT student_id FROM students WHERE email LIKE '%demo@college.edu');
-- DELETE FROM marks       WHERE student_id IN (SELECT student_id FROM students WHERE email LIKE '%demo@college.edu');
-- DELETE FROM students    WHERE email LIKE '%demo@college.edu';
-- COMMIT;

/* ============================================================================
   END OF 11_test_cases.sql
   ============================================================================ */
