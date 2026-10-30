/* ============================================================================
   FILE    : 04_create_procedures.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Create the 10 stored procedures that perform the main operations.
   ENV     : Oracle FreeSQL
   RUN     : FOURTH (after 01, 02, 03)
   ============================================================================
   HOW TO RUN IN FREESQL
   Paste one procedure at a time and press Run. Each block ends with a single
   "/" on its own line - that tells the worksheet the PL/SQL block is finished.
   To see the SUCCESS / ERROR messages, enable DBMS_OUTPUT (see README).
   If DBMS_OUTPUT is not visible, verify with a SELECT as shown in
   11_test_cases.sql.
   ============================================================================
   COMMON NAMING CONVENTIONS USED IN THIS PROJECT
     p_  = parameter        v_  = local variable
     e_  = user defined exception
     PK ids are NOT passed in: the BEFORE INSERT trigger (06) generates them.
     RETURNING INTO is used to capture the generated id.
   ============================================================================ */


/* ===========================================================================
   1. ADD_STUDENT
   Adds a student after validating that the department exists and that the
   gender / status values are allowed. DUPLICATE EMAIL is caught by the
   unique constraint (DUP_VAL_ON_INDEX).
   =========================================================================== */
CREATE OR REPLACE PROCEDURE add_student (
  p_first_name    IN VARCHAR2,
  p_last_name     IN VARCHAR2,
  p_email         IN VARCHAR2,
  p_phone         IN VARCHAR2 DEFAULT NULL,
  p_date_of_birth IN DATE,
  p_gender        IN VARCHAR2,
  p_address       IN VARCHAR2 DEFAULT NULL,
  p_department_id IN NUMBER,
  p_status        IN VARCHAR2 DEFAULT 'ACTIVE'
) IS
  v_dept_count NUMBER;
  v_new_id     NUMBER;
  e_invalid_department EXCEPTION;
  e_invalid_gender     EXCEPTION;
  e_invalid_status     EXCEPTION;
BEGIN
  /* --- Validate the department (business rule 1) --- */
  SELECT COUNT(*) INTO v_dept_count
    FROM departments
   WHERE department_id = p_department_id;

  IF v_dept_count = 0 THEN
    RAISE e_invalid_department;
  END IF;

  /* --- Validate allowed values before touching the table --- */
  IF p_gender NOT IN ('Male','Female','Other') THEN
    RAISE e_invalid_gender;
  END IF;

  IF p_status NOT IN ('ACTIVE','INACTIVE','GRADUATED') THEN
    RAISE e_invalid_status;
  END IF;

  /* --- Insert. The id column is omitted: the trigger fills it. --- */
  INSERT INTO students
    (first_name, last_name, email, phone, date_of_birth,
     gender, address, department_id, admission_date, student_status)
  VALUES
    (p_first_name, p_last_name, p_email, p_phone, p_date_of_birth,
     p_gender, p_address, p_department_id, SYSDATE, p_status)
  RETURNING student_id INTO v_new_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Student added with ID '||v_new_id||
                       ' ('||p_first_name||' '||p_last_name||').');

EXCEPTION
  WHEN e_invalid_department THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Department ID '||p_department_id||' does not exist.');
  WHEN e_invalid_gender THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Gender must be Male, Female or Other.');
  WHEN e_invalid_status THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Status must be ACTIVE, INACTIVE or GRADUATED.');
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Email '||p_email||' already exists. Emails must be unique.');
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END add_student;
/


/* ===========================================================================
   2. UPDATE_STUDENT
   Updates selected columns of an existing student. A NULL parameter means
   "leave this column unchanged" - handled with NVL.
   =========================================================================== */
CREATE OR REPLACE PROCEDURE update_student (
  p_student_id    IN NUMBER,
  p_phone         IN VARCHAR2 DEFAULT NULL,
  p_address       IN VARCHAR2 DEFAULT NULL,
  p_department_id IN NUMBER   DEFAULT NULL,
  p_status        IN VARCHAR2 DEFAULT NULL
) IS
  v_count NUMBER;
  e_student_not_found  EXCEPTION;
  e_invalid_department EXCEPTION;
  e_invalid_status     EXCEPTION;
