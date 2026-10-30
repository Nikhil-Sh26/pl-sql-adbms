/* ============================================================================
   FILE    : 07_create_cursors.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Demonstrate the three cursor styles required by the project.
   ENV     : Oracle FreeSQL
   RUN     : SEVENTH (after 01-06)
   ============================================================================
   WHAT A CURSOR IS
   A cursor is a pointer to the result of a query. It lets PL/SQL process the
   rows one by one instead of all at once.
   LIFE CYCLE OF AN EXPLICIT CURSOR
     1. DECLARE  - define the query (no rows are read yet)
     2. OPEN     - execute the query and position before the first row
     3. FETCH    - read the next row into variables
     4. CLOSE    - release the resources
   A cursor FOR loop does steps 2-4 for you automatically.

   These blocks only WRITE to DBMS_OUTPUT, they do not change any data, so no
   COMMIT is needed. Each block is followed by the equivalent SELECT query that
   you can run if DBMS_OUTPUT is not enabled.
   ============================================================================ */

/* ===========================================================================
   DEMO 1 - EXPLICIT CURSOR: display all students
   =========================================================================== */
DECLARE
  /* 1. DECLARE the cursor */
  CURSOR c_students IS
    SELECT s.student_id, s.first_name, s.last_name,
           d.department_name, s.student_status
      FROM students s
      JOIN departments d ON d.department_id = s.department_id
     ORDER BY s.student_id;

  v_row c_students%ROWTYPE;         -- record that matches the cursor columns
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- ALL STUDENTS ---');

  OPEN c_students;                  -- 2. OPEN

  LOOP
    FETCH c_students INTO v_row;    -- 3. FETCH
    EXIT WHEN c_students%NOTFOUND;  -- stop when no row is left

    DBMS_OUTPUT.PUT_LINE(
      RPAD(v_row.student_id, 5)||' '||
      RPAD(v_row.first_name||' '||v_row.last_name, 25)||' '||
      RPAD(v_row.department_name, 25)||v_row.student_status);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Total rows fetched: '||c_students%ROWCOUNT);

  CLOSE c_students;                 -- 4. CLOSE
END;
/

/* Equivalent plain SQL query (use this if DBMS_OUTPUT is unavailable) */
SELECT s.student_id, s.first_name||' '||s.last_name AS student_name,
       d.department_name, s.student_status
  FROM students s
  JOIN departments d ON d.department_id = s.department_id
 ORDER BY s.student_id;


/* ===========================================================================
   DEMO 2 - PARAMETERIZED CURSOR: students of one department
   The parameter makes the same cursor reusable for any department.
   =========================================================================== */
DECLARE
  CURSOR c_dept_students (p_department_id NUMBER) IS
    SELECT student_id, first_name, last_name, email, student_status
      FROM students
     WHERE department_id = p_department_id
     ORDER BY student_id;

  v_row c_dept_students%ROWTYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- STUDENTS OF DEPARTMENT 1 (Computer Science) ---');

  OPEN c_dept_students(1);          -- pass the department id as the parameter

  LOOP
    FETCH c_dept_students INTO v_row;
    EXIT WHEN c_dept_students%NOTFOUND;

    DBMS_OUTPUT.PUT_LINE(
      RPAD(v_row.student_id,5)||' '||
      RPAD(v_row.first_name||' '||v_row.last_name,25)||' '||v_row.email);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Rows for department 1: '||c_dept_students%ROWCOUNT);
  CLOSE c_dept_students;
END;
/

/* Equivalent plain SQL query */
SELECT student_id, first_name||' '||last_name AS student_name, email, student_status
  FROM students
 WHERE department_id = 1
 ORDER BY student_id;


/* ===========================================================================
   DEMO 3 - CURSOR FOR LOOP: display all examination results
   The loop variable is declared automatically and OPEN / FETCH / CLOSE
   are handled by Oracle.
   =========================================================================== */
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- EXAMINATION RESULTS ---');

  FOR r IN (
        SELECT s.student_id,
               s.first_name||' '||s.last_name AS student_name,
               c.course_name,
               e.exam_name,
               m.marks_obtained,
               e.maximum_marks,
               m.grade,
               m.result_status
          FROM marks m
          JOIN students     s ON s.student_id = m.student_id
          JOIN examinations e ON e.exam_id    = m.exam_id
          JOIN courses      c ON c.course_id  = e.course_id
         ORDER BY s.student_id, e.exam_id
       )
  LOOP
    DBMS_OUTPUT.PUT_LINE(
      RPAD(r.student_id,5)||' '||
      RPAD(r.student_name,22)||' '||
      RPAD(r.course_name,28)||' '||
      RPAD(r.marks_obtained||'/'||r.maximum_marks,10)||' '||
      RPAD(r.grade,3)||' '||r.result_status);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('End of results.');
END;
/

/* Equivalent plain SQL query */
SELECT s.student_id, s.first_name||' '||s.last_name AS student_name,
       c.course_name, e.exam_name,
       m.marks_obtained||'/'||e.maximum_marks AS score,
       m.grade, m.result_status
  FROM marks m
  JOIN students     s ON s.student_id = m.student_id
  JOIN examinations e ON e.exam_id    = m.exam_id
  JOIN courses      c ON c.course_id  = e.course_id
 ORDER BY s.student_id, e.exam_id;

/* ============================================================================
   NOTE
   Cursors are also used inside procedures/functions (an implicit cursor is
   created for every DML statement - that is what SQL%ROWCOUNT and SQL%FOUND
   refer to). The three styles shown above are the ones asked for in the
   project specification.
   ============================================================================
   END OF 07_create_cursors.sql
   ============================================================================ */
