# Student Management System (SMS)

A complete **Oracle SQL + PL/SQL** academic project (MCA practical) that manages the
core academic data of a small college: departments, students, courses, enrollments,
attendance, examinations, marks and fees. The project is written **only** in Oracle SQL
and PL/SQL and is meant to be run inside **Oracle FreeSQL** (Oracle's browser-based SQL
worksheet / Live SQL style environment). There is **no backend language** (no Python, Java,
PHP or Node) and **no application UI** — everything is demonstrated through SQL scripts
that create objects, load sample data, run procedures/functions, and print or SELECT
results.

---

## Project folder structure

```text
Student-Management-System/
├── README.md
├── documentation/
│   ├── project_overview.md
│   ├── database_schema.md
│   ├── er_diagram.md
│   └── project_report.md
└── database/
    ├── 01_create_tables.sql
    ├── 02_create_sequences.sql
    ├── 03_insert_sample_data.sql
    ├── 04_create_procedures.sql
    ├── 05_create_functions.sql
    ├── 06_create_triggers.sql
    ├── 07_create_cursors.sql
    ├── 08_create_packages.sql
    ├── 09_create_views.sql
    ├── 10_reporting_queries.sql
    └── 11_test_cases.sql
```

---

## Execution order (and why it matters)

Run the scripts in exactly this order. Each file depends on the objects created by the
files before it, so an out-of-order run will fail with "object does not exist" errors.

| Order | File | Why it must run here |
|-------|------|----------------------|
| 1 | `01_create_tables.sql` | Creates the 9 base tables. Nothing else can be created until the tables exist. |
| 2 | `02_create_sequences.sql` | Creates the 9 sequences the ID-generation triggers will use; sequences cannot exist without the project context. |
| 3 | `03_insert_sample_data.sql` | Loads data; it needs both the tables (01) and the sequences (02) because it re-synchronises the sequences at the end. |
| 4 | `04_create_procedures.sql` | Procedures INSERT/UPDATE/DELETE the tables, so the tables and sample data must already exist. |
| 5 | `05_create_functions.sql` | Functions query the tables (and are called from views/reports); they need the tables loaded first. |
| 6 | `06_create_triggers.sql` | Triggers rely on the sequences (02) for ID generation and on EXAMINATIONS for validation; they must run **before** the test cases that rely on them. |
| 7 | `07_create_cursors.sql` | The cursor demos read the sample data (03) and the data written by earlier steps. |
| 8 | `08_create_packages.sql` | The package bodies **call** the standalone procedures (04) and functions (05); those objects must already be valid. |
| 9 | `09_create_views.sql` | Views join the tables and reuse columns; they need the data model in place. |
| 10 | `10_reporting_queries.sql` | Reports SELECT from the views (09) and the stored functions (05); both must exist. |
| 11 | `11_test_cases.sql` | The test suite exercises procedures (04), functions (05), triggers (06) and packages (08) — everything must be created first. |

---

## How to run in Oracle FreeSQL

1. Open the FreeSQL worksheet in your browser and log in with the schema/user you want to
   use for the project.
2. Open `database/01_create_tables.sql`, **copy the statements and run them** in the
   worksheet. Run **one file at a time** — do not paste several files together.
3. For every PL/SQL block (procedures, functions, triggers, anonymous blocks), the block
   ends with a single **`/` on its own line**. Keep that `/` when you copy the code: it
   tells the worksheet that the block is finished. Without it the worksheet keeps waiting
   for more input.
4. After each file, read the **verification SELECT** that is provided at the bottom of the
   file (for example the row-count query in `03_insert_sample_data.sql`, or
   `SELECT object_name, status FROM user_objects` in `04`/`05`). Confirm every object is
   **VALID** before moving on.
5. Continue 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11.
6. In `11_test_cases.sql`, run the blocks **one at a time** and read the "VERIFY" SELECT
   after each block.

### How to enable DBMS_OUTPUT

Most procedures and cursor demos in this project print their messages with
`DBMS_OUTPUT.PUT_LINE`. `SET SERVEROUTPUT ON` is a **SQL\*Plus** command and **may not
work in FreeSQL** (or may be silently ignored). Therefore:

- Look for a **"DBMS Output"** panel, tab or toggle in the worksheet and switch it **on**
  before running the PL/SQL blocks. If you can also run `SET SERVEROUTPUT ON` and it is
  accepted, do so — but do not rely on it.