BEGIN
  SELECT COUNT(*) INTO v_count FROM students WHERE student_id = p_student_id;
  IF v_count = 0 THEN
    RAISE e_student_not_found;
  END IF;

  IF p_department_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_count FROM departments WHERE department_id = p_department_id;
    IF v_count = 0 THEN
      RAISE e_invalid_department;
    END IF;
  END IF;

  IF p_status IS NOT NULL AND p_status NOT IN ('ACTIVE','INACTIVE','GRADUATED') THEN
    RAISE e_invalid_status;
  END IF;

  UPDATE students
     SET phone          = NVL(p_phone, phone),
         address        = NVL(p_address, address),
         department_id  = NVL(p_department_id, department_id),
         student_status = NVL(p_status, student_status)
   WHERE student_id = p_student_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Student '||p_student_id||' updated.');

EXCEPTION
  WHEN e_student_not_found THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student ID '||p_student_id||' not found.');
  WHEN e_invalid_department THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Department ID '||p_department_id||' does not exist.');
  WHEN e_invalid_status THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Status must be ACTIVE, INACTIVE or GRADUATED.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END update_student;
/


/* ===========================================================================
   3. DELETE_STUDENT
   Deletes a student only if no child records exist. Instead of letting the
   FOREIGN KEY fail with a raw Oracle error, we check first and give a
   meaningful message.
   =========================================================================== */
CREATE OR REPLACE PROCEDURE delete_student (
  p_student_id IN NUMBER
) IS
  v_count    NUMBER;
  v_children NUMBER;
  e_student_not_found EXCEPTION;
  e_child_records     EXCEPTION;
BEGIN
  SELECT COUNT(*) INTO v_count FROM students WHERE student_id = p_student_id;
  IF v_count = 0 THEN
    RAISE e_student_not_found;
  END IF;

  SELECT (SELECT COUNT(*) FROM enrollments WHERE student_id = p_student_id)
       + (SELECT COUNT(*) FROM attendance  WHERE student_id = p_student_id)
       + (SELECT COUNT(*) FROM marks       WHERE student_id = p_student_id)
       + (SELECT COUNT(*) FROM fees        WHERE student_id = p_student_id)
    INTO v_children
    FROM dual;

  IF v_children > 0 THEN
    RAISE e_child_records;
  END IF;

  DELETE FROM students WHERE student_id = p_student_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Student '||p_student_id||' deleted.');

EXCEPTION
  WHEN e_student_not_found THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student ID '||p_student_id||' not found.');
  WHEN e_child_records THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Student '||p_student_id||' has related records '||
                         '(enrollments/attendance/marks/fees) and cannot be deleted. '||
                         'Set student_status = ''INACTIVE'' instead.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END delete_student;
/


/* ===========================================================================
   4. ADD_DEPARTMENT
   =========================================================================== */
CREATE OR REPLACE PROCEDURE add_department (
  p_department_name IN VARCHAR2,
  p_department_code IN VARCHAR2,
  p_department_head IN VARCHAR2 DEFAULT NULL
) IS
  v_new_id NUMBER;
BEGIN
  INSERT INTO departments (department_name, department_code, department_head)
  VALUES (p_department_name, UPPER(p_department_code), p_department_head)
  RETURNING department_id INTO v_new_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Department added with ID '||v_new_id||'.');

EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Department code '||UPPER(p_department_code)||' already exists.');
  WHEN VALUE_ERROR THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Invalid value - check the length of the department name or code.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END add_department;
/


/* ===========================================================================
   5. ADD_COURSE
   =========================================================================== */
CREATE OR REPLACE PROCEDURE add_course (
  p_course_name        IN VARCHAR2,
  p_course_code        IN VARCHAR2,
  p_credits            IN NUMBER,
  p_department_id      IN NUMBER,
  p_course_description IN VARCHAR2 DEFAULT NULL
) IS
  v_count  NUMBER;
  v_new_id NUMBER;
  e_invalid_department EXCEPTION;
  e_invalid_credits    EXCEPTION;
BEGIN
  SELECT COUNT(*) INTO v_count FROM departments WHERE department_id = p_department_id;
  IF v_count = 0 THEN
    RAISE e_invalid_department;
  END IF;

  IF p_credits IS NULL OR p_credits < 1 OR p_credits > 10 THEN
    RAISE e_invalid_credits;
  END IF;

  INSERT INTO courses (course_name, course_code, credits, department_id, course_description)
  VALUES (p_course_name, UPPER(p_course_code), p_credits, p_department_id, p_course_description)
  RETURNING course_id INTO v_new_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Course added with ID '||v_new_id||'.');

EXCEPTION
  WHEN e_invalid_department THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Department ID '||p_department_id||' does not exist.');
  WHEN e_invalid_credits THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Credits must be between 1 and 10.');
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Course code '||UPPER(p_course_code)||' already exists.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END add_course;
/


