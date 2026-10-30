/* ============================================================================
   FILE    : 01_create_tables.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Create all base tables and their constraints.
   ENV     : Oracle FreeSQL (browser SQL worksheet)
   RUN     : FIRST  (before sequences, data, procedures, functions ...)
   ============================================================================
   DESIGN NOTES
   1. Every table has a NUMBER surrogate primary key.
      IDs are produced by sequences (02_create_sequences.sql) through
      BEFORE INSERT triggers (06_create_triggers.sql).
   2. Parent tables are created before child tables so FOREIGN KEYs resolve.
   3. Simple value rules use CHECK constraints; rules that need logic
      (marks vs maximum marks, fee due amount) use triggers.
   ============================================================================ */

/* ---------------------------------------------------------------------------
   A. DEPARTMENTS - master table of academic departments
   --------------------------------------------------------------------------- */
CREATE TABLE departments (
  department_id    NUMBER         CONSTRAINT pk_departments PRIMARY KEY,
  department_name  VARCHAR2(100)  CONSTRAINT nn_dept_name    NOT NULL,
  department_code  VARCHAR2(10)   CONSTRAINT nn_dept_code    NOT NULL
                                  CONSTRAINT uq_dept_code    UNIQUE,
  department_head  VARCHAR2(100),
  created_at       DATE           DEFAULT SYSDATE CONSTRAINT nn_dept_created NOT NULL
);

/* ---------------------------------------------------------------------------
   B. STUDENTS - personal and academic information of a student
   department_id is a FOREIGN KEY  ->  a student must belong to a real dept.
   email is UNIQUE                 ->  no two students share an email.
   --------------------------------------------------------------------------- */
CREATE TABLE students (
  student_id      NUMBER         CONSTRAINT pk_students     PRIMARY KEY,
  first_name      VARCHAR2(50)   CONSTRAINT nn_stu_fname    NOT NULL,
  last_name       VARCHAR2(50)   CONSTRAINT nn_stu_lname    NOT NULL,
  email           VARCHAR2(100)  CONSTRAINT nn_stu_email    NOT NULL
                                 CONSTRAINT uq_stu_email    UNIQUE,
  phone           VARCHAR2(15),
  date_of_birth   DATE           CONSTRAINT nn_stu_dob      NOT NULL,
  gender          VARCHAR2(10)   CONSTRAINT ck_stu_gender   CHECK (gender IN ('Male','Female','Other')),
  address         VARCHAR2(200),
  department_id   NUMBER         CONSTRAINT nn_stu_dept     NOT NULL
                                 CONSTRAINT fk_stu_dept     REFERENCES departments(department_id),
  admission_date  DATE           DEFAULT SYSDATE,
  student_status  VARCHAR2(10)   DEFAULT 'ACTIVE'
                                 CONSTRAINT ck_stu_status   CHECK (student_status IN ('ACTIVE','INACTIVE','GRADUATED')),
  created_at      DATE           DEFAULT SYSDATE CONSTRAINT nn_stu_created NOT NULL
);

/* ---------------------------------------------------------------------------
   C. COURSES - every course belongs to a department
   --------------------------------------------------------------------------- */
CREATE TABLE courses (
  course_id          NUMBER        CONSTRAINT pk_courses      PRIMARY KEY,
  course_name        VARCHAR2(100) CONSTRAINT nn_course_name  NOT NULL,
  course_code        VARCHAR2(15)  CONSTRAINT nn_course_code  NOT NULL
                                   CONSTRAINT uq_course_code  UNIQUE,
  credits            NUMBER(2)     CONSTRAINT nn_course_cr    NOT NULL
                                   CONSTRAINT ck_course_cr    CHECK (credits BETWEEN 1 AND 10),
  department_id      NUMBER        CONSTRAINT nn_course_dept  NOT NULL
                                   CONSTRAINT fk_course_dept  REFERENCES departments(department_id),
  course_description VARCHAR2(300)
);

/* ---------------------------------------------------------------------------
   D. ENROLLMENTS - resolves the many-to-many between STUDENTS and COURSES.
   uq_enrollment prevents a student registering the same course twice in the
   same academic year and semester (business rule 2).
   --------------------------------------------------------------------------- */
CREATE TABLE enrollments (
  enrollment_id     NUMBER       CONSTRAINT pk_enrollments  PRIMARY KEY,
  student_id        NUMBER       CONSTRAINT nn_enr_student  NOT NULL
                                 CONSTRAINT fk_enr_student  REFERENCES students(student_id),
  course_id         NUMBER       CONSTRAINT nn_enr_course   NOT NULL
                                 CONSTRAINT fk_enr_course   REFERENCES courses(course_id),
  enrollment_date   DATE         DEFAULT SYSDATE,
  academic_year     VARCHAR2(10) CONSTRAINT nn_enr_year     NOT NULL,
  semester          NUMBER(1)    CONSTRAINT nn_enr_sem      NOT NULL
                                 CONSTRAINT ck_enr_sem      CHECK (semester BETWEEN 1 AND 8),
  enrollment_status VARCHAR2(15) DEFAULT 'ENROLLED'
                                 CONSTRAINT ck_enr_status   CHECK (enrollment_status IN ('ENROLLED','COMPLETED','DROPPED')),
  CONSTRAINT uq_enrollment UNIQUE (student_id, course_id, academic_year, semester)
);

/* ---------------------------------------------------------------------------
   E. ATTENDANCE - one row per student, course and date.
   attendance_status supports Present, Absent and Leave.
   --------------------------------------------------------------------------- */
