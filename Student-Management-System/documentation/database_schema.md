# Database Schema — Student Management System (SMS)

This document lists every table, column, data type and constraint exactly as defined in
`database/01_create_tables.sql`. All object names are written in UPPERCASE for readability,
although the scripts create them in lowercase.

There are **9 tables**: DEPARTMENTS, STUDENTS, COURSES, ENROLLMENTS, ATTENDANCE,
EXAMINATIONS, MARKS, FEES and AUDIT_LOG.

---

## 1. DEPARTMENTS

Master table of academic departments. It is the parent of STUDENTS and COURSES.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| DEPARTMENT_ID | NUMBER | PK `pk_departments` | Surrogate primary key (from `seq_department_id`). |
| DEPARTMENT_NAME | VARCHAR2(100) | NOT NULL `nn_dept_name` | Department name. |
| DEPARTMENT_CODE | VARCHAR2(10) | NOT NULL `nn_dept_code`, UNIQUE `uq_dept_code` | Short code such as CS, IT, COM, ECE. |
| DEPARTMENT_HEAD | VARCHAR2(100) | — | Name of the department head. |
| CREATED_AT | DATE | DEFAULT `SYSDATE`, NOT NULL `nn_dept_created` | Date the row was created. |

## 2. STUDENTS

Personal and academic information of a student. Belongs to a department.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| STUDENT_ID | NUMBER | PK `pk_students` | Surrogate primary key (from `seq_student_id`). |
| FIRST_NAME | VARCHAR2(50) | NOT NULL `nn_stu_fname` | First name. |
| LAST_NAME | VARCHAR2(50) | NOT NULL `nn_stu_lname` | Last name. |
| EMAIL | VARCHAR2(100) | NOT NULL `nn_stu_email`, UNIQUE `uq_stu_email` | Email; must be unique. |
| PHONE | VARCHAR2(15) | — | Contact number. |
| DATE_OF_BIRTH | DATE | NOT NULL `nn_stu_dob` | Date of birth. |
| GENDER | VARCHAR2(10) | CHECK `ck_stu_gender` IN ('Male','Female','Other') | Gender. |
| ADDRESS | VARCHAR2(200) | — | Postal address. |
| DEPARTMENT_ID | NUMBER | NOT NULL `nn_stu_dept`, FK `fk_stu_dept` → DEPARTMENTS(DEPARTMENT_ID) | Home department. |
| ADMISSION_DATE | DATE | DEFAULT `SYSDATE` | Date of admission. |
| STUDENT_STATUS | VARCHAR2(10) | DEFAULT 'ACTIVE', CHECK `ck_stu_status` IN ('ACTIVE','INACTIVE','GRADUATED') | Current status. |
| CREATED_AT | DATE | DEFAULT `SYSDATE`, NOT NULL `nn_stu_created` | Date the row was created. |

## 3. COURSES

Every course belongs to a department.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| COURSE_ID | NUMBER | PK `pk_courses` | Surrogate primary key (from `seq_course_id`). |
| COURSE_NAME | VARCHAR2(100) | NOT NULL `nn_course_name` | Course title. |
| COURSE_CODE | VARCHAR2(15) | NOT NULL `nn_course_code`, UNIQUE `uq_course_code` | Course code such as CS101. |
| CREDITS | NUMBER(2) | NOT NULL `nn_course_cr`, CHECK `ck_course_cr` BETWEEN 1 AND 10 | Credit weight. |
| DEPARTMENT_ID | NUMBER | NOT NULL `nn_course_dept`, FK `fk_course_dept` → DEPARTMENTS(DEPARTMENT_ID) | Owning department. |
| COURSE_DESCRIPTION | VARCHAR2(300) | — | Short description. |

## 4. ENROLLMENTS

Junction table that resolves the many-to-many relationship between STUDENTS and COURSES.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| ENROLLMENT_ID | NUMBER | PK `pk_enrollments` | Surrogate primary key (from `seq_enrollment_id`). |
| STUDENT_ID | NUMBER | NOT NULL `nn_enr_student`, FK `fk_enr_student` → STUDENTS(STUDENT_ID) | Enrolled student. |
| COURSE_ID | NUMBER | NOT NULL `nn_enr_course`, FK `fk_enr_course` → COURSES(COURSE_ID) | Course enrolled in. |
| ENROLLMENT_DATE | DATE | DEFAULT `SYSDATE` | Date of enrollment. |
| ACADEMIC_YEAR | VARCHAR2(10) | NOT NULL `nn_enr_year` | Academic year, e.g. '2024-2025'. |
| SEMESTER | NUMBER(1) | NOT NULL `nn_enr_sem`, CHECK `ck_enr_sem` BETWEEN 1 AND 8 | Semester number. |
| ENROLLMENT_STATUS | VARCHAR2(15) | DEFAULT 'ENROLLED', CHECK `ck_enr_status` IN ('ENROLLED','COMPLETED','DROPPED') | Status of the enrollment. |
| — | — | UNIQUE `uq_enrollment` (STUDENT_ID, COURSE_ID, ACADEMIC_YEAR, SEMESTER) | Prevents duplicate registration. |