/* ===========================================================================
   6. ENROLL_STUDENT
   Enrolls a student into a course. Enforces:
     - student exists and is ACTIVE (business rule 8)
     - course exists
     - no duplicate enrollment for the same year + semester (business rule 2)
   =========================================================================== */
CREATE OR REPLACE PROCEDURE enroll_student (
  p_student_id    IN NUMBER,
  p_course_id     IN NUMBER,
  p_academic_year IN VARCHAR2,
  p_semester      IN NUMBER
) IS
  v_status  students.student_status%TYPE;
  v_count   NUMBER;
  v_new_id  NUMBER;
  e_student_not_found    EXCEPTION;
  e_course_not_found     EXCEPTION;
  e_student_inactive     EXCEPTION;
  e_duplicate_enrollment EXCEPTION;
BEGIN
  /* --- student must exist --- */
  BEGIN
    SELECT student_status INTO v_status FROM students WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN RAISE e_student_not_found;
  END;

  /* --- student must be ACTIVE --- */
  IF v_status <> 'ACTIVE' THEN
    RAISE e_student_inactive;
  END IF;

  /* --- course must exist --- */
  SELECT COUNT(*) INTO v_count FROM courses WHERE course_id = p_course_id;
  IF v_count = 0 THEN
    RAISE e_course_not_found;
  END IF;

  /* --- no duplicate for same student + course + year + semester --- */
  SELECT COUNT(*) INTO v_count
    FROM enrollments
   WHERE student_id = p_student_id
     AND course_id  = p_course_id
     AND academic_year = p_academic_year
     AND semester   = p_semester;
  IF v_count > 0 THEN
    RAISE e_duplicate_enrollment;
  END IF;

  INSERT INTO enrollments (student_id, course_id, academic_year, semester)
  VALUES (p_student_id, p_course_id, p_academic_year, p_semester)
  RETURNING enrollment_id INTO v_new_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Enrollment '||v_new_id||' created - student '||
                       p_student_id||' enrolled in course '||p_course_id||'.');

EXCEPTION
  WHEN e_student_not_found THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student ID '||p_student_id||' not found.');
  WHEN e_course_not_found THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Course ID '||p_course_id||' not found.');
  WHEN e_student_inactive THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student '||p_student_id||' has status '||
                                   v_status||' and cannot be enrolled in new courses.');
  WHEN e_duplicate_enrollment THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student '||p_student_id||' is already enrolled in course '||
                                   p_course_id||' for '||p_academic_year||' semester '||p_semester||'.');
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Duplicate enrollment blocked by the unique constraint.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END enroll_student;
/


/* ===========================================================================
   7. MARK_ATTENDANCE
   Records one attendance row. Attendance is only allowed for a student who is
   enrolled in that course (business rule 3), and only once per date.
   =========================================================================== */
CREATE OR REPLACE PROCEDURE mark_attendance (
  p_student_id        IN NUMBER,
  p_course_id         IN NUMBER,
  p_attendance_date   IN DATE,
  p_attendance_status IN VARCHAR2,
  p_remarks           IN VARCHAR2 DEFAULT NULL
) IS
  v_count  NUMBER;
  v_new_id NUMBER;
  e_not_enrolled       EXCEPTION;
  e_invalid_status     EXCEPTION;
  e_duplicate_attendance EXCEPTION;
BEGIN
  IF p_attendance_status NOT IN ('Present','Absent','Leave') THEN
    RAISE e_invalid_status;
  END IF;

  /* --- the student must be actively enrolled in this course --- */
  SELECT COUNT(*) INTO v_count
    FROM enrollments
   WHERE student_id = p_student_id
     AND course_id  = p_course_id
     AND enrollment_status <> 'DROPPED';
  IF v_count = 0 THEN
    RAISE e_not_enrolled;
  END IF;

  /* --- one row per student, course and date --- */
  SELECT COUNT(*) INTO v_count
    FROM attendance
   WHERE student_id = p_student_id
     AND course_id  = p_course_id
     AND attendance_date = p_attendance_date;
  IF v_count > 0 THEN
    RAISE e_duplicate_attendance;
  END IF;

  INSERT INTO attendance (student_id, course_id, attendance_date, attendance_status, remarks)
  VALUES (p_student_id, p_course_id, p_attendance_date, p_attendance_status, p_remarks)
  RETURNING attendance_id INTO v_new_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Attendance '||v_new_id||' recorded - student '||
                       p_student_id||' on '||TO_CHAR(p_attendance_date,'DD-MON-YYYY')||
                       ' = '||p_attendance_status||'.');

EXCEPTION
  WHEN e_invalid_status THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Attendance status must be Present, Absent or Leave.');
  WHEN e_not_enrolled THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student '||p_student_id||' is not enrolled in course '||
                                   p_course_id||'. Attendance cannot be recorded.');
  WHEN e_duplicate_attendance THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Attendance for student '||p_student_id||' in course '||
                                   p_course_id||' on '||TO_CHAR(p_attendance_date,'DD-MON-YYYY')||
                                   ' is already recorded.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END mark_attendance;
/


/* ===========================================================================
   8. ADD_EXAMINATION
   =========================================================================== */
CREATE OR REPLACE PROCEDURE add_examination (
  p_course_id     IN NUMBER,
  p_exam_name     IN VARCHAR2,
  p_exam_date     IN DATE,
  p_maximum_marks IN NUMBER,
  p_passing_marks IN NUMBER,
  p_semester      IN NUMBER DEFAULT NULL
) IS
  v_count  NUMBER;
  v_new_id NUMBER;
  e_course_not_found EXCEPTION;
  e_invalid_marks    EXCEPTION;
BEGIN
  SELECT COUNT(*) INTO v_count FROM courses WHERE course_id = p_course_id;
  IF v_count = 0 THEN
    RAISE e_course_not_found;
  END IF;

  IF p_maximum_marks IS NULL OR p_maximum_marks <= 0
     OR p_passing_marks IS NULL OR p_passing_marks <= 0
     OR p_passing_marks > p_maximum_marks THEN
    RAISE e_invalid_marks;
  END IF;

  INSERT INTO examinations (course_id, exam_name, exam_date, maximum_marks, passing_marks, semester)
  VALUES (p_course_id, p_exam_name, p_exam_date, p_maximum_marks, p_passing_marks, p_semester)
  RETURNING exam_id INTO v_new_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Examination added with ID '||v_new_id||'.');

EXCEPTION
  WHEN e_course_not_found THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Course ID '||p_course_id||' does not exist.');
  WHEN e_invalid_marks THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Marks invalid - maximum and passing marks must be > 0 '||
                                   'and passing marks cannot exceed maximum marks.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END add_examination;
/


/* ===========================================================================
   9. ENTER_STUDENT_MARKS
   Enters the marks of one student in one examination.
   Business rules enforced here:
     - examination must exist (rule 9)
     - student must be enrolled in the course of that examination
     - no duplicate marks for the same student + exam
   The TRIGGER trg_marks_validate (06) blocks marks above maximum_marks and
   automatically fills grade and result_status (rule 5).
   =========================================================================== */
CREATE OR REPLACE PROCEDURE enter_student_marks (
  p_student_id     IN NUMBER,
  p_exam_id        IN NUMBER,
  p_marks_obtained IN NUMBER,
  p_remarks        IN VARCHAR2 DEFAULT NULL
) IS
  v_course_id  NUMBER;
  v_max_marks  NUMBER;
  v_count      NUMBER;
  v_new_id     NUMBER;
  e_exam_not_found   EXCEPTION;
  e_not_enrolled     EXCEPTION;
  e_negative_marks   EXCEPTION;
  e_duplicate_marks  EXCEPTION;
BEGIN
  /* --- examination must exist (rule 9); capture its course and max marks --- */
  BEGIN
    SELECT course_id, maximum_marks
      INTO v_course_id, v_max_marks
      FROM examinations
     WHERE exam_id = p_exam_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN RAISE e_exam_not_found;
  END;

  IF p_marks_obtained IS NULL OR p_marks_obtained < 0 THEN
    RAISE e_negative_marks;
  END IF;

  /* --- friendly check before the trigger fires --- */
  IF p_marks_obtained > v_max_marks THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Marks '||p_marks_obtained||' exceed the maximum of '||
                         v_max_marks||' for examination '||p_exam_id||'.');
    RETURN;
  END IF;

  /* --- student must be enrolled in the course --- */
  SELECT COUNT(*) INTO v_count
    FROM enrollments
   WHERE student_id = p_student_id
     AND course_id  = v_course_id;
  IF v_count = 0 THEN
    RAISE e_not_enrolled;
  END IF;

  /* --- no duplicate marks --- */
  SELECT COUNT(*) INTO v_count
    FROM marks
   WHERE student_id = p_student_id AND exam_id = p_exam_id;
  IF v_count > 0 THEN
    RAISE e_duplicate_marks;
  END IF;

  INSERT INTO marks (student_id, exam_id, marks_obtained, remarks)
  VALUES (p_student_id, p_exam_id, p_marks_obtained, p_remarks)
  RETURNING marks_id INTO v_new_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Marks '||p_marks_obtained||'/'||v_max_marks||
                       ' entered for student '||p_student_id||' in exam '||p_exam_id||'.');

