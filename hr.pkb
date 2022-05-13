CREATE OR REPLACE PACKAGE BODY hr AS

FUNCTION employees_fn (
    p_salary        IN NUMBER
  , p_department_id IN NUMBER DEFAULT NULL
  , p_employee_id   IN NUMBER DEFAULT NULL
) RETURN employees_tab_t
    PIPELINED
IS
    l_query varchar2(500);
    l_cursor number;
    l_result number;
    l_cursor_rc  SYS_REFCURSOR;
    l_employees_tab employees_tab_t;
    l_max_fetch_size number := 1000;
BEGIN
    --Building the statement dynamically.
    l_query := 'SELECT * FROM employees WHERE salary > :sal';
    IF p_department_id IS NOT NULL THEN
        l_query := l_query || ' AND department_id = :depid';
    END IF;
    IF p_employee_id IS NOT NULL THEN
        l_query := l_query || ' AND employee_id = :empid';
    END IF;

    --Opening the cursor and parsing the query.
    l_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(l_cursor, l_query, dbms_sql.native);

    --Binding the necessary variables
    dbms_sql.bind_variable (l_cursor, 'sal', p_salary);
    IF p_department_id IS NOT NULL THEN
        dbms_sql.bind_variable (l_cursor, 'depid', p_department_id);
    END IF;
    IF p_employee_id IS NOT NULL THEN
        dbms_sql.bind_variable (l_cursor, 'empid', p_employee_id);
    END IF;

    --Executing the query and converting the cursor to a ref cursor for easier bulk fetch.
    l_result := dbms_sql.execute(l_cursor);
    l_cursor_rc := dbms_sql.to_refcursor(l_cursor);

    --Bulk fetching the data in blocks of l_max_fetch_size rows, and piping the rows from the collection.
    LOOP
            FETCH l_cursor_rc BULK COLLECT INTO l_employees_tab LIMIT l_max_fetch_size;
            FOR i IN 1 .. l_employees_tab.count LOOP
                PIPE ROW (l_employees_tab(i));
            END LOOP;
    EXIT WHEN l_employees_tab.count < l_max_fetch_size;
    END LOOP;
    
    --Closing the cursor.
    CLOSE l_cursor_rc;    
END employees_fn;

FUNCTION employees_native_fn (
    p_salary        IN NUMBER
  , p_department_id IN NUMBER DEFAULT NULL
  , p_employee_id   IN NUMBER DEFAULT NULL
) RETURN employees_tab_t
    PIPELINED
IS
    l_query varchar2(500);
    l_cursor_rc  SYS_REFCURSOR;
    l_employees_tab employees_tab_t;
    l_max_fetch_size number := 1000;
BEGIN
    --Building the statement dynamically, in a way that the set of bind variables is always the same.
    --When any of the optional parameters is null, a condition that the optimizer can later remove is added.
    l_query := 'SELECT * FROM employees WHERE salary > :sal';
    IF p_department_id IS NOT NULL THEN
        l_query := l_query || ' AND department_id = :depid';
    ELSE
        l_query := l_query || ' AND (1=1 OR :depid IS NULL)';
    END IF;
    IF p_employee_id IS NOT NULL THEN
        l_query := l_query || ' AND employee_id = :empid';
    ELSE
        l_query := l_query || ' AND (1=1 OR :empid IS NULL)';
    END IF;
    
    --Opening the cursor with a fixed set of bind variables.
    OPEN l_cursor_rc  for l_query  USING p_salary, p_department_id, p_employee_id;
    
    --Bulk fetching the data in blocks of l_max_fetch_size rows, and piping the rows from the collection.
    LOOP
            FETCH l_cursor_rc BULK COLLECT INTO l_employees_tab LIMIT l_max_fetch_size;
            FOR i IN 1 .. l_employees_tab.count LOOP
                PIPE ROW (l_employees_tab(i));
            END LOOP;
    EXIT WHEN l_employees_tab.count < l_max_fetch_size;
    END LOOP;
    
    --Closing the cursor.
    CLOSE l_cursor_rc;    
    
END employees_native_fn;

END hr;
/


