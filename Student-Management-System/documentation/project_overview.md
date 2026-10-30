# Project Overview — Student Management System (SMS)

## Purpose and scope

The **Student Management System (SMS)** is an academic database project for an MCA
practical. Its purpose is to show how a single Oracle database can store and manage the
core academic information of a small college and how **PL/SQL** can enforce business rules
and produce reports over that data.

**In scope:**

- Master data: departments, students, courses.
- Academic activity: enrollments, attendance, examinations, marks.
- Finance: student fee accounts and payments.
- Reporting: 14 SQL reports and 4 reusable views.
- Auditing: automatic logging of all changes to the STUDENTS table.

**Out of scope:** any user interface, web/mobile application, login system, or backend
code. The project is 100% SQL and PL/SQL, run manually in a browser SQL worksheet.

## Technology stack and environment constraints

| Item | Choice / Constraint |
|------|---------------------|
| Database | **Oracle Database** (any recent version; designed for Oracle FreeSQL in the browser) |
| Language | **Oracle SQL and PL/SQL only** |
| Not allowed | MySQL, PostgreSQL, SQLite or any other RDBMS |
| Not allowed | Python, Java, PHP, Node.js or any backend/hosted language |
| Not required | No local Oracle installation is needed — everything runs in the browser worksheet |
| Avoid | SQL\*Plus-only commands. `SET SERVEROUTPUT ON` may not work in FreeSQL — the project pairs every PL/SQL block with a plain SELECT so results are visible without it |

## Functional modules

| # | Module | What it does |
|---|--------|--------------|
| 1 | **Department** | Stores departments (`DEPARTMENTS`) with a unique code and head. Other modules reference a department. |
| 2 | **Student** | Registers students (`STUDENTS`) with personal details, contact info, department and status. |
| 3 | **Course** | Stores courses (`COURSES`) with a unique code, credits and owning department. |
| 4 | **Enrollment** | Links students to courses (`ENROLLMENTS`) and prevents duplicate registrations. |
| 5 | **Attendance** | Records one attendance row per student, course and date (`ATTENDANCE`); supports Present / Absent / Leave. |
| 6 | **Examination & Marks** | Defines examinations (`EXAMINATIONS`) and stores a student's result (`MARKS`) with automatic grade and pass/fail. |
| 7 | **Fee** | Maintains a student's fee account (`FEES`) with automatic due amount and payment status. |
| 8 | **Reporting** | 14 read-only reports and 4 views for students, attendance, results and fees. |
| 9 | **Audit** | `AUDIT_LOG` captures every INSERT/UPDATE/DELETE made to STUDENTS through a trigger. |

## Why PL/SQL is used

Plain SQL can store and fetch data, but it cannot easily express *multi-step rules* and
*automatic actions*. PL/SQL adds that layer:

- **Multi-step atomic operations** — registering a student means validating the department,
  validating the allowed values, inserting a row and handling a duplicate email; all in one
  block that commits or rolls back as a unit.
- **Reusable business rules** — the same validation (for example "the student must be
  ACTIVE to enrol") is written once in a procedure and reused everywhere.
- **Constraints that need logic** — a CHECK constraint cannot compare a value in one table
  with a value in another. PL/SQL triggers can (e.g. marks must not exceed the maximum
  marks of the examination).
- **Clean error reporting** — user-defined exceptions turn raw Oracle errors into friendly
  messages such as "Department ID 999 does not exist".
- **Packaging** — related procedures and functions are bundled into packages so callers use
  one name.
- **Reporting over many rows** — cursors and functions let us process and summarise large
  sets of rows consistently.

## Data flow / lifecycle

The data follows a strict parent-to-child dependency order, which is also the order in
which the tables must be created and loaded:

```text
DEPARTMENTS
   │
   ├──► STUDENTS ──────────┐
   │                       │
   └──► COURSES ───────────┼──► ENROLLMENTS
                           │            │
                           │            ├──► ATTENDANCE   (student + course + date)
                           │            │
                           └──► EXAMINATIONS ──► MARKS   (student + examination)
                                        │
   STUDENTS ────────────────────────────┴──► FEES         (one fee account per student)

   STUDENTS (changes) ──► AUDIT_LOG (written by trigger)
```

Narrative:

1. **Departments** are created first — they are the root of the hierarchy.
2. **Students** and **Courses** both belong to a department, so they come next.
3. **Enrollments** connect a student to a course (many-to-many). A student must be enrolled
   before attendance or marks can be recorded.
4. **Attendance** is recorded per student, per course, per date; the student must already
   be enrolled in that course.
5. **Examinations** belong to a course; **Marks** connect a student to an examination and
   require the student to be enrolled in the course of that examination.
6. **Fees** are a per-student finance record.
7. **Reports** read all of the above through views and functions.
8. Any change to **Students** is automatically written to **Audit Log**.

## Architecture

```text
+---------------------------------------------------------------+
|                    Oracle FreeSQL (browser)                   |
|                                                               |
|   PRESENTATION / ACCESS LAYER                                 |
|   - SQL worksheet: run scripts, read SELECT results           |
|                                                               |
|   REPORTING LAYER                                             |
|   - 4 VIEWS  (student_details_view, student_attendance_view,  |
|               student_results_view, student_fees_view)        |
|   - 14 reporting queries (JOIN, GROUP BY, HAVING, subquery,   |
|     CASE, RANK)                                               |
|                                                               |
|   PL/SQL PROGRAM UNIT LAYER                                   |
|   - 10 PROCEDURES  (add/update/delete student, add dept/course|
|                     enroll, attendance, exam, marks, fee)     |
|   - 5  FUNCTIONS   (details, attendance %, average, balance,  |
|                     result)                                   |
|   - 12 TRIGGERS    (9 id generators, audit, marks validate,   |
|                     fees maintain)                            |
|   - 3  CURSOR DEMOS (explicit, parameterised, FOR loop)       |
|   - 2  PACKAGES    (student_management_pkg,                   |
|                     academic_management_pkg)                  |
|                                                               |
|   TRANSACTION CONTROL                                         |
|   - COMMIT on success, ROLLBACK on failure in every DML block |
|                                                               |
|   DATA LAYER                                                  |
|   - 9 TABLES: departments, students, courses, enrollments,    |
|     attendance, examinations, marks, fees, audit_log          |
|   - 9 SEQUENCES feeding the BEFORE INSERT id triggers         |
+---------------------------------------------------------------+
```
