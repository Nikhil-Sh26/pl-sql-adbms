/* ============================================================================
   FILE    : 05_create_functions.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Create the 5 stored functions used for calculations and reports.
   ENV     : Oracle FreeSQL
   RUN     : FIFTH (after 01-04)
   ============================================================================
   A FUNCTION always RETURNS a value and is normally called from a SELECT,
   a WHERE clause or another PL/SQL block.
   RETURN CONVENTION USED HERE
     - Numeric functions return -1 when the student does not exist, so that
       they can be used safely inside SQL queries.
     - Functions never COMMIT (a SELECT must not change data).
   ============================================================================ */


/* ===========================================================================
   1. GET_STUDENT_DETAILS
   Returns one readable line with the student's basic information.
   Demonstrates a JOIN inside a function and NO_DATA_FOUND handling.
   =========================================================================== */
CREATE OR REPLACE FUNCTION get_student_details (
  p_student_id IN NUMBER
) RETURN VARCHAR2 IS
  v_result VARCHAR2(400);
  v_count  NUMBER;
  e_student_not_found EXCEPTION;
BEGIN
  SELECT COUNT(*) INTO v_count FROM students WHERE student_id = p_student_id;
  IF v_count = 0 THEN
    RAISE e_student_not_found;
  END IF;

  SELECT s.student_id||' | '||s.first_name||' '||s.last_name
         ||' | '||s.email
         ||' | Dept: '||d.department_name
         ||' | Status: '||s.student_status
         ||' | Admitted: '||TO_CHAR(s.admission_date,'DD-MON-YYYY')
    INTO v_result
    FROM students s
    JOIN departments d ON d.department_id = s.department_id
   WHERE s.student_id = p_student_id;

  RETURN v_result;

EXCEPTION
  WHEN e_student_not_found THEN
    RETURN 'ERROR: Student ID '||p_student_id||' not found.';
  WHEN OTHERS THEN
    RETURN 'ERROR: '||SQLERRM;
END get_student_details;
/


/* ===========================================================================
   2. CALCULATE_ATTENDANCE_PERCENTAGE
   Percentage = (number of ''Present'' records) / (total records) * 100.
   Leave is counted in the total, so it lowers the percentage.
   If p_course_id is supplied the calculation is limited to that course.
   Demonstrates ZERO_DIVIDE handling.
   =========================================================================== */
CREATE OR REPLACE FUNCTION calculate_attendance_percentage (
  p_student_id IN NUMBER,
  p_course_id  IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
  v_total   NUMBER := 0;
  v_present NUMBER := 0;
  v_exists  NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM students WHERE student_id = p_student_id;
  IF v_exists = 0 THEN
    RETURN -1;              -- caller convention: student not found
  END IF;

  SELECT COUNT(*),
         NVL(SUM(CASE WHEN attendance_status = 'Present' THEN 1 ELSE 0 END),0)
    INTO v_total, v_present
    FROM attendance
   WHERE student_id = p_student_id
     AND (p_course_id IS NULL OR course_id = p_course_id);

  RETURN ROUND(v_present / v_total * 100, 2);

EXCEPTION
  WHEN ZERO_DIVIDE THEN
    RETURN 0;               -- no attendance recorded yet
  WHEN OTHERS THEN
    RETURN -1;
END calculate_attendance_percentage;
/


/* ===========================================================================
   3. CALCULATE_STUDENT_CGPA_OR_AVERAGE
   Average performance across all examinations, expressed as a percentage:
        AVG( marks_obtained / maximum_marks * 100 )
   Returns 0 when the student has no marks yet.
   =========================================================================== */
CREATE OR REPLACE FUNCTION calculate_student_cgpa_or_average (
  p_student_id IN NUMBER
) RETURN NUMBER IS
  v_avg    NUMBER;
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM students WHERE student_id = p_student_id;
  IF v_exists = 0 THEN
    RETURN -1;
  END IF;

  SELECT AVG(m.marks_obtained / e.maximum_marks * 100)
    INTO v_avg
    FROM marks m
    JOIN examinations e ON e.exam_id = m.exam_id
   WHERE m.student_id = p_student_id;

  RETURN ROUND(NVL(v_avg,0),2);

EXCEPTION
  WHEN OTHERS THEN
    RETURN -1;
END calculate_student_cgpa_or_average;
/


/* ===========================================================================
   4. GET_STUDENT_FEE_BALANCE
   Total amount still due from the student (sum of all fee accounts).
   =========================================================================== */
CREATE OR REPLACE FUNCTION get_student_fee_balance (
  p_student_id IN NUMBER
) RETURN NUMBER IS
  v_balance NUMBER;
  v_exists  NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM students WHERE student_id = p_student_id;
  IF v_exists = 0 THEN
    RETURN -1;
  END IF;

  SELECT NVL(SUM(due_amount),0) INTO v_balance
    FROM fees
   WHERE student_id = p_student_id;

  RETURN v_balance;

EXCEPTION
  WHEN OTHERS THEN
    RETURN -1;
END get_student_fee_balance;
/


/* ===========================================================================
   5. GET_STUDENT_RESULT
   Returns the result of one student in one examination:
   'PASS', 'FAIL', 'ABSENT' or 'NOT ENTERED'.
   Demonstrates NO_DATA_FOUND handling.
   =========================================================================== */
CREATE OR REPLACE FUNCTION get_student_result (
  p_student_id IN NUMBER,
  p_exam_id    IN NUMBER
) RETURN VARCHAR2 IS
  v_result VARCHAR2(15);
BEGIN
  SELECT result_status
    INTO v_result
    FROM marks
   WHERE student_id = p_student_id
     AND exam_id    = p_exam_id;

  RETURN NVL(v_result,'NOT ENTERED');

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'NOT ENTERED';
  WHEN OTHERS THEN
    RETURN 'ERROR: '||SQLERRM;
END get_student_result;
/

/* ============================================================================
   VERIFY - list all functions that were created
   ============================================================================ */
SELECT object_name, status
  FROM user_objects
 WHERE object_type = 'FUNCTION'
 ORDER BY object_name;

/* ============================================================================
   END OF 05_create_functions.sql
   ============================================================================ */
