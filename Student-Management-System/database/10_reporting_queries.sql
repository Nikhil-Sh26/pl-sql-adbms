/* ============================================================================
   FILE    : 10_reporting_queries.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : The 14 reporting / analytical queries required by the project.
   ENV     : Oracle FreeSQL
   RUN     : TENTH (after 01-09) - run any query on its own
   ============================================================================
   TECHNIQUES USED
   JOIN, LEFT JOIN, GROUP BY, HAVING, subqueries, aggregate functions
   (COUNT, SUM, AVG, MAX, MIN), CASE and the analytic function RANK().
   ============================================================================ */


/* ---------------------------------------------------------------------------
   REPORT 1 - All registered students
   --------------------------------------------------------------------------- */
SELECT student_id, student_name, email, department_name, student_status
  FROM student_details_view
 ORDER BY student_id;


/* ---------------------------------------------------------------------------
   REPORT 2 - Students department-wise
   --------------------------------------------------------------------------- */
SELECT d.department_name,
       s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       s.student_status
  FROM students s
  JOIN departments d ON d.department_id = s.department_id
 ORDER BY d.department_name, s.student_id;


/* ---------------------------------------------------------------------------
   REPORT 3 - Students enrolled in a particular course
   Change the course id (here 1 = Data Structures).
   --------------------------------------------------------------------------- */
SELECT e.course_id,
       c.course_name,
       s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       e.academic_year,
       e.semester,
       e.enrollment_status
  FROM enrollments e
  JOIN students s ON s.student_id = e.student_id
  JOIN courses  c ON c.course_id  = e.course_id
 WHERE e.course_id = 1
 ORDER BY s.student_id;


/* ---------------------------------------------------------------------------
   REPORT 4 - Semester-wise enrollment statistics
   --------------------------------------------------------------------------- */
SELECT academic_year,
       semester,
       COUNT(*)                       AS total_enrollments,
       COUNT(DISTINCT student_id)     AS distinct_students,
       COUNT(DISTINCT course_id)      AS distinct_courses
  FROM enrollments
 GROUP BY academic_year, semester
 ORDER BY academic_year, semester;


/* ---------------------------------------------------------------------------
   REPORT 5 - Student attendance percentage (overall, per student)
   --------------------------------------------------------------------------- */
SELECT s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       COUNT(a.attendance_id) AS total_sessions,
       SUM(CASE WHEN a.attendance_status = 'Present' THEN 1 ELSE 0 END) AS present_count,
       ROUND(SUM(CASE WHEN a.attendance_status = 'Present' THEN 1 ELSE 0 END)
             / COUNT(a.attendance_id) * 100, 2) AS attendance_percentage
  FROM students s
  JOIN attendance a ON a.student_id = s.student_id
 GROUP BY s.student_id, s.first_name, s.last_name
 ORDER BY attendance_percentage DESC;


/* ---------------------------------------------------------------------------
   REPORT 6 - Students with attendance below 75%  (HAVING filter)
   --------------------------------------------------------------------------- */
SELECT s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       COUNT(a.attendance_id) AS total_sessions,
       ROUND(SUM(CASE WHEN a.attendance_status = 'Present' THEN 1 ELSE 0 END)
             / COUNT(a.attendance_id) * 100, 2) AS attendance_percentage
  FROM students s
  JOIN attendance a ON a.student_id = s.student_id
 GROUP BY s.student_id, s.first_name, s.last_name
HAVING ROUND(SUM(CASE WHEN a.attendance_status = 'Present' THEN 1 ELSE 0 END)
             / COUNT(a.attendance_id) * 100, 2) < 75
 ORDER BY attendance_percentage;


/* ---------------------------------------------------------------------------
   REPORT 7 - Examination results
   --------------------------------------------------------------------------- */
SELECT student_id, student_name, course_name, exam_name,
       marks_obtained, maximum_marks, percentage, grade, result_status
  FROM student_results_view
 ORDER BY student_id, exam_id;


/* ---------------------------------------------------------------------------
   REPORT 8 - Top-performing students (ranked by average percentage)
   --------------------------------------------------------------------------- */