## 5. ATTENDANCE

One row per student, course and date.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| ATTENDANCE_ID | NUMBER | PK `pk_attendance` | Surrogate primary key (from `seq_attendance_id`). |
| STUDENT_ID | NUMBER | NOT NULL `nn_att_student`, FK `fk_att_student` → STUDENTS(STUDENT_ID) | Student. |
| COURSE_ID | NUMBER | NOT NULL `nn_att_course`, FK `fk_att_course` → COURSES(COURSE_ID) | Course. |
| ATTENDANCE_DATE | DATE | NOT NULL `nn_att_date` | Date of the class. |
| ATTENDANCE_STATUS | VARCHAR2(10) | NOT NULL `nn_att_status`, CHECK `ck_att_status` IN ('Present','Absent','Leave') | Attendance value. |
| REMARKS | VARCHAR2(200) | — | Optional note (e.g. "Medical leave"). |
| — | — | UNIQUE `uq_attendance` (STUDENT_ID, COURSE_ID, ATTENDANCE_DATE) | One row per student/course/date. |

## 6. EXAMINATIONS

Examinations conducted for a course.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| EXAM_ID | NUMBER | PK `pk_examinations` | Surrogate primary key (from `seq_exam_id`). |
| COURSE_ID | NUMBER | NOT NULL `nn_exam_course`, FK `fk_exam_course` → COURSES(COURSE_ID) | Course examined. |
| EXAM_NAME | VARCHAR2(50) | NOT NULL `nn_exam_name` | Name of the examination. |
| EXAM_DATE | DATE | NOT NULL `nn_exam_date` | Date of the examination. |
| MAXIMUM_MARKS | NUMBER(5) | NOT NULL `nn_exam_max`, CHECK `ck_exam_max` > 0 | Maximum marks. |
| PASSING_MARKS | NUMBER(5) | NOT NULL `nn_exam_pass`, CHECK `ck_exam_pass` > 0 | Passing marks. |
| SEMESTER | NUMBER(1) | CHECK `ck_exam_sem` BETWEEN 1 AND 8 | Semester (nullable). |
| — | — | CHECK `ck_exam_pass_le_max` (PASSING_MARKS ≤ MAXIMUM_MARKS) | Passing marks cannot exceed maximum. |

## 7. MARKS

Result of one student in one examination.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| MARKS_ID | NUMBER | PK `pk_marks` | Surrogate primary key (from `seq_marks_id`). |
| STUDENT_ID | NUMBER | NOT NULL `nn_mark_student`, FK `fk_mark_student` → STUDENTS(STUDENT_ID) | Student. |
| EXAM_ID | NUMBER | NOT NULL `nn_mark_exam`, FK `fk_mark_exam` → EXAMINATIONS(EXAM_ID) | Examination. |
| MARKS_OBTAINED | NUMBER(5,2) | NOT NULL `nn_mark_obt`, CHECK `ck_mark_obt` ≥ 0 | Marks scored. |
| GRADE | VARCHAR2(2) | — | Letter grade, filled by the trigger. |
| RESULT_STATUS | VARCHAR2(10) | CHECK `ck_mark_result` IN ('PASS','FAIL','ABSENT') | Result, filled by the trigger. |
| REMARKS | VARCHAR2(200) | — | Optional note. |
| — | — | UNIQUE `uq_marks` (STUDENT_ID, EXAM_ID) | No duplicate marks for the same student + exam. |

> The rule "marks must not exceed the examination's maximum marks" cannot be a CHECK
> constraint because the maximum lives in another table — it is enforced by the trigger
> `trg_marks_validate` (`06_create_triggers.sql`).

## 8. FEES