- **Project rule:** every PL/SQL block in this project is paired with a plain **SELECT
  verification query**. Even if DBMS_OUTPUT is unavailable, the SELECT shows exactly what
  happened inside the tables (the new row, the updated columns, the row counts). This is
  also the safest way to demonstrate the project during a viva.

---

## What the system can do (features)

- Register, update and safely delete students (with department, gender and status checks).
- Register departments and courses (with unique code enforcement).
- Enroll students into courses and prevent duplicate enrollments.
- Record daily attendance and block attendance for students who are not enrolled.
- Create examinations and validate maximum/passing marks.
- Enter marks with automatic **grade** and **PASS / FAIL** calculation.
- Maintain a fee account with automatic **due amount** and **payment status**.
- Automatically log every change to STUDENTS in an audit table.
- Produce 14 reports and use 4 reporting views for attendance, results and fees.

### Modules

Department, Student, Course, Enrollment, Attendance, Examination & Marks, Fee, Reporting
and Audit — see `documentation/project_overview.md` for what each module does.

---

## Learning objectives / PL/SQL concepts demonstrated

| Concept | Where it is demonstrated |
|---------|--------------------------|
| Tables, data types, DEFAULT values | `01_create_tables.sql` |
| Primary keys, foreign keys, UNIQUE, NOT NULL, CHECK constraints | `01_create_tables.sql` |
| Sequences for surrogate keys | `02_create_sequences.sql` |
| INSERT, COMMIT, explicit IDs, sequence re-sync | `03_insert_sample_data.sql` |
| Stored procedures, IN parameters, custom exceptions, exception handling, COMMIT/ROLLBACK, `RETURNING INTO` | `04_create_procedures.sql` |
| Stored functions, `RETURN`, NO_DATA_FOUND, ZERO_DIVIDE handling | `05_create_functions.sql` |
| Triggers (BEFORE INSERT, BEFORE INSERT OR UPDATE, AFTER INSERT OR UPDATE OR DELETE), `:NEW`/`:OLD`, `RAISE_APPLICATION_ERROR` | `06_create_triggers.sql` |
| Explicit cursors, parameterised cursors, cursor FOR loop, `%ROWTYPE`, `%NOTFOUND`, `%ROWCOUNT` | `07_create_cursors.sql` |
| Packages (specification + body), re-using standalone subprograms | `08_create_packages.sql` |
| Views (saved queries, JOINs, aggregation) | `09_create_views.sql` |
| Reporting: JOIN, LEFT JOIN, GROUP BY, HAVING, subqueries, CASE, aggregate and analytic (`RANK()`) functions | `10_reporting_queries.sql` |
| Transactions (COMMIT / ROLLBACK), exception demos (NO_DATA_FOUND, TOO_MANY_ROWS, DUP_VAL_ON_INDEX, VALUE_ERROR, ZERO_DIVIDE, WHEN OTHERS) and 30 test cases | `11_test_cases.sql` |

---

## IMPORTANT — these scripts are NOT verified against a live Oracle database

These files were written for Oracle, but the author of these files **did not execute them
against a live Oracle instance**. They are written carefully and consistently, but they
have **not** been run, so small syntax or environment issues may remain. You must run them
in **Oracle FreeSQL**, in the order above, and **report any errors you see**.

### Troubleshooting

| Error | Meaning | How to fix |
|-------|---------|------------|
| `ORA-00955: name is already used by an existing object` | The object (table/sequence/view/trigger) already exists. | You already ran that file. Either skip it or, to start fresh, `DROP` the object first (for tables: `DROP TABLE x CASCADE CONSTRAINTS;`). |
| `ORA-01430: column being added already exists in table` | You tried to add a column that is already there. | The table is already up to date — skip that statement. |
| `ORA-02275: such a referential constraint already exists in the table` | The foreign key/constraint already exists. | Skip that constraint, or drop the table and recreate it. |
| `ORA-04098: trigger '...' is invalid and failed re-validation` | A trigger references an object that does not exist yet (usually a sequence or table created by an earlier file). | Run the files in the correct order (02 before 06). Then re-run `06_create_triggers.sql`. |
| `PLS-00201: identifier 'X' must be declared` | A procedure/function/package called by the code does not exist yet. | Run the earlier file that creates `X` first (e.g. run `04`/`05` before `08`). |
| `ORA-00942: table or view does not exist` | An earlier script was not run. | Run the scripts from the beginning, in order. |
| `ORA-01400: cannot insert NULL` | A NOT NULL column was left empty. | Supply a value for the column, or let the BEFORE INSERT trigger fill the id. |

If an error appears, fix it, then continue with the **next** file rather than restarting
the whole project unless the object you need is broken.