CREATE TABLE attendance (
  attendance_id     NUMBER        CONSTRAINT pk_attendance   PRIMARY KEY,
  student_id        NUMBER        CONSTRAINT nn_att_student  NOT NULL
                                  CONSTRAINT fk_att_student  REFERENCES students(student_id),
  course_id         NUMBER        CONSTRAINT nn_att_course   NOT NULL
                                  CONSTRAINT fk_att_course   REFERENCES courses(course_id),
  attendance_date   DATE          CONSTRAINT nn_att_date     NOT NULL,
  attendance_status VARCHAR2(10)  CONSTRAINT nn_att_status   NOT NULL
                                  CONSTRAINT ck_att_status   CHECK (attendance_status IN ('Present','Absent','Leave')),
  remarks           VARCHAR2(200),
  CONSTRAINT uq_attendance UNIQUE (student_id, course_id, attendance_date)
);

/* ---------------------------------------------------------------------------
   F. EXAMINATIONS - examinations conducted for a course
   --------------------------------------------------------------------------- */
CREATE TABLE examinations (
  exam_id       NUMBER        CONSTRAINT pk_examinations PRIMARY KEY,
  course_id     NUMBER        CONSTRAINT nn_exam_course  NOT NULL
                              CONSTRAINT fk_exam_course  REFERENCES courses(course_id),
  exam_name     VARCHAR2(50)  CONSTRAINT nn_exam_name    NOT NULL,
  exam_date     DATE          CONSTRAINT nn_exam_date    NOT NULL,
  maximum_marks NUMBER(5)     CONSTRAINT nn_exam_max     NOT NULL
                              CONSTRAINT ck_exam_max     CHECK (maximum_marks > 0),
  passing_marks NUMBER(5)     CONSTRAINT nn_exam_pass    NOT NULL
                              CONSTRAINT ck_exam_pass    CHECK (passing_marks > 0),
  semester      NUMBER(1)     CONSTRAINT ck_exam_sem     CHECK (semester BETWEEN 1 AND 8),
  CONSTRAINT ck_exam_pass_le_max CHECK (passing_marks <= maximum_marks)
);

/* ---------------------------------------------------------------------------
   G. MARKS - result of one student in one examination.
   uq_marks prevents duplicate marks for the same student + exam.
   The "marks <= maximum_marks" rule needs a trigger (06) because it depends
   on another table (EXAMINATIONS).
   --------------------------------------------------------------------------- */
CREATE TABLE marks (
  marks_id       NUMBER       CONSTRAINT pk_marks        PRIMARY KEY,
  student_id     NUMBER       CONSTRAINT nn_mark_student NOT NULL
                              CONSTRAINT fk_mark_student REFERENCES students(student_id),
  exam_id        NUMBER       CONSTRAINT nn_mark_exam    NOT NULL
                              CONSTRAINT fk_mark_exam    REFERENCES examinations(exam_id),
  marks_obtained NUMBER(5,2)  CONSTRAINT nn_mark_obt     NOT NULL
                              CONSTRAINT ck_mark_obt     CHECK (marks_obtained >= 0),
  grade          VARCHAR2(2),
  result_status  VARCHAR2(10) CONSTRAINT ck_mark_result  CHECK (result_status IN ('PASS','FAIL','ABSENT')),
  remarks        VARCHAR2(200),
  CONSTRAINT uq_marks UNIQUE (student_id, exam_id)
);

/* ---------------------------------------------------------------------------
   H. FEES - fee account of a student.
   due_amount and payment_status are maintained by a trigger (06) so they can
   never go out of sync with total_fee and paid_amount.
   --------------------------------------------------------------------------- */
CREATE TABLE fees (
  fee_id         NUMBER        CONSTRAINT pk_fees        PRIMARY KEY,
  student_id     NUMBER        CONSTRAINT nn_fee_student NOT NULL
                               CONSTRAINT fk_fee_student REFERENCES students(student_id),
  total_fee      NUMBER(10,2)  CONSTRAINT nn_fee_total   NOT NULL
                               CONSTRAINT ck_fee_total   CHECK (total_fee >= 0),
  paid_amount    NUMBER(10,2)  DEFAULT 0 CONSTRAINT nn_fee_paid NOT NULL
                               CONSTRAINT ck_fee_paid    CHECK (paid_amount >= 0),
  due_amount     NUMBER(10,2)  CONSTRAINT nn_fee_due     NOT NULL
                               CONSTRAINT ck_fee_due     CHECK (due_amount >= 0),
  payment_date   DATE          DEFAULT SYSDATE,
  payment_status VARCHAR2(10)  DEFAULT 'PENDING'
                               CONSTRAINT ck_fee_status  CHECK (payment_status IN ('PAID','PARTIAL','PENDING')),
  payment_method VARCHAR2(20)  CONSTRAINT ck_fee_method  CHECK (payment_method IN ('CASH','CARD','UPI','NETBANKING','CHEQUE') OR payment_method IS NULL),
  CONSTRAINT ck_fee_paid_le_total CHECK (paid_amount <= total_fee)
);

/* ---------------------------------------------------------------------------
   I. AUDIT_LOG - history of every change made to STUDENTS.
   Written automatically by TRG_STUDENTS_AUDIT (06_create_triggers.sql).
   --------------------------------------------------------------------------- */
CREATE TABLE audit_log (
  log_id         NUMBER        CONSTRAINT pk_audit_log   PRIMARY KEY,
  table_name     VARCHAR2(30)  CONSTRAINT nn_log_table   NOT NULL,
  operation_type VARCHAR2(10)  CONSTRAINT nn_log_op      NOT NULL
                               CONSTRAINT ck_log_op      CHECK (operation_type IN ('INSERT','UPDATE','DELETE')),
  record_id      NUMBER,
  operation_date DATE          DEFAULT SYSDATE CONSTRAINT nn_log_date NOT NULL,
  description    VARCHAR2(400)
);

/* ============================================================================
   END OF 01_create_tables.sql
   ============================================================================ */