Fee account of a student.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| FEE_ID | NUMBER | PK `pk_fees` | Surrogate primary key (from `seq_fee_id`). |
| STUDENT_ID | NUMBER | NOT NULL `nn_fee_student`, FK `fk_fee_student` → STUDENTS(STUDENT_ID) | Student. |
| TOTAL_FEE | NUMBER(10,2) | NOT NULL `nn_fee_total`, CHECK `ck_fee_total` ≥ 0 | Total fee for the student. |
| PAID_AMOUNT | NUMBER(10,2) | DEFAULT 0, NOT NULL `nn_fee_paid`, CHECK `ck_fee_paid` ≥ 0 | Amount paid so far. |
| DUE_AMOUNT | NUMBER(10,2) | NOT NULL `nn_fee_due`, CHECK `ck_fee_due` ≥ 0 | Outstanding amount (maintained by trigger). |
| PAYMENT_DATE | DATE | DEFAULT `SYSDATE` | Date of the last payment. |
| PAYMENT_STATUS | VARCHAR2(10) | DEFAULT 'PENDING', CHECK `ck_fee_status` IN ('PAID','PARTIAL','PENDING') | Status (maintained by trigger). |
| PAYMENT_METHOD | VARCHAR2(20) | CHECK `ck_fee_method` IN ('CASH','CARD','UPI','NETBANKING','CHEQUE') OR IS NULL | Method of payment. |
| — | — | CHECK `ck_fee_paid_le_total` (PAID_AMOUNT ≤ TOTAL_FEE) | Paid amount cannot exceed total fee. |

> `DUE_AMOUNT` and `PAYMENT_STATUS` are re-computed on every insert/update by the trigger
> `trg_fees_maintain` (`06_create_triggers.sql`), so they cannot drift out of sync.

## 9. AUDIT_LOG

History of every change made to STUDENTS, written automatically by `trg_students_audit`.

| Column | Data Type | Constraint | Description |
|--------|-----------|------------|-------------|
| LOG_ID | NUMBER | PK `pk_audit_log` | Surrogate primary key (from `seq_log_id`). |
| TABLE_NAME | VARCHAR2(30) | NOT NULL `nn_log_table` | Table that changed ('STUDENTS'). |
| OPERATION_TYPE | VARCHAR2(10) | NOT NULL `nn_log_op`, CHECK `ck_log_op` IN ('INSERT','UPDATE','DELETE') | Operation performed. |
| RECORD_ID | NUMBER | — | Primary key of the affected student. |
| OPERATION_DATE | DATE | DEFAULT `SYSDATE`, NOT NULL `nn_log_date` | When the change happened. |
| DESCRIPTION | VARCHAR2(400) | — | Human-readable description of the change. |

---

## Keys and constraints — what each one protects

### Primary keys

| Constraint | Table | Protects |
|------------|-------|----------|
| `pk_departments` | DEPARTMENTS | Unique department row. |
| `pk_students` | STUDENTS | Unique student row. |
| `pk_courses` | COURSES | Unique course row. |
| `pk_enrollments` | ENROLLMENTS | Unique enrollment row. |
| `pk_attendance` | ATTENDANCE | Unique attendance row. |
| `pk_examinations` | EXAMINATIONS | Unique examination row. |
| `pk_marks` | MARKS | Unique marks row. |
| `pk_fees` | FEES | Unique fee row. |
| `pk_audit_log` | AUDIT_LOG | Unique log row. |

### Foreign keys

| Constraint | Child → Parent | Protects |
|------------|----------------|----------|
| `fk_stu_dept` | STUDENTS.DEPARTMENT_ID → DEPARTMENTS | A student must belong to a real department. |
| `fk_course_dept` | COURSES.DEPARTMENT_ID → DEPARTMENTS | A course must belong to a real department. |
| `fk_enr_student` | ENROLLMENTS.STUDENT_ID → STUDENTS | You cannot enrol a non-existent student. |
| `fk_enr_course` | ENROLLMENTS.COURSE_ID → COURSES | You cannot enrol into a non-existent course. |
| `fk_att_student` | ATTENDANCE.STUDENT_ID → STUDENTS | Attendance must belong to a real student. |
| `fk_att_course` | ATTENDANCE.COURSE_ID → COURSES | Attendance must belong to a real course. |
| `fk_exam_course` | EXAMINATIONS.COURSE_ID → COURSES | An examination must belong to a real course. |
| `fk_mark_student` | MARKS.STUDENT_ID → STUDENTS | Marks must belong to a real student. |
| `fk_mark_exam` | MARKS.EXAM_ID → EXAMINATIONS | Marks must belong to a real examination. |
| `fk_fee_student` | FEES.STUDENT_ID → STUDENTS | A fee account must belong to a real student. |

### Unique constraints

| Constraint | Table | Protects |
|------------|-------|----------|
| `uq_dept_code` | DEPARTMENTS | No two departments share a code. |
| `uq_stu_email` | STUDENTS | No two students share an email. |
| `uq_course_code` | COURSES | No two courses share a code. |
| `uq_enrollment` | ENROLLMENTS (STUDENT_ID, COURSE_ID, ACADEMIC_YEAR, SEMESTER) | A student cannot register the same course twice in one year/semester. |
| `uq_attendance` | ATTENDANCE (STUDENT_ID, COURSE_ID, ATTENDANCE_DATE) | Only one attendance row per student/course/date. |
| `uq_marks` | MARKS (STUDENT_ID, EXAM_ID) | Only one result per student per examination. |