EXCEPTION
  WHEN e_exam_not_found THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Examination ID '||p_exam_id||' does not exist.');
  WHEN e_negative_marks THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Marks cannot be negative.');
  WHEN e_not_enrolled THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student '||p_student_id||
                                   ' is not enrolled in the course of examination '||p_exam_id||'.');
  WHEN e_duplicate_marks THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Marks for student '||p_student_id||
                                   ' in examination '||p_exam_id||' already exist.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END enter_student_marks;
/


/* ===========================================================================
   10. RECORD_FEE_PAYMENT
   Adds a payment to the student's fee account.
   - If the student already has a fee row, paid_amount is increased.
   - If not, a new fee row is created using p_total_fee (required in that case).
   The TRIGGER trg_fees_maintain (06) recalculates due_amount and
   payment_status automatically.
   =========================================================================== */
CREATE OR REPLACE PROCEDURE record_fee_payment (
  p_student_id     IN NUMBER,
  p_payment_amount IN NUMBER,
  p_payment_method IN VARCHAR2 DEFAULT 'CASH',
  p_total_fee      IN NUMBER   DEFAULT NULL
) IS
  v_count      NUMBER;
  v_fee_id     NUMBER;
  v_total      NUMBER;
  v_paid       NUMBER;
  e_student_not_found EXCEPTION;
  e_invalid_amount    EXCEPTION;
  e_no_fee_account    EXCEPTION;
  e_overpayment       EXCEPTION;
BEGIN
  SELECT COUNT(*) INTO v_count FROM students WHERE student_id = p_student_id;
  IF v_count = 0 THEN
    RAISE e_student_not_found;
  END IF;

  IF p_payment_amount IS NULL OR p_payment_amount <= 0 THEN
    RAISE e_invalid_amount;
  END IF;

  /* --- find the latest fee account of the student --- */
  BEGIN
    SELECT fee_id, total_fee, paid_amount
      INTO v_fee_id, v_total, v_paid
      FROM fees
     WHERE student_id = p_student_id
     ORDER BY fee_id DESC
     FETCH FIRST 1 ROW ONLY;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_fee_id := NULL;
  END;

  IF v_fee_id IS NULL THEN
    /* --- no account yet: one must be created --- */
    IF p_total_fee IS NULL THEN
      RAISE e_no_fee_account;
    END IF;
    IF p_payment_amount > p_total_fee THEN
      RAISE e_overpayment;
    END IF;

    INSERT INTO fees (student_id, total_fee, paid_amount, payment_date, payment_method)
    VALUES (p_student_id, p_total_fee, p_payment_amount, SYSDATE, UPPER(p_payment_method));
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Fee account created for student '||p_student_id||
                         ' with payment of '||p_payment_amount||'.');
  ELSE
    IF (v_paid + p_payment_amount) > v_total THEN
      RAISE e_overpayment;
    END IF;

    UPDATE fees
       SET paid_amount  = v_paid + p_payment_amount,
           payment_date = SYSDATE,
           payment_method = UPPER(p_payment_method)
     WHERE fee_id = v_fee_id;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Payment of '||p_payment_amount||
                         ' recorded for student '||p_student_id||'.');
  END IF;

  COMMIT;

EXCEPTION
  WHEN e_student_not_found THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student ID '||p_student_id||' not found.');
  WHEN e_invalid_amount THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Payment amount must be greater than zero.');
  WHEN e_no_fee_account THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Student '||p_student_id||
                                   ' has no fee account. Supply p_total_fee to create one.');
  WHEN e_overpayment THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: Payment exceeds the outstanding balance for student '||
                                   p_student_id||'.');
  WHEN OTHERS THEN
    ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
END record_fee_payment;
/

/* ============================================================================
   VERIFY - list all procedures that were created
   ============================================================================ */
SELECT object_name, status
  FROM user_objects
 WHERE object_type = 'PROCEDURE'
 ORDER BY object_name;

/* ============================================================================
   END OF 04_create_procedures.sql
   ============================================================================ */
