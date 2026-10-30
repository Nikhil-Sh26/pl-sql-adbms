# Project Report — Student Management System (SMS)

## Title page information

| Item | Detail |
|------|--------|
| **Project title** | Student Management System (SMS) |
| **Submitted for** | MCA practical / database laboratory |
| **Technology** | Oracle SQL and PL/SQL |
| **Environment** | Oracle FreeSQL (browser-based SQL worksheet). No local Oracle installation, no backend language. |
| **Database objects** | 9 tables, 9 sequences, 10 procedures, 5 functions, 12 triggers, 2 packages, 4 views, 14 reports, 30 test cases |
| **Status of scripts** | Written for Oracle; **not executed against a live Oracle database by the author**. The reader must run them in FreeSQL and report any errors. |

---

## Abstract

The Student Management System (SMS) is a database-centric academic project built entirely
with Oracle SQL and PL/SQL. It models the day-to-day academic records of a small college:
departments, students, courses, enrollments, attendance, examinations, marks and fees. All
business logic — validation, automatic calculation and auditing — is implemented **inside
the database** using stored procedures, functions, triggers and packages. The project
demonstrates the complete PL/SQL feature set required for an MCA practical (constraints,
sequences, procedures, functions, triggers, cursors, packages, views, exception handling and
transactions) in one consistent schema, and it produces fourteen reports for analysis.

---

## 1. Introduction

Managing student data manually is repetitive and error-prone. A relational database with
embedded PL/SQL logic keeps the data consistent and centralises the rules. This project
builds such a system using **only** Oracle SQL and PL/SQL. There is no application front
end; the user interacts with the database through a browser SQL worksheet, running scripts
and reading the results of SELECT queries. The emphasis is on correct database design and on
**enforcing every business rule in code**, not on building an interface.

---

## 2. Objectives

- Design a normalised schema for a student management system.
- Implement primary keys, foreign keys, unique, not-null and check constraints.
- Generate surrogate keys safely with sequences and BEFORE INSERT triggers.
- Encapsulate business operations in stored procedures.
- Provide reusable calculations through stored functions.
- Enforce complex, cross-table rules with triggers.
- Demonstrate all cursor types.
- Group related program units into packages.
- Create views and reporting queries for analysis.
- Handle exceptions gracefully and control transactions with COMMIT and ROLLBACK.
- Provide a thorough test suite of successful and failing scenarios.

---

## 3. System requirements

| Item | Requirement |
|------|-------------|
| Database | Oracle Database (any recent version) |
| Tool | Oracle FreeSQL browser worksheet (no local install needed) |
| Language | Oracle SQL + PL/SQL only |
| Not allowed | Other RDBMS (MySQL/PostgreSQL/SQLite) and backend languages (Python/Java/PHP/Node) |
| Output visibility | Enable the DBMS Output panel; every PL/SQL block is also paired with a SELECT because `SET SERVEROUTPUT ON` may not work in FreeSQL |

---

## 4. Database design summary

The schema has nine tables organised around a department → student/course core:

- **DEPARTMENTS** is the root; **STUDENTS** and **COURSES** each reference it.
- **ENROLLMENTS** resolves the many-to-many between STUDENTS and COURSES.
- **ATTENDANCE** references STUDENTS and COURSES.
- **EXAMINATIONS** references COURSES; **MARKS** references STUDENTS and EXAMINATIONS.
- **FEES** references STUDENTS.
- **AUDIT_LOG** records changes to STUDENTS.

Every table uses a `NUMBER` surrogate primary key fed by its own sequence through a BEFORE
INSERT trigger. Value rules use CHECK constraints; cross-table rules use triggers. Full
column details are in `database_schema.md`; relationships are in `er_diagram.md`.

---

## 5. Module descriptions

| Module | Description |
|--------|-------------|
| Department | CRUD of departments with unique code. |
| Student | Register/update/delete students with department, gender and status validation. |
| Course | Register courses with unique code, credits (1–10) and department. |
| Enrollment | Enroll students and block duplicate registrations. |
| Attendance | Record attendance and block attendance for non-enrolled students. |
| Examination & Marks | Create examinations and store marks with automatic grade/result. |
| Fee | Maintain fee accounts with automatic due amount and status. |
| Reporting | 14 reports and 4 views. |
| Audit | Automatic logging of STUDENTS changes. |

---

## 6. PL/SQL implementation summary

### Procedures — `04_create_procedures.sql` (10)

