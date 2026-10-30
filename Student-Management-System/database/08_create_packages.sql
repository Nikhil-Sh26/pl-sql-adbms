/* ============================================================================
   FILE    : 08_create_packages.sql
   PROJECT : Student Management System (SMS)
   PURPOSE : Create the two PL/SQL packages (specification + body each).
   ENV     : Oracle FreeSQL
   RUN     : EIGHTH (after 01-07)
   ============================================================================
   WHAT A PACKAGE IS
   A package groups related procedures and functions under one name.
   It has two parts:
     - SPECIFICATION : the public interface (what the caller can use)
     - BODY          : the implementation (the code behind it)
   Benefits: one name to remember, shared private code, better performance
   (the whole package is loaded once), and easy maintenance.

   IMPORTANT DESIGN NOTE (name resolution - a useful viva point)
   The package bodies REUSE the standalone procedures and functions created in
   04 and 05 instead of duplicating the logic. The wrapper names are slightly
   different (for example add_student_record instead of add_student) because
   inside a package body an unqualified name that is identical to a package
   subprogram would refer to the package itself - which would cause endless
   recursion. Using distinct names keeps the code unambiguous and re-usable.
   ============================================================================ */


/* ===========================================================================
   PACKAGE 1 - STUDENT_MANAGEMENT_PKG
   SPECIFICATION (the public interface)
   =========================================================================== */
CREATE OR REPLACE PACKAGE student_management_pkg AS

  /* Add a student (wraps ADD_STUDENT from 04_create_procedures.sql) */
  PROCEDURE add_student_record (
    p_first_name    IN VARCHAR2,
    p_last_name     IN VARCHAR2,
    p_email         IN VARCHAR2,
    p_phone         IN VARCHAR2 DEFAULT NULL,
    p_date_of_birth IN DATE,
    p_gender        IN VARCHAR2,
    p_address       IN VARCHAR2 DEFAULT NULL,
    p_department_id IN NUMBER,
    p_status        IN VARCHAR2 DEFAULT 'ACTIVE'
  );

  /* Update a student (wraps UPDATE_STUDENT) */
  PROCEDURE update_student_record (
    p_student_id    IN NUMBER,
    p_phone         IN VARCHAR2 DEFAULT NULL,
    p_address       IN VARCHAR2 DEFAULT NULL,
    p_department_id IN NUMBER   DEFAULT NULL,
    p_status        IN VARCHAR2 DEFAULT NULL
  );

  /* Delete a student (wraps DELETE_STUDENT) */
  PROCEDURE delete_student_record (
    p_student_id IN NUMBER
  );

  /* Get one readable line of student information (wraps GET_STUDENT_DETAILS) */
  FUNCTION get_student_information (
    p_student_id IN NUMBER
  ) RETURN VARCHAR2;

END student_management_pkg;
/

/* PACKAGE 1 - BODY (the implementation) */
CREATE OR REPLACE PACKAGE BODY student_management_pkg AS

  PROCEDURE add_student_record (
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
  BEGIN
    add_student(p_first_name, p_last_name, p_email, p_phone,
                p_date_of_birth, p_gender, p_address, p_department_id, p_status);
  END add_student_record;

  PROCEDURE update_student_record (
    p_student_id    IN NUMBER,
    p_phone         IN VARCHAR2 DEFAULT NULL,
    p_address       IN VARCHAR2 DEFAULT NULL,
    p_department_id IN NUMBER   DEFAULT NULL,
    p_status        IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    update_student(p_student_id, p_phone, p_address, p_department_id, p_status);
  END update_student_record;

  PROCEDURE delete_student_record (
    p_student_id IN NUMBER
  ) IS
  BEGIN
    delete_student(p_student_id);
  END delete_student_record;

  FUNCTION get_student_information (
    p_student_id IN NUMBER
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN get_student_details(p_student_id);
  END get_student_information;

END student_management_pkg;
/


/* ===========================================================================
   PACKAGE 2 - ACADEMIC_MANAGEMENT_PKG
   SPECIFICATION
   =========================================================================== */
CREATE OR REPLACE PACKAGE academic_management_pkg AS

  /* Enroll a student in a course (wraps ENROLL_STUDENT) */
  PROCEDURE enroll_student_in_course (
    p_student_id    IN NUMBER,
    p_course_id     IN NUMBER,
    p_academic_year IN VARCHAR2,
    p_semester      IN NUMBER
  );

  /* Record one attendance row (wraps MARK_ATTENDANCE) */
  PROCEDURE record_student_attendance (
    p_student_id        IN NUMBER,
    p_course_id         IN NUMBER,
    p_attendance_date   IN DATE,
    p_attendance_status IN VARCHAR2,
    p_remarks           IN VARCHAR2 DEFAULT NULL
  );

  /* Enter marks for an examination (wraps ENTER_STUDENT_MARKS) */
  PROCEDURE enter_marks (
    p_student_id     IN NUMBER,
    p_exam_id        IN NUMBER,
    p_marks_obtained IN NUMBER,
    p_remarks        IN VARCHAR2 DEFAULT NULL
  );

  /* Attendance percentage (wraps CALCULATE_ATTENDANCE_PERCENTAGE) */
  FUNCTION get_attendance_percentage (
    p_student_id IN NUMBER,
    p_course_id  IN NUMBER DEFAULT NULL
  ) RETURN NUMBER;

  /* Overall academic performance in percent
     (wraps CALCULATE_STUDENT_CGPA_OR_AVERAGE) */
  FUNCTION calculate_academic_performance (
    p_student_id IN NUMBER
  ) RETURN NUMBER;

END academic_management_pkg;
/

/* PACKAGE 2 - BODY */
CREATE OR REPLACE PACKAGE BODY academic_management_pkg AS

  PROCEDURE enroll_student_in_course (
    p_student_id    IN NUMBER,
    p_course_id     IN NUMBER,
    p_academic_year IN VARCHAR2,
    p_semester      IN NUMBER
  ) IS
  BEGIN
    enroll_student(p_student_id, p_course_id, p_academic_year, p_semester);
  END enroll_student_in_course;

  PROCEDURE record_student_attendance (
    p_student_id        IN NUMBER,
    p_course_id         IN NUMBER,
    p_attendance_date   IN DATE,
    p_attendance_status IN VARCHAR2,
    p_remarks           IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    mark_attendance(p_student_id, p_course_id, p_attendance_date,
                    p_attendance_status, p_remarks);
  END record_student_attendance;

  PROCEDURE enter_marks (
    p_student_id     IN NUMBER,
    p_exam_id        IN NUMBER,
    p_marks_obtained IN NUMBER,
    p_remarks        IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    enter_student_marks(p_student_id, p_exam_id, p_marks_obtained, p_remarks);
  END enter_marks;

  FUNCTION get_attendance_percentage (
    p_student_id IN NUMBER,
    p_course_id  IN NUMBER DEFAULT NULL
  ) RETURN NUMBER IS
  BEGIN
    RETURN calculate_attendance_percentage(p_student_id, p_course_id);
  END get_attendance_percentage;

  FUNCTION calculate_academic_performance (
    p_student_id IN NUMBER
  ) RETURN NUMBER IS
  BEGIN
    RETURN calculate_student_cgpa_or_average(p_student_id);
  END calculate_academic_performance;

END academic_management_pkg;
/

/* ============================================================================
   VERIFY - a package and its body must both be VALID
   ============================================================================ */
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN ('STUDENT_MANAGEMENT_PKG','ACADEMIC_MANAGEMENT_PKG')
 ORDER BY object_name, object_type;

/* ============================================================================
   END OF 08_create_packages.sql
   ============================================================================ */
