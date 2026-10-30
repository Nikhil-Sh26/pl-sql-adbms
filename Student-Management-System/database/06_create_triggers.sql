/* ============================================================================
   FILE    : 06_create_triggers.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Create the 12 triggers of the project.
   ENV     : Oracle FreeSQL
   RUN     : SIXTH (after 01-05)  --  must run BEFORE 11_test_cases.sql
   ============================================================================
   WHAT A TRIGGER IS
   A trigger is PL/SQL that the database runs AUTOMATICALLY when a table event
   occurs. If this file is not executed the procedures that rely on it
   (ID generation, fee due amount) will fail.

   TRIGGER LIST AND WHEN EACH ONE FIRES
   GROUP A - ID generation (BEFORE INSERT, one per table)      -> 9 triggers
   GROUP B - TRG_STUDENTS_AUDIT     AFTER INSERT/UPDATE/DELETE on students
   GROUP C - TRG_MARKS_VALIDATE     BEFORE INSERT or UPDATE on marks
   GROUP D - TRG_FEES_MAINTAIN      BEFORE INSERT or UPDATE on fees
   ============================================================================ */


/* ===========================================================================
   GROUP A - ID GENERATION TRIGGERS
   FIRES      : BEFORE INSERT, FOR EACH ROW.
   WHAT IT DOES: if no id was supplied, take the next value from the sequence.
   WHY          : keeps every INSERT simple (id column can be left out) while
                  still allowing explicit ids when loading data.
   =========================================================================== */
CREATE OR REPLACE TRIGGER trg_departments_bi
BEFORE INSERT ON departments FOR EACH ROW
BEGIN
  IF :NEW.department_id IS NULL THEN
    :NEW.department_id := seq_department_id.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_students_bi
BEFORE INSERT ON students FOR EACH ROW
BEGIN
  IF :NEW.student_id IS NULL THEN
    :NEW.student_id := seq_student_id.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_courses_bi
BEFORE INSERT ON courses FOR EACH ROW
BEGIN
  IF :NEW.course_id IS NULL THEN
    :NEW.course_id := seq_course_id.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_enrollments_bi
BEFORE INSERT ON enrollments FOR EACH ROW
BEGIN
  IF :NEW.enrollment_id IS NULL THEN
    :NEW.enrollment_id := seq_enrollment_id.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_attendance_bi
BEFORE INSERT ON attendance FOR EACH ROW
BEGIN
  IF :NEW.attendance_id IS NULL THEN
    :NEW.attendance_id := seq_attendance_id.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_examinations_bi
BEFORE INSERT ON examinations FOR EACH ROW
BEGIN
  IF :NEW.exam_id IS NULL THEN
    :NEW.exam_id := seq_exam_id.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_marks_bi
BEFORE INSERT ON marks FOR EACH ROW
BEGIN
  IF :NEW.marks_id IS NULL THEN
    :NEW.marks_id := seq_marks_id.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_fees_bi
BEFORE INSERT ON fees FOR EACH ROW
BEGIN
  IF :NEW.fee_id IS NULL THEN
    :NEW.fee_id := seq_fee_id.NEXTVAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_audit_log_bi
BEFORE INSERT ON audit_log FOR EACH ROW
BEGIN
  IF :NEW.log_id IS NULL THEN
    :NEW.log_id := seq_log_id.NEXTVAL;
  END IF;
END;
/


/* ===========================================================================
   GROUP B - TRG_STUDENTS_AUDIT
   FIRES      : AFTER INSERT / UPDATE / DELETE on STUDENTS, FOR EACH ROW.
   WHAT IT DOES: writes one row into AUDIT_LOG describing the change.
   NOTE       : it is an AFTER trigger because we only want to log changes
                that really happened.
   =========================================================================== */
CREATE OR REPLACE TRIGGER trg_students_audit
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW
DECLARE
  v_op   VARCHAR2(10);
  v_id   NUMBER;
  v_desc VARCHAR2(400);