| Procedure | One-line description |
|-----------|----------------------|
| `ADD_STUDENT` | Validates department/gender/status and inserts a student; catches duplicate email. |
| `UPDATE_STUDENT` | Updates phone/address/department/status; NULL means "leave unchanged". |
| `DELETE_STUDENT` | Deletes a student only if no child records exist. |
| `ADD_DEPARTMENT` | Inserts a department; catches duplicate code. |
| `ADD_COURSE` | Validates department and credits, then inserts a course. |
| `ENROLL_STUDENT` | Enrols a student (must be ACTIVE, no duplicate) into a course. |
| `MARK_ATTENDANCE` | Records attendance for an enrolled student, once per date. |
| `ADD_EXAMINATION` | Inserts an examination after validating maximum/passing marks. |
| `ENTER_STUDENT_MARKS` | Enters marks for an enrolled student; trigger fills grade/result. |
| `RECORD_FEE_PAYMENT` | Adds a payment, creating a fee account the first time; blocks overpayment. |

### Functions — `05_create_functions.sql` (5)

| Function | One-line description |
|----------|----------------------|
| `GET_STUDENT_DETAILS` | Returns one readable line of student information (JOIN). |
| `CALCULATE_ATTENDANCE_PERCENTAGE` | Returns present / total × 100 for a student (optionally per course). |
| `CALCULATE_STUDENT_CGPA_OR_AVERAGE` | Returns average performance as a percentage across examinations. |
| `GET_STUDENT_FEE_BALANCE` | Returns the total amount still due from a student. |
| `GET_STUDENT_RESULT` | Returns 'PASS', 'FAIL', 'ABSENT' or 'NOT ENTERED' for one exam. |

### Triggers — `06_create_triggers.sql` (12)

| Trigger | Fires | One-line description |
|---------|-------|----------------------|
| `TRG_DEPARTMENTS_BI` | BEFORE INSERT on DEPARTMENTS | Fills DEPARTMENT_ID from `seq_department_id` when NULL. |
| `TRG_STUDENTS_BI` | BEFORE INSERT on STUDENTS | Fills STUDENT_ID from `seq_student_id` when NULL. |
| `TRG_COURSES_BI` | BEFORE INSERT on COURSES | Fills COURSE_ID from `seq_course_id` when NULL. |
| `TRG_ENROLLMENTS_BI` | BEFORE INSERT on ENROLLMENTS | Fills ENROLLMENT_ID from `seq_enrollment_id` when NULL. |
| `TRG_ATTENDANCE_BI` | BEFORE INSERT on ATTENDANCE | Fills ATTENDANCE_ID from `seq_attendance_id` when NULL. |
| `TRG_EXAMINATIONS_BI` | BEFORE INSERT on EXAMINATIONS | Fills EXAM_ID from `seq_exam_id` when NULL. |
| `TRG_MARKS_BI` | BEFORE INSERT on MARKS | Fills MARKS_ID from `seq_marks_id` when NULL. |
| `TRG_FEES_BI` | BEFORE INSERT on FEES | Fills FEE_ID from `seq_fee_id` when NULL. |
| `TRG_AUDIT_LOG_BI` | BEFORE INSERT on AUDIT_LOG | Fills LOG_ID from `seq_log_id` when NULL. |
| `TRG_STUDENTS_AUDIT` | AFTER INSERT/UPDATE/DELETE on STUDENTS | Writes one AUDIT_LOG row per change. |
| `TRG_MARKS_VALIDATE` | BEFORE INSERT or UPDATE on MARKS | Blocks marks above the maximum and computes grade and PASS/FAIL. |
| `TRG_FEES_MAINTAIN` | BEFORE INSERT or UPDATE on FEES | Recomputes DUE_AMOUNT and PAYMENT_STATUS; blocks overpayment. |

### Cursors — `07_create_cursors.sql` (3 demos)

| Demo | Style | One-line description |
|------|-------|----------------------|
| Demo 1 | Explicit cursor `c_students` | DECLARE / OPEN / FETCH / CLOSE loop over all students with department name. |
| Demo 2 | Parameterised cursor `c_dept_students` | Same cursor reused for any department id (here department 1). |
| Demo 3 | Cursor FOR loop | Processes all examination results; OPEN/FETCH/CLOSE handled by Oracle. |

### Packages — `08_create_packages.sql` (2)