SELECT * FROM (
  SELECT s.student_id,
         s.first_name||' '||s.last_name AS student_name,
         ROUND(AVG(m.marks_obtained / e.maximum_marks * 100), 2) AS average_percentage,
         RANK() OVER (ORDER BY AVG(m.marks_obtained / e.maximum_marks * 100) DESC) AS position
    FROM students s
    JOIN marks m        ON m.student_id = s.student_id
    JOIN examinations e ON e.exam_id    = m.exam_id
   GROUP BY s.student_id, s.first_name, s.last_name
)
 WHERE position <= 5
 ORDER BY position;


/* ---------------------------------------------------------------------------
   REPORT 9 - Department-wise student count
   --------------------------------------------------------------------------- */
SELECT d.department_id,
       d.department_name,
       COUNT(s.student_id) AS total_students
  FROM departments d
  LEFT JOIN students s ON s.department_id = d.department_id
 GROUP BY d.department_id, d.department_name
 ORDER BY total_students DESC;


/* ---------------------------------------------------------------------------
   REPORT 10 - Course-wise student enrollment count
   --------------------------------------------------------------------------- */
SELECT c.course_id,
       c.course_name,
       c.course_code,
       COUNT(e.enrollment_id) AS total_enrollments
  FROM courses c
  LEFT JOIN enrollments e ON e.course_id = c.course_id
 GROUP BY c.course_id, c.course_name, c.course_code
 ORDER BY total_enrollments DESC;


/* ---------------------------------------------------------------------------
   REPORT 11 - Students who have failed an examination
   --------------------------------------------------------------------------- */
SELECT student_id, student_name, course_name, exam_name,
       marks_obtained, maximum_marks, result_status
  FROM student_results_view
 WHERE result_status = 'FAIL'
 ORDER BY student_id;


/* ---------------------------------------------------------------------------
   REPORT 12 - Students with pending fee balances
   --------------------------------------------------------------------------- */
SELECT student_id, student_name, total_fee, paid_amount, due_amount, payment_status
  FROM student_fees_view
 WHERE due_amount > 0
 ORDER BY due_amount DESC;


/* ---------------------------------------------------------------------------
   REPORT 13 - Student academic performance (subquery in the SELECT list)
   --------------------------------------------------------------------------- */
SELECT s.student_id,
       s.first_name||' '||s.last_name AS student_name,
       NVL((SELECT ROUND(AVG(m.marks_obtained / e.maximum_marks * 100), 2)
              FROM marks m
              JOIN examinations e ON e.exam_id = m.exam_id
             WHERE m.student_id = s.student_id), 0) AS average_percentage,
       NVL((SELECT COUNT(*)
              FROM marks m
             WHERE m.student_id = s.student_id
               AND m.result_status = 'FAIL'), 0) AS failed_exams
  FROM students s
 ORDER BY average_percentage DESC;


/* ---------------------------------------------------------------------------
   REPORT 14 - Overall institution statistics
   Uses scalar subqueries so the whole summary is a single row.
   --------------------------------------------------------------------------- */
SELECT (SELECT COUNT(*) FROM students)                          AS total_students,
       (SELECT COUNT(*) FROM students WHERE student_status = 'ACTIVE') AS active_students,
       (SELECT COUNT(*) FROM departments)                        AS total_departments,
       (SELECT COUNT(*) FROM courses)                            AS total_courses,
       (SELECT COUNT(*) FROM enrollments)                        AS total_enrollments,
       (SELECT COUNT(*) FROM examinations)                       AS total_examinations,
       (SELECT COUNT(*) FROM marks)                              AS total_marks_records,
       (SELECT ROUND(AVG(m.marks_obtained / e.maximum_marks * 100), 2)
          FROM marks m JOIN examinations e ON e.exam_id = m.exam_id) AS overall_average_percent,
       (SELECT NVL(SUM(due_amount), 0) FROM fees)                AS total_pending_fees
  FROM dual;

/* ============================================================================
   END OF 10_reporting_queries.sql
   ============================================================================ */