BEGIN
  IF INSERTING THEN
    v_op   := 'INSERT';
    v_id   := :NEW.student_id;
    v_desc := 'New student added: '||:NEW.first_name||' '||:NEW.last_name||
              ' (email '||:NEW.email||', dept '||:NEW.department_id||
              ', status '||:NEW.student_status||')';

  ELSIF UPDATING THEN
    v_op   := 'UPDATE';
    v_id   := :NEW.student_id;
    v_desc := 'Student updated: status '||:OLD.student_status||' -> '||:NEW.student_status||
              ', dept '||:OLD.department_id||' -> '||:NEW.department_id;

  ELSE
    v_op   := 'DELETE';
    v_id   := :OLD.student_id;
    v_desc := 'Student deleted: '||:OLD.first_name||' '||:OLD.last_name||
              ' (email '||:OLD.email||')';
  END IF;

  INSERT INTO audit_log (table_name, operation_type, record_id, operation_date, description)
  VALUES ('STUDENTS', v_op, v_id, SYSDATE, v_desc);
END;
/


/* ===========================================================================
   GROUP C - TRG_MARKS_VALIDATE
   FIRES      : BEFORE INSERT or BEFORE UPDATE on MARKS.
   WHAT IT DOES:
     1. blocks marks greater than the maximum marks of the examination
        (business rule 4) with RAISE_APPLICATION_ERROR;
     2. computes result_status PASS / FAIL from passing_marks (rule 5);
     3. computes the letter grade from the percentage.
   =========================================================================== */
CREATE OR REPLACE TRIGGER trg_marks_validate
BEFORE INSERT OR UPDATE ON marks
FOR EACH ROW
DECLARE
  v_max NUMBER;
  v_pass NUMBER;
  v_pct  NUMBER;
BEGIN
  SELECT maximum_marks, passing_marks
    INTO v_max, v_pass
    FROM examinations
   WHERE exam_id = :NEW.exam_id;

  IF :NEW.marks_obtained > v_max THEN
    RAISE_APPLICATION_ERROR(-20005,
      'Marks '||:NEW.marks_obtained||' exceed the maximum of '||v_max||
      ' for examination '||:NEW.exam_id);
  END IF;

  /* automatic pass / fail */
  IF :NEW.marks_obtained >= v_pass THEN
    :NEW.result_status := 'PASS';
  ELSE
    :NEW.result_status := 'FAIL';
  END IF;

  /* automatic grade based on percentage */
  v_pct := ROUND(:NEW.marks_obtained / v_max * 100, 2);
  :NEW.grade := CASE
                  WHEN v_pct >= 90 THEN 'A+'
                  WHEN v_pct >= 80 THEN 'A'
                  WHEN v_pct >= 70 THEN 'B'
                  WHEN v_pct >= 60 THEN 'C'
                  WHEN v_pct >= 50 THEN 'D'
                  ELSE 'F'
                END;
END;
/


/* ===========================================================================
   GROUP D - TRG_FEES_MAINTAIN
   FIRES      : BEFORE INSERT or BEFORE UPDATE on FEES.
   WHAT IT DOES:
     1. recalculates due_amount = total_fee - paid_amount;
     2. blocks a payment larger than the total fee;
     3. sets payment_status to PENDING / PARTIAL / PAID automatically.
   This guarantees the fee columns can never become inconsistent.
   =========================================================================== */
CREATE OR REPLACE TRIGGER trg_fees_maintain
BEFORE INSERT OR UPDATE ON fees
FOR EACH ROW
BEGIN
  :NEW.due_amount := :NEW.total_fee - :NEW.paid_amount;

  IF :NEW.due_amount < 0 THEN
    RAISE_APPLICATION_ERROR(-20006,
      'Payment exceeds total fee for student '||:NEW.student_id||
      ' (total '||:NEW.total_fee||', paid '||:NEW.paid_amount||')');
  END IF;

  IF :NEW.paid_amount = 0 THEN
    :NEW.payment_status := 'PENDING';
  ELSIF :NEW.paid_amount < :NEW.total_fee THEN
    :NEW.payment_status := 'PARTIAL';
  ELSE
    :NEW.payment_status := 'PAID';
  END IF;
END;
/

/* ============================================================================
   VERIFY - list all triggers and their status
   ============================================================================ */
SELECT trigger_name, triggering_event, table_name, status
  FROM user_triggers
 ORDER BY table_name, trigger_name;

/* ============================================================================
   END OF 06_create_triggers.sql
   ============================================================================ */