| Package | Subprograms | One-line description |
|---------|-------------|----------------------|
| `STUDENT_MANAGEMENT_PKG` | `ADD_STUDENT_RECORD`, `UPDATE_STUDENT_RECORD`, `DELETE_STUDENT_RECORD`, `GET_STUDENT_INFORMATION` | Groups student operations; wraps the standalone procedures/functions from files 04/05. |
| `ACADEMIC_MANAGEMENT_PKG` | `ENROLL_STUDENT_IN_COURSE`, `RECORD_STUDENT_ATTENDANCE`, `ENTER_MARKS`, `GET_ATTENDANCE_PERCENTAGE`, `CALCULATE_ACADEMIC_PERFORMANCE` | Groups academic operations; wraps the standalone procedures/functions from files 04/05. |

> The wrappers use slightly different names (for example `add_student_record` instead of
> `add_student`) so that an unqualified call inside the package body does not resolve to the
> package's own subprogram and cause endless recursion.

### Views — `09_create_views.sql` (4)

| View | One-line description |
|------|----------------------|
| `STUDENT_DETAILS_VIEW` | One row per student with the department name resolved. |
| `STUDENT_ATTENDANCE_VIEW` | Attendance summary per student and course with percentage. |
| `STUDENT_RESULTS_VIEW` | One row per student per examination with marks, grade, result and percentage. |
| `STUDENT_FEES_VIEW` | One row per fee account with the student name. |

---

## 7. Business rules and where they are enforced

| # | Business rule | Where enforced | How |
|---|---------------|----------------|-----|
| 1 | A student/course must belong to a valid department | `ADD_STUDENT`, `UPDATE_STUDENT`, `ADD_COURSE`; schema | Procedure validation (`SELECT COUNT(*) FROM departments …` then `RAISE e_invalid_department`) + FK `fk_stu_dept` / `fk_course_dept` |
| 2 | No duplicate enrollment for the same student/course/year/semester | `ENROLL_STUDENT`; schema | Procedure check (`e_duplicate_enrollment`) + UNIQUE `uq_enrollment` |
| 3 | Attendance only for enrolled students | `MARK_ATTENDANCE` | Procedure checks ENROLLMENTS for a non-DROPPED row; raises `e_not_enrolled` otherwise |
| 4 | Marks cannot exceed the examination maximum | `TRG_MARKS_VALIDATE`; `ENTER_STUDENT_MARKS` | Trigger raises `RAISE_APPLICATION_ERROR(-20005)`; procedure also pre-checks and prints a friendly message |
| 5 | Automatic pass/fail | `TRG_MARKS_VALIDATE` | Compares MARKS_OBTAINED with PASSING_MARKS and sets RESULT_STATUS; also computes GRADE |
| 6 | Attendance percentage calculation | `CALCULATE_ATTENDANCE_PERCENTAGE`; `STUDENT_ATTENDANCE_VIEW` | Present ÷ total × 100 (Leave counts in the total) |
| 7 | Fee balance calculation | `GET_STUDENT_FEE_BALANCE`; `TRG_FEES_MAINTAIN` | Function sums DUE_AMOUNT; trigger recomputes DUE_AMOUNT = TOTAL_FEE − PAID_AMOUNT |
| 8 | An inactive student cannot enroll | `ENROLL_STUDENT` | Reads STUDENT_STATUS and raises `e_student_inactive` unless it is 'ACTIVE' |
| 9 | A valid examination is required before marks | `ENTER_STUDENT_MARKS`; schema | Procedure selects the exam (NO_DATA_FOUND → `e_exam_not_found`) + FK `fk_mark_exam` |
| 10 | Duplicate/invalid records are rejected | Schema | UNIQUE `uq_marks`, `uq_attendance`, `uq_stu_email`, `uq_course_code`, `uq_dept_code`, plus all CHECK constraints and the procedures' own duplicate checks |

---

## 8. Testing

`11_test_cases.sql` contains **30 test cases**. They are grouped into successful cases,
rejection (failing) cases, and exception demonstrations. Because DBMS_OUTPUT may not be
visible, each test is followed by a "VERIFY" SELECT.

### Section A — successful operations

| Test | Scenario | Expected result |
|------|----------|-----------------|
| 1 | Register a new student | SUCCESS, new student id (16) |
| 2 | Update that student | SUCCESS, phone and address changed |
| 3 | Enroll student 16 in course 1 | SUCCESS, new enrollment id (21) |
| 4 | Record attendance for student 16 | SUCCESS, one attendance row |
| 5 | Attendance percentage (function) | 100 for student 16; percentage for student 2 |
| 6 | Enter marks for student 16 | SUCCESS; trigger fills grade and result |
| 7 | Record fee payments | Account created, then updated to PAID |
| 8 | Check fee balance | Student 16 = 0; student 2 = 20000 |
| 9 | Details, average, results | One-line details, average %, PASS, NOT ENTERED |
| 21 | Delete a student with no child records | SUCCESS, the student is removed |
| 30 | Call the packages | Messages of the wrapped procedures/functions |