### Check constraints

| Constraint | Rule protected |
|------------|----------------|
| `ck_stu_gender` | Gender must be Male, Female or Other. |
| `ck_stu_status` | Status must be ACTIVE, INACTIVE or GRADUATED. |
| `ck_course_cr` | Credits between 1 and 10. |
| `ck_enr_sem` | Semester between 1 and 8. |
| `ck_enr_status` | Enrollment status must be ENROLLED, COMPLETED or DROPPED. |
| `ck_att_status` | Attendance status must be Present, Absent or Leave. |
| `ck_exam_max` | Maximum marks must be greater than 0. |
| `ck_exam_pass` | Passing marks must be greater than 0. |
| `ck_exam_sem` | Semester between 1 and 8. |
| `ck_exam_pass_le_max` | Passing marks cannot exceed maximum marks. |
| `ck_mark_obt` | Marks obtained must be zero or more. |
| `ck_mark_result` | Result must be PASS, FAIL or ABSENT. |
| `ck_fee_total`, `ck_fee_paid`, `ck_fee_due` | Fee amounts must be zero or more. |
| `ck_fee_status` | Status must be PAID, PARTIAL or PENDING. |
| `ck_fee_method` | Method must be CASH, CARD, UPI, NETBANKING, CHEQUE or NULL. |
| `ck_fee_paid_le_total` | Paid amount cannot exceed the total fee. |
| `ck_log_op` | Operation type must be INSERT, UPDATE or DELETE. |

---

## Sequence strategy

The project uses **9 sequences — one per table** — to generate the surrogate primary keys
(`02_create_sequences.sql`):

| Sequence | Feeds |
|----------|-------|
| `seq_department_id` | DEPARTMENTS.DEPARTMENT_ID |
| `seq_student_id` | STUDENTS.STUDENT_ID |
| `seq_course_id` | COURSES.COURSE_ID |
| `seq_enrollment_id` | ENROLLMENTS.ENROLLMENT_ID |
| `seq_attendance_id` | ATTENDANCE.ATTENDANCE_ID |
| `seq_exam_id` | EXAMINATIONS.EXAM_ID |
| `seq_marks_id` | MARKS.MARKS_ID |
| `seq_fee_id` | FEES.FEE_ID |
| `seq_log_id` | AUDIT_LOG.LOG_ID |

All are created as `START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE`. `NOCACHE` is used so the
numbers stay easy to follow while learning.

### How the BEFORE INSERT triggers use `.NEXTVAL`

Each table has a `BEFORE INSERT ... FOR EACH ROW` trigger
(`06_create_triggers.sql`, Group A) that runs:

```sql
IF :NEW.<id_column> IS NULL THEN
  :NEW.<id_column> := seq_<table>.NEXTVAL;
END IF;
```

So an INSERT can omit the id column entirely and the trigger fills it. If an explicit id is
supplied (as in the sample data), the trigger leaves it untouched.

### Why explicit IDs in the sample data, and how the sequences are re-synchronised

`03_insert_sample_data.sql` inserts **explicit IDs (1, 2, 3, …)** so that relationships are
easy to read (for example student 1 is enrolled in courses 1 and 2). But because these IDs
were not taken from the sequences, the sequences would still be at their starting value and
the next generated id could collide with an existing row.

To prevent that, the end of `03_insert_sample_data.sql` runs a small anonymous block that,
for every table, reads `MAX(id)` and restarts the matching sequence at `MAX(id)+1` using
`ALTER SEQUENCE ... RESTART START WITH <n>`. After this step, every later procedure call
continues from a safe number.

---

## Naming conventions used

| Prefix / pattern | Meaning | Examples |
|------------------|---------|----------|
| `pk_` | Primary key constraint | `pk_students`, `pk_marks` |
| `fk_` | Foreign key constraint | `fk_stu_dept`, `fk_mark_exam` |
| `nn_` | NOT NULL constraint | `nn_stu_email`, `nn_fee_total` |
| `uq_` | Unique constraint | `uq_stu_email`, `uq_enrollment` |
| `ck_` | Check constraint | `ck_stu_gender`, `ck_exam_pass_le_max` |
| `seq_` | Sequence | `seq_student_id` |
| `trg_` | Trigger | `trg_students_audit`, `trg_marks_validate` |
| `_view` suffix | View | `student_details_view` |
| `p_` | PL/SQL parameter | `p_student_id` |
| `v_` | PL/SQL local variable | `v_new_id` |
| `e_` | User-defined exception | `e_invalid_department` |
| `c_` | Explicit cursor | `c_students`, `c_dept_students` |
