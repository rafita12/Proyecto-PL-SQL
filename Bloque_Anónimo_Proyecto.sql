SET SERVEROUTPUT ON

--Bloque an�nimo, en el que mediante un men� elegimos la opci�n sobre lo que nos queremos informar:
    --1. Primera funci�n.
    --2. Segunda funci�n.
    --3. Primera procedimiento.
    --4. Segundo procedimiento.
DECLARE

--Variable en la que damos el valor de la opci�n del men� que nos interesa.
v_menu NUMBER:=3;
--Variable de la funcion 1, en el que damos el valor del codigo cliente que queremos saber su promoci�n.
v_cod_cliente NUMBER:=1;
v_promocion VARCHAR2(99);

--Variable de la funcion 2, en el que damos el valor del codigo producto de que queremos saber si es necesario reponer.
v_cod_producto VARCHAR2(10):='FR-45';
v_reponer VARCHAR2(99);

--Variables del procedimiento 2, en las que hay que introducir el periodo de fecha del que nos vamos a informar.
    --Fecha inicio --> Fecha inicial del periodo de tiempo.
    --Fecha fin --> Fecha en la que termina el periodo de tiempo.
v_fecha_inicio DATE := '12/03/2006';
v_fecha_fin DATE := '18/09/2007';

BEGIN 

    CASE
        WHEN v_menu = 1 THEN
            v_promocion:=promocion_cliente(v_cod_cliente);
            DBMS_OUTPUT.PUT_LINE(v_promocion);
        WHEN v_menu = 2 THEN
            v_reponer:=cantidad_stock(v_cod_producto);
            DBMS_OUTPUT.PUT_LINE(v_reponer);
        WHEN v_menu = 3 THEN
            listadoclientes();
        WHEN v_menu = 4 THEN
            informacionFecha(v_fecha_inicio, v_fecha_fin);
        --Gesti�n de excepci�n si elegimos una opci�n del men� incorrecta.
        ELSE 
            RAISE_APPLICATION_ERROR(-20009,'ERROR[N�MERO DEL MEN� QUE NO REALIZA NIGUNA FUNCI�N]');
    END CASE;
    
    --Gesti�n de exepciones.
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ocurri� el error ' || SQLCODE ||' mensaje: ' || SQLERRM);

END;
/