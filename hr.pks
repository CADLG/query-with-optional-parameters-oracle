CREATE OR REPLACE PACKAGE hr AS

--The collection type that will be used for bulk fetching and returning the data
    TYPE employees_tab_t IS
        TABLE OF employees%rowtype;

--The function that uses DBMS_SQL
    FUNCTION employees_fn (
        p_salary        IN NUMBER
      , p_department_id IN NUMBER DEFAULT NULL
      , p_employee_id   IN NUMBER DEFAULT NULL
    ) RETURN employees_tab_t
        PIPELINED; 

--The function that uses native dynamic SQL
    FUNCTION employees_native_fn (
        p_salary        IN NUMBER
      , p_department_id IN NUMBER DEFAULT NULL
      , p_employee_id   IN NUMBER DEFAULT NULL
    ) RETURN employees_tab_t
        PIPELINED;

END hr;
/
