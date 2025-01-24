# Efficient queries with optional parameters in Oracle Database

## The Problem
Have you encountered the need to have a query that filters rows based on some user-supplied criteria, but some (or all) of the filtering parameters are optional?

For example, let’s suppose that I have a query that returns a list of employees that earn more than $10,000 and work in a specific department. The query would look something like this:

    SELECT employee_id, last_name, salary, department_id
    FROM employees
    WHERE salary > 10000
          AND department_id = :deptid;

Now, what should I do if I need to get the same list of employees that earn more than $10,000,  regardless of the department they work in?

Some people take the option of writing a query that will work in both situations, and one of the ways in which they do it, looks like this:

    SELECT employee_id, last_name, salary, department_id
    FROM employees
    WHERE salary > 10000
    AND (:deptid IS NULL
        OR department_id = :deptid);

This produces the desired result: If I provide a value for the :deptid variable, the query returns all employees who earn more than 10000 and work in the desired department, and if I don’t supply a value for the parameter, the condition about the department_id is ignored and all employees who earn more than 10000 are returned.

The problem with this approach is that if I have an index available on the department_id which could actually make the query retrieve the rows faster, the database will not use it, because it needs to create an execution plan that is generic and usable in both situations (when I supply a value for :deptid and when I don’t).

Another approach that some people follow to write a generic query looks like this:

    SELECT employee_id, last_name, salary, department_id
    FROM employees
    WHERE salary > 10000
          AND department_id = nvl (:deptid, department_id);

This option could be a little better because the query optimizer in some cases is able to create an execution plan that takes into account the two possibilities  (whether I provide a value for :deptid or not).

Unfortunately, as soon as you add more optional parameters, the possibility of the optimizer creating an efficient execution plan practically disappears.

## The Proposed Solution
So, what is the best way to handle these situations?

To help the optimizer create a plan that is optimal for each situation, we would need to write a query that is specific for each situation, and tell the database which one to execute depending on the presence of the parameters, but this quickly gets complicated when there are several optional parameters, because we would need to create different queries for all the different combinations of parameters present.

So, as you might be thinking at this point, if we want to have a query for each specific situation without having to write many different static queries, we need to use dynamic SQL.

In the hr package I present two of the possible ways to handle these situations: One of them uses the dbms_sql package, which helps us run dynamic statements that can have a variable number of bind variables, and the other one uses a “trick” to be able to have a fixed number of binds, and thus, allows us to use native dynamic SQL. Both of them are coded as pipelined table functions, to facilitate their use from SQL statements.

The query on which these functions are based is this one, in which a value for the :sal variable is expected to always be provided, but the :depid and :empid are optional. It queries the employees table, which you can find in the Oracle-supplied HR schema:

    SELECT *
    FROM employees
    WHERE salary > :sal
        AND department_id = :depid
        AND employee_id = :empid;

In this particular case, it might not make much sense wanting to execute the query for a specific department and a specific employee, because you would probably get an efficient response by providing the employee_id only, but this was used as an example of how you could handle situations like this in your real-world scenarios.

The code has comments that will hopefully help you to understand what it does and how it works.

Here are a few examples of how these functions would be used. Both can be used exactly in the same way, and you can, of course, use them in more complex queries to join other tables and use other features of the SQL language:

    --Queries by salary only
    SELECT *
    FROM hr.employees_fn (5000);
    
    --Queries by salary and department_id
    SELECT *
    FROM hr.employees_native_fn (5000, 50);
    
    --Queries by salary, department_id, and employee_id
    SELECT *
    FROM hr.employees_fn (5000, 50, 124);
    
    --Queries by salary and employee_id
    SELECT *
    FROM hr.employees_fn (5000, NULL, 123);
    
    --Queries by salary and employee_id (using named notation for the latter)
    SELECT *
    FROM hr.employees_native_fn (5000, p_employee_id => 120);    