### Section B — failing operations (must be rejected)

| Test | Scenario | Expected result |
|------|----------|-----------------|
| 10 | Register with an existing email | ERROR, DUP_VAL_ON_INDEX |
| 11 | Register in a non-existent department | ERROR, custom exception |
| 12 | Duplicate enrollment | ERROR, custom exception |
| 13 | Enroll an INACTIVE student (id 12) | ERROR, inactive student |
| 14 | Attendance for a non-enrolled student | ERROR, not enrolled |
| 15 | Marks greater than the maximum | ERROR, marks exceed maximum |
| 16 | Direct INSERT of invalid marks (bypasses the procedure) | ORA-20005 from the trigger |
| 17 | Duplicate marks for the same exam | ERROR, custom exception |
| 18 | Pay more than the outstanding balance | ERROR / ORA-20006 |
| 19 | Fee payment for a non-existent student | ERROR, student not found |
| 20 | Delete a student who has related records | ERROR, cannot delete |

### Section C — invalid ids and exception demonstrations

| Test | Scenario | Expected result |
|------|----------|-----------------|
| 22 | Functions with an invalid student id | -1 for numeric functions; ERROR text for the string function |
| 23 | NO_DATA_FOUND | "NO_DATA_FOUND caught" |
| 24 | TOO_MANY_ROWS | "TOO_MANY_ROWS caught" |
| 25 | DUP_VAL_ON_INDEX | "DUP_VAL_ON_INDEX caught" |
| 26 | VALUE_ERROR | "VALUE_ERROR caught" |
| 27 | ZERO_DIVIDE | "ZERO_DIVIDE caught" |
| 28 | User-defined exception | "Custom exception caught" (attendance below 75 %) |
| 29 | WHEN OTHERS safety net | "Unexpected error caught" with SQLERRM and SQLCODE |

### Section D — final state

Re-runs the audit-log verification and the final row counts of every table, and (optionally)
the commented-out cleanup statements.

---

## 9. Reporting

### 14 reports (`10_reporting_queries.sql`)

| # | Report | Technique used |
|---|--------|----------------|
| 1 | All registered students | View SELECT |
| 2 | Students department-wise | JOIN |
| 3 | Students enrolled in a particular course | JOIN + filter |
| 4 | Semester-wise enrollment statistics | GROUP BY, COUNT DISTINCT |
| 5 | Student attendance percentage (overall) | JOIN, CASE, GROUP BY |
| 6 | Students with attendance below 75% | HAVING |
| 7 | Examination results | View SELECT |
| 8 | Top-performing students (top 5) | Analytic `RANK()` |
| 9 | Department-wise student count | LEFT JOIN, GROUP BY |
| 10 | Course-wise enrollment count | LEFT JOIN, GROUP BY |
| 11 | Students who failed an examination | View + filter |
| 12 | Students with pending fee balances | View + filter |
| 13 | Student academic performance (per student) | Subquery in SELECT list |
| 14 | Overall institution statistics | Scalar subqueries |

### 4 views

`STUDENT_DETAILS_VIEW`, `STUDENT_ATTENDANCE_VIEW`, `STUDENT_RESULTS_VIEW`,
`STUDENT_FEES_VIEW` (see Section 6).

---

## 10. Limitations and future enhancements

**Limitations**

- No front-end UI; interaction is through a SQL worksheet.
- No login/authentication or role-based access control.
- The scripts have not been executed against a live Oracle database by the author.
- A student id can appear in AUDIT_LOG without a foreign key (intentional, to keep history).

**Future enhancements**

- Add an application interface (web or desktop) in front of the same schema.
- Add role-based security and finer privileges.
- Add attendance percentage as a persisted, indexed column for very large data.
- Add a fee-instalment table to record each payment separately.
- Add more audit tables (or a generic audit framework) for other tables.
- Replace NOCACHE sequences with CACHE for a production load.

---

## 11. Viva questions and answers

1. **What is the difference between a procedure and a function?**
   A procedure performs an action and returns nothing (it can print messages or modify data).
   A function always returns a value and is normally called inside a SELECT or an expression.
   In this project `ADD_STUDENT` is a procedure; `CALCULATE_ATTENDANCE_PERCENTAGE` is a
   function.

