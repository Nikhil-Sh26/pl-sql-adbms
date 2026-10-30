/* ============================================================================
   FILE    : 02_create_sequences.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Create one sequence per table for primary-key generation.
   ENV     : Oracle FreeSQL
   RUN     : SECOND (after 01_create_tables.sql)
   ============================================================================
   WHY SEQUENCES?
   Oracle sequences are independent counters. They are safe (no duplicates,
   no locking) and work in every Oracle version - unlike IDENTITY columns
   which are unavailable in older databases. Each table gets its own sequence
   and a BEFORE INSERT trigger uses .NEXTVAL to fill the primary key.
   NOCACHE is used so numbers are easy to follow while learning.
   ============================================================================ */

CREATE SEQUENCE seq_department_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_student_id    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_course_id     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_enrollment_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_attendance_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_exam_id       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_marks_id      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_fee_id        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_log_id        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

/* VERIFY: list all sequences created for this project */
SELECT sequence_name, min_value, increment_by, last_number
  FROM user_sequences
 WHERE sequence_name LIKE 'SEQ\_%' ESCAPE '\'
 ORDER BY sequence_name;

/* ============================================================================
   END OF 02_create_sequences.sql
   ============================================================================ */
