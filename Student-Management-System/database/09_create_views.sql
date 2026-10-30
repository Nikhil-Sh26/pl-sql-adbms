/* ============================================================================
   FILE    : 09_create_views.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Create the four reporting views required by the project.
   ENV     : Oracle FreeSQL
   RUN     : NINTH (after 01-08)
   ============================================================================
   WHAT A VIEW IS
   A view is a saved query that behaves like a virtual table. It stores no data
   of its own; it runs the underlying query every time it is used. Views keep
   complex JOINs and calculations in one place so that reports stay short and
   consistent.
   ============================================================================ */


/* ===========================================================================
   1. STUDENT_DETAILS_VIEW
   One row per student with the department name resolved (JOIN).
   =========================================================================== */
CREATE OR REPLACE VIEW student_details_view AS
SELECT s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       s.email,
       s.phone,
       s.gender,
       s.date_of_birth,
       s.address,
       s.admission_date,
       s.student_status,
       d.department_id,
       d.department_name,
       d.department_code
  FROM students s
  JOIN departments d ON d.department_id = s.department_id;


/* ===========================================================================
   2. STUDENT_ATTENDANCE_VIEW
   Attendance summary per student and course:
   total sessions, present / absent / leave counts and the percentage.
   Percentage = present / total * 100  (the same rule as the function).
   =========================================================================== */
CREATE OR REPLACE VIEW student_attendance_view AS
SELECT s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       c.course_id,
       c.course_name,
       COUNT(a.attendance_id) AS total_sessions,
       SUM(CASE WHEN a.attendance_status = 'Present' THEN 1 ELSE 0 END) AS present_count,
       SUM(CASE WHEN a.attendance_status = 'Absent'  THEN 1 ELSE 0 END) AS absent_count,
       SUM(CASE WHEN a.attendance_status = 'Leave'   THEN 1 ELSE 0 END) AS leave_count,
       ROUND(SUM(CASE WHEN a.attendance_status = 'Present' THEN 1 ELSE 0 END)
             / COUNT(a.attendance_id) * 100, 2) AS attendance_percentage
  FROM attendance a
  JOIN students s ON s.student_id = a.student_id
  JOIN courses  c ON c.course_id  = a.course_id
 GROUP BY s.student_id, s.first_name, s.last_name, c.course_id, c.course_name;


/* ===========================================================================
   3. STUDENT_RESULTS_VIEW
   One row per student per examination with marks, grade, result and
   percentage.
   =========================================================================== */
CREATE OR REPLACE VIEW student_results_view AS
SELECT s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       c.course_id,
       c.course_name,
       e.exam_id,
       e.exam_name,
       e.exam_date,
       e.maximum_marks,
       e.passing_marks,
       m.marks_obtained,
       m.grade,
       m.result_status,
       ROUND(m.marks_obtained / e.maximum_marks * 100, 2) AS percentage
  FROM marks m
  JOIN students     s ON s.student_id = m.student_id
  JOIN examinations e ON e.exam_id    = m.exam_id
  JOIN courses      c ON c.course_id  = e.course_id;


/* ===========================================================================
   4. STUDENT_FEES_VIEW
   One row per fee account with the student name.
   =========================================================================== */
CREATE OR REPLACE VIEW student_fees_view AS
SELECT s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       f.fee_id,
       f.total_fee,
       f.paid_amount,
       f.due_amount,
       f.payment_status,
       f.payment_method,
       f.payment_date
  FROM fees f
  JOIN students s ON s.student_id = f.student_id;

/* ============================================================================
   VERIFY - list the four views and check their contents
   ============================================================================ */
SELECT view_name, status FROM user_views ORDER BY view_name;

SELECT * FROM student_details_view  ORDER BY student_id;
SELECT * FROM student_attendance_view ORDER BY student_id, course_id;
SELECT * FROM student_results_view  ORDER BY student_id, exam_id;
SELECT * FROM student_fees_view     ORDER BY student_id;

/* ============================================================================
   END OF 09_create_views.sql
   ============================================================================ */