2. **Why are triggers used in this project?**
   To run PL/SQL automatically when a table changes: to fill primary keys from sequences, to
   audit changes to STUDENTS, to validate marks against the examination maximum, and to keep
   the fee columns consistent.

3. **What is a package?**
   A package is a grouped set of related procedures and functions with two parts — a
   specification (public interface) and a body (implementation). This project has
   `STUDENT_MANAGEMENT_PKG` and `ACADEMIC_MANAGEMENT_PKG`.

4. **What is the difference between BEFORE/AFTER triggers and INSTEAD OF triggers?**
   BEFORE/AFTER triggers fire before or after a DML statement on a table. INSTEAD OF triggers
   are used on **views** (which are not directly DML-able) and run instead of the DML. This
   project uses only BEFORE/AFTER triggers.

5. **What is a cursor?**
   A cursor is a pointer to the result set of a query, letting PL/SQL process rows one by
   one. This project shows an explicit cursor, a parameterised cursor and a cursor FOR loop.

6. **What do COMMIT and ROLLBACK do?**
   COMMIT permanently saves the current transaction; ROLLBACK undoes it. Every DML block in
   this project commits on success and rolls back in its exception handler.

7. **What is a REF CURSOR?**
   A REF CURSOR is a pointer to a result set that can be opened for different queries at
   runtime and passed between program units. (This project does not use REF CURSOR; it uses
   explicit and implicit cursors.)

8. **What is the difference between a view and a table?**
   A table stores data physically. A view is a saved query that stores no data of its own; it
   behaves like a virtual table and runs its query each time it is queried.

9. **Why use sequences instead of `MAX(id)+1`?**
   Sequences are independent counters that avoid duplicates and locking, and they perform
   well under concurrency. `MAX(id)+1` can produce duplicates when two sessions insert at the
   same time.

10. **What does NO_DATA_FOUND mean?**
    It is raised when a SELECT ... INTO finds no rows. In this project
    `GET_STUDENT_RESULT` catches it and returns 'NOT ENTERED'.

11. **What is the WITH CHECK OPTION in a view?**
    It prevents an INSERT/UPDATE through a view from creating a row that the view's WHERE
    clause would not be able to see. (Not used here, because these views are read-only
    reports; it is a common viva follow-up.)

12. **What does `:NEW` and `:OLD` mean in a trigger?**
    `:NEW` holds the new value of a column being inserted/updated; `:OLD` holds the previous
    value. `TRG_STUDENTS_AUDIT` uses both to describe an update.

13. **What is `RAISE_APPLICATION_ERROR`?**
    A built-in procedure that raises a custom error with a number between -20000 and -20999.
    The marks trigger raises -20005 and the fees trigger raises -20006.

14. **What is the difference between an implicit and an explicit cursor?**
    Oracle automatically creates an implicit cursor for every DML statement (accessed through
    `SQL%ROWCOUNT`, `SQL%FOUND`). An explicit cursor is declared and controlled by the
    programmer with OPEN / FETCH / CLOSE.

15. **Why does the sample data use explicit ids, and what is done about it?**
    Explicit ids make the sample relationships easy to read. At the end of
    `03_insert_sample_data.sql` each sequence is restarted at `MAX(id)+1` so later inserts do
    not collide.

16. **What is the difference between a UNIQUE constraint and a PRIMARY KEY?**
    Both enforce uniqueness, but a primary key also implies NOT NULL and identifies the row;
    a UNIQUE constraint allows (in Oracle) multiple NULLs. `uq_stu_email` is unique;
    `pk_students` is the primary key.

17. **Why can't the "marks ≤ maximum marks" rule be a CHECK constraint?**
    A CHECK constraint cannot look up a value in another table. The maximum lives in
    EXAMINATIONS, so the rule is enforced by the `TRG_MARKS_VALIDATE` trigger.

18. **What is the difference between a scalar subquery and a correlated subquery?**
    A scalar subquery returns a single value and can stand alone (Report 14). A correlated
    subquery references a column from the outer query and runs once per outer row
    (Report 13).

---

## 12. Conclusion

The Student Management System demonstrates how a single Oracle schema, enriched with PL/SQL,
can hold and protect academic data. Constraints guard simple value rules, sequences and
triggers generate keys and enforce cross-table rules, procedures and functions encapsulate
the business operations, packages group the API, views and reports make the data easy to
analyse, and exception handling plus COMMIT/ROLLBACK keep operations safe. Because the
scripts were written for Oracle but **not executed against a live database by the author**,
the final step is to run them in Oracle FreeSQL in the documented order and verify each
result — which is itself a valuable part of the learning exercise.
