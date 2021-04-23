SET SERVEROUTPUT ON

--Primera Función:
--Esta función devuelve un mensaje con la promoción que le corresponde a cada cliente según la cantidad total de dinero gastado en los
--pagos que haya realizado.

CREATE OR REPLACE FUNCTION Promocion_Cliente(v_cod_cliente NUMBER)
    RETURN VARCHAR2 IS
    --Variable que guarda la cantidad total de los pagos del cliente.
    v_pago NUMBER;
    --Variable en la que guardamos la promoción que le corresponde a dicho cliente.
    v_promociones VARCHAR2(99);

BEGIN
    --Cursor encargado de dar a la varible v_pago la cantidad de pagos que haya realizado el cliente introducido por parámetros.
    SELECT SUM(total) INTO v_pago
        FROM pago
        WHERE codigo_cliente=v_cod_cliente
        GROUP BY codigo_cliente;

    --Case que da el valor a la promoción según los pagos del cliente.
    CASE
        WHEN v_pago > 70000 THEN
            v_promociones:='Descuento del 40% en la compra de un televisor de 55 pulgadas';
        WHEN (v_pago BETWEEN 50000 AND 69999) THEN
            v_promociones:='Descuento del 20% en la compra de un Samsung Galaxy S20';
        WHEN (v_pago BETWEEN 20000 AND 49999) THEN
            v_promociones:='Descuento del 10% en la compra de una PS5';
        WHEN (v_pago BETWEEN 10000 AND 19999) THEN
            v_promociones:='Descuento del 5% en la compra de una PS5';
        WHEN (v_pago BETWEEN 5000 AND 10000) THEN
            v_promociones:='Descuento del 10% en la compra de un Samsung Galaxy S10';
        WHEN (v_pago BETWEEN 1000 AND 4999) THEN
            v_promociones:='Descuento del 5% en la compra de cualquier producto de nuestra Página Web';
        ELSE 
            --Gestión de la exepción si el cliente no supera un mínimo de pagos.
            RAISE_APPLICATION_ERROR(-20007,'ERROR[EL CLIENTE NO SUPERA EL MÍNIMO DE PAGOS]');
    END CASE;
    
    --No he añadido gestión de exepciones ya que al ponerlo me saltaba una exepción como que la función no devuelve valor; pero, la 
    --función si devuelve valor y al quitar la gestión de exepciones fuciona correctamente.
    
RETURN v_promociones;
END;
/

/*----------------------------------------------------------------------------------------------------------------*/

--Segunda Función
--Esta función se encarga de devolver una cadena indicando si es necesario reponer la cantidad en stock del producto
--pasado por parámetros.
CREATE OR REPLACE FUNCTION cantidad_stock(v_cod_producto VARCHAR2)
    RETURN VARCHAR2 IS
    
    --Variable que guarda la cantidad total de stock del producto pasado por parámetros.
    v_stock NUMBER(4);
    --Variable que guarda la cadena que nos indica si el producto pasado por parámetros debe reponerse.
    v_reponer VARCHAR2(99);

BEGIN
    --Cursor encargado de dar a la varible v_stock la cantidad de stock que tiene el producto introducido por parámetros.
    SELECT cantidad_en_stock INTO v_stock
        FROM producto
        WHERE codigo_producto=v_cod_producto;

    --Condición en la que damos valor a la variable v_reponer:
        --Si hay menos de 50 productos en stock --> hay que reponer.
        --Si no es así y hay más de 50 productos --> no es necesario reponer.
    IF v_stock <= 50 THEN
        v_reponer := 'El stock del producto ' || v_cod_producto || ' es de ' || v_stock ||' por lo tanto es necesario reponer.';
    ELSE 
        v_reponer := 'El stock del producto ' || v_cod_producto || ' es de ' || v_stock ||' por lo tanto no es necesario reponer.';
    END IF;

    --No he añadido gestión de exepciones, ya que, al ponerlo me saltaba una exepción como que la función no devuelve valor; pero, la 
    --función si devuelve valor y al quitar la gestión de exepciones fuciona correctamente.
RETURN v_reponer;
END;
/

/*----------------------------------------------------------------------------------------------------------------*/

--Primer procedimiento:
--Procedimiento que se va a encargar de mostrarnos información de todos los clientes que hayan realizado algún pedido. Además, de los pedidos realizados y los gastos 
--en cada undo de ellos. Por último, nos muestra información de la cantidad total de clientes con pedidos, el total de pedidos y el total de gastos en todos los pedidos.
CREATE OR REPLACE PROCEDURE listadoClientes IS

    --Cursor para obtener los clientes que han realizado pedidos y el numero de pedidos que han realizado
    CURSOR c_clientes IS
        SELECT c.codigo_cliente, c.nombre_cliente, c.nombre_contacto, c.apellido_contacto, c.telefono, c.linea_direccion1, c.ciudad, c.pais, c.codigo_postal, COUNT(p.codigo_pedido) AS "NUMERO_PEDIDOS"
        FROM cliente c, pedido p
        WHERE c.codigo_cliente=p.codigo_cliente
        GROUP BY c.codigo_cliente, c.nombre_cliente, c.nombre_contacto, c.apellido_contacto, c.telefono, c.linea_direccion1, c.ciudad, c.pais, c.codigo_postal
        ORDER BY  c.codigo_cliente;
        
    r_cliente c_clientes%ROWTYPE;
    
    --Variable que va sumando todos los pedidos realizados
    v_num_pedidos NUMBER := 0;
    
    --Variable que va sumando los clientes
    v_num_clientes NUMBER := 0;
    
    --Cursor que recoge la información del pedido del cliente que pasemos por parámetros.
     CURSOR c_pedido (v_cod_cliente NUMBER)  IS
        SELECT *
            FROM pedido 
            WHERE codigo_cliente=v_cod_cliente;
    
     r_pedido c_pedido%ROWTYPE;
     
     --Cursor que recoge la información del codigo de pedido, cantidad de productos y el precio del pedido que pasemos por parámetros.
     CURSOR c_detalle_pedido (v_cod_pedido NUMBER)  IS
        SELECT dp.codigo_pedido, SUM (dp.cantidad) AS "CANTIDAD_PRODUCTO", SUM(dp.cantidad*dp.precio_unidad) AS "PRECIO_TOTAL"
    FROM detalle_pedido dp, producto pr
    WHERE dp.codigo_pedido=v_cod_pedido
    AND dp.codigo_producto=pr.codigo_producto
    GROUP BY dp.codigo_pedido;
    
     r_detalle_pedido c_detalle_pedido%ROWTYPE;
     
     --Variable que va sumando el precio de todos los pedidos
     v_precio_total NUMBER := 0;
     
    BEGIN
    
        DBMS_OUTPUT.PUT_LINE('Clientes con pedidos registrados ');
        DBMS_OUTPUT.PUT_LINE('');
        
        OPEN c_clientes;
        --Bucle que va mostrando la información de los clientes.
        LOOP
            FETCH c_clientes INTO r_cliente;
            EXIT WHEN c_clientes%NOTFOUND;
            
            --Operación que va calculando los clientes que han realizado pedidos.
            v_num_clientes:=v_num_clientes+1;
            
            DBMS_OUTPUT.PUT_LINE('#############################################################################################');
            DBMS_OUTPUT.PUT_LINE('Cliente '|| v_num_clientes);  
            DBMS_OUTPUT.PUT_LINE('Código del cliente: '|| r_cliente.codigo_cliente);  
            DBMS_OUTPUT.PUT_LINE('Cliente: '|| r_cliente.nombre_cliente || ' | Nombre Contacto: ' || r_cliente.nombre_contacto || ' ' || r_cliente.apellido_contacto);  
            DBMS_OUTPUT.PUT_LINE('Teléfono: ' || r_cliente.telefono || ' | Dirección: ' || r_cliente.linea_direccion1 || ', ' || r_cliente.ciudad || ', ' || r_cliente.pais);  
            
            
                DBMS_OUTPUT.PUT_LINE('----------------------------');
                DBMS_OUTPUT.PUT_LINE('El cliente ha realizado ' || r_cliente.NUMERO_PEDIDOS || ' Pedidos');
                DBMS_OUTPUT.PUT_LINE('----------------------------');
                
                --Operación que va calculando el número total de pedidos
                v_num_pedidos := v_num_pedidos+r_cliente.NUMERO_PEDIDOS;

            --Bucle que va mostrando la información de los pedidos.
            FOR r_pedido IN c_pedido(r_cliente.codigo_cliente) LOOP
            
                DBMS_OUTPUT.PUT_LINE('Codigo Pedido: ' || r_pedido.codigo_pedido);
                DBMS_OUTPUT.PUT_LINE('Fecha en la que se realiza el pedido: ' || r_pedido.fecha_pedido);
                
                --Condición en la que indicamso si el pedido ya ha sido entregado o por el contrario todavía no.
                IF r_pedido.fecha_entrega IS NULL THEN
                    DBMS_OUTPUT.PUT_LINE('El pedido todavía no ha sido entregado');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('Fecha en la que se entregó el pedido: ' || r_pedido.fecha_entrega);
                END IF;
            
                --Bucle que va mostrando información del detalle de los pedidos
                FOR r_detalle_pedido IN c_detalle_pedido(r_pedido.codigo_pedido) LOOP
                
                --Condición para que la cadena se muestre correctamente si es 1 pedido los que ha realizado un cliente o varios.
                IF r_detalle_pedido.CANTIDAD_PRODUCTO=1 THEN
                    DBMS_OUTPUT.PUT_LINE('Cantidad de productos en este pedido: ' || r_detalle_pedido.CANTIDAD_PRODUCTO || ' Producto');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('Cantidad de productos en este pedido: ' || r_detalle_pedido.CANTIDAD_PRODUCTO || ' Productos');
                END IF;
                
                DBMS_OUTPUT.PUT_LINE('El precio del pedido es de : ' || TRIM(TO_CHAR(r_detalle_pedido.PRECIO_TOTAL, '99G999G999D99')) || ' €');
                
                --Opreación que va calculando el total de dinero gastado entre todos los pedidos.
                v_precio_total := v_precio_total+r_detalle_pedido.PRECIO_TOTAL;
                
                
                DBMS_OUTPUT.PUT_LINE('----------------------------');
                 END LOOP;
            END LOOP;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('La cantidad de clientes que han realizado pedidos es de: ' || v_num_clientes || ' clientes.');
        DBMS_OUTPUT.PUT_LINE('La cantidad total de pedidos es de: ' || v_num_pedidos || ' pedidos.');
        DBMS_OUTPUT.PUT_LINE('La cantidad total de dinero registrada de todos los pedidos realizados es de: ' || TRIM(TO_CHAR(v_precio_total, '99G999G999D99')) || ' €.');
    CLOSE c_clientes;
END;
/

/*----------------------------------------------------------------------------------------------------------------*/

--Segundo procedimiento:
--Procedimiento que nos informa de los clientes que han realizado pedidos, los gastos de dichos pedidos, los empleados de dichos clientes, las oficinas del empleado
--y el total de gasto entre todos los pedidos.
CREATE OR REPLACE PROCEDURE informacionFecha(v_fecha_inicio DATE , v_fecha_fin DATE) IS

--Variable en la que vamos a guardar los gastos totales en el periodo de tiempo definido.
v_gasto NUMBER;

--Cursor que nos da información de los cientes que han realizado pedidos en un determinado periodo de tiempo.
--Además de información sobre los gastos que han tenido en cada uno de los pedidos realizados en el intervalo de la fecha definida.
CURSOR c_cliente IS
    SELECT c.codigo_cliente, c.nombre_cliente, p.fecha_pedido, SUM(dp.cantidad*dp.precio_unidad) AS "GASTO", c.codigo_empleado_rep_ventas
    FROM cliente c, pedido p, detalle_pedido dp
    WHERE p.fecha_pedido BETWEEN  v_fecha_inicio AND v_fecha_fin
    AND p.codigo_cliente=c.codigo_cliente
    AND dp.codigo_pedido=p.codigo_pedido
    GROUP BY c.codigo_cliente, c.nombre_cliente, p.fecha_pedido, c.codigo_empleado_rep_ventas
    ORDER BY p.fecha_pedido;
    
    r_cliente c_cliente%ROWTYPE;
    
    --Cursor que obtiene información de los empleados de ventas de aquellos clientes que han realizado compras.
    CURSOR c_empleado (v_cod_empleado NUMBER) IS
        SELECT nombre, apellido1, apellido2, codigo_oficina 
            FROM empleado
            WHERE codigo_empleado=v_cod_empleado;
    
    r_empleado c_empleado%ROWTYPE;
    
    --Cursor que obtiene informacion de las oficinas en la que trabaja el empleado que pasamos por parámetro.
    CURSOR c_oficina(v_cod_oficina VARCHAR2) IS
        SELECT codigo_oficina, ciudad, pais
            FROM oficina
            WHERE codigo_oficina=v_cod_oficina;
    
    r_oficina c_oficina%ROWTYPE;

BEGIN

    --Cursor en la que damos valor a la varible v_gastos con el total de gastos en los pedidods realizados en el periodo de tiempo definido.
    SELECT SUM(dp.cantidad*dp.precio_unidad) INTO v_gasto
        FROM pedido p, detalle_pedido dp
        WHERE p.codigo_pedido=dp.codigo_pedido
        AND p.fecha_pedido BETWEEN v_fecha_inicio AND v_fecha_fin;
    
    --Gestión de la excepción si la fecha inicio es mayor que la fecha final.
    IF v_fecha_fin < v_fecha_inicio THEN
    
        RAISE_APPLICATION_ERROR(-20003,'ERROR[HA INTRODUCIDO LAS FECHAS DE FORMA INCORRECTA]');
        
    ELSE
    
        --Condición en la gestionamos si un cliente ha realizado algún pedido en ese periodo de tiempo
        IF v_gasto IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('En este periodo de tiempo no se ha realizado ningún pedido');
        ELSE 
            DBMS_OUTPUT.PUT_LINE('El dinero que se ha recaudado entre el ' || v_fecha_inicio || ' y el ' || v_fecha_fin || ' es de: ' || TRIM(TO_CHAR(v_gasto, '99G999G999D99')) || ' €');
        
            DBMS_OUTPUT.PUT_LINE('En este periodo de tiempo han realizado pedido los clientes:');
    
            DBMS_OUTPUT.PUT_LINE('------------------------------------');
            
            --Bucle mediante el que vamos mostrando información de los clientes.
            FOR r_cliente IN c_cliente LOOP
                DBMS_OUTPUT.PUT_LINE('El cliente ' || r_cliente.nombre_cliente || ' realizó su pedido el día: ' || r_cliente.fecha_pedido);
                --Bucle mediante el que vamos mostrando información de los empleados del cliente.
                FOR r_empleado IN c_empleado(r_cliente.codigo_empleado_rep_ventas) LOOP
                    --Bucle mediante el que vamos mostrando información de las oficinas de los empleados.
                    FOR r_oficina IN c_oficina(r_empleado.codigo_oficina) LOOP
                        DBMS_OUTPUT.PUT_LINE('El empleado encargado de dicho pedido es: ' || r_empleado.nombre || ' ' || r_empleado.apellido1 || ' ' || r_empleado.apellido2 || ' de la oficina: ' || r_oficina.codigo_oficina || ' de ' ||  r_oficina.ciudad || ', ' || r_oficina.pais || ' .');
                    END LOOP;
                END LOOP;
                DBMS_OUTPUT.PUT_LINE('Ha gastado en su pedido un total de: ' || TRIM(TO_CHAR(r_cliente.GASTO,'99G999G999D99')) || ' €');

                DBMS_OUTPUT.PUT_LINE('------------------------------------');
            END LOOP;
    
        END IF;
    
    END IF;
    
    --Gestión de exepciones.
    EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ocurrió el error ' || SQLCODE ||' mensaje: ' || SQLERRM);
END;
/

/*----------------------------------------------------------------------------------------------------------------*/

--Tabla en la que vamos a insertar cualquier cambio que se produzca en la tabla cliente, ya sea, insertar,
--borrar o actualizar un cliente. 

--En dicha tabla se insertará el usuario que ha efectuado la operación, la fecha y hora, la operación en la que 1 es insertar, 2 actualizar
--y 3 borrar, información del registro antiguo e información del nuevo registro.
CREATE TABLE Auditoria_Cliente(
    Usuario VARCHAR2(30),
    Fecha VARCHAR2(30),
    Operacion NUMBER(1),
    Reg_antiguo VARCHAR2(200),
    Reg_nuevo VARCHAR2(200)
);


CREATE OR REPLACE TRIGGER Auditoria_cliente
    AFTER INSERT OR DELETE OR UPDATE ON cliente
    FOR EACH ROW
BEGIN
    --En el caso de borrar un cliente, se inserta en la tabla auditoria cliente el cambio producido.
    IF DELETING THEN
        INSERT INTO auditoria_cliente VALUES ( USER, TO_CHAR(SYSDATE, 'DD/MM/YYYY / HH:MM:SS'), 3 , :OLD.codigo_cliente || '#' || :OLD.codigo_cliente || '#' || :OLD.nombre_cliente || '#' || :OLD.nombre_contacto || '#' || :OLD.apellido_contacto || '#' || :OLD.telefono || '#' || :OLD.fax || '#' || :OLD.linea_direccion1 || '#' || :OLD.linea_direccion2 || '#' || :OLD.ciudad || '#' || :OLD.region || '#' || :OLD.pais || '#' || :OLD.codigo_postal || '#' || :OLD.codigo_empleado_rep_ventas || '#' || :OLD.limite_credito, '' );
    --En el caso de insertar un cliente, se inserta en la tabla auditoria cliente el cambio producido.
    ELSIF INSERTING THEN
        INSERT INTO auditoria_cliente VALUES ( USER, TO_CHAR(SYSDATE, 'DD/MM/YYYY / HH:MM:SS'), 1 , '', :NEW.codigo_cliente || '#' || :NEW.nombre_cliente || '#' || :NEW.nombre_contacto || '#' || :NEW.apellido_contacto || '#' || :NEW.telefono || '#' || :NEW.fax || '#' || :NEW.linea_direccion1 || '#' || :NEW.linea_direccion2 || '#' || :NEW.ciudad || '#' || :NEW.region || '#' || :NEW.pais || '#' || :NEW.codigo_postal || '#' || :NEW.codigo_empleado_rep_ventas || '#' || :NEW.limite_credito );
    --En el caso de actualizar un cliente, se inserta en la tabla auditoria cliente el cambio producido.
    ELSE
        INSERT INTO auditoria_cliente VALUES ( USER, TO_CHAR(SYSDATE, 'DD/MM/YYYY / HH:MM:SS'), 2 ,:OLD.codigo_cliente || '#' || :OLD.nombre_cliente || '#' || :OLD.nombre_contacto || '#' || :OLD.apellido_contacto || '#' || :OLD.telefono || '#' || :OLD.fax || '#' || :OLD.linea_direccion1 || '#' || :OLD.linea_direccion2 || '#' || :OLD.ciudad || '#' || :OLD.region || '#' || :OLD.pais || '#' || :OLD.codigo_postal || '#' || :OLD.codigo_empleado_rep_ventas || '#' || :OLD.limite_credito, :NEW.codigo_cliente || '#' || :NEW.nombre_cliente || '#' || :NEW.nombre_contacto || '#' || :NEW.apellido_contacto || '#' || :NEW.telefono || '#' || :NEW.fax || '#' || :NEW.linea_direccion1 || '#' || :NEW.linea_direccion2 || '#' || :NEW.ciudad || '#' || :NEW.region || '#' || :NEW.pais || '#' || :NEW.codigo_postal || '#' || :NEW.codigo_empleado_rep_ventas || '#' || :NEW.limite_credito);
    END IF;
    
    EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ocurrió el error ' || SQLCODE ||' mensaje: ' || SQLERRM);
END;
/

/*----------------------------------------------------------------------------------------------------------------*/

--Tabla en la que vamos a insertar cualquier cambio que se produzca en la tabla pedido, ya sea, insertar,
--borrar o actualizar un cliente.

--En dicha tabla se insertará el usuario que ha efectuado la operación, la fecha y hora, la operación en la que 1 es insertar, 2 actualizar
--y 3 borrar, información del registro antiguo e información del nuevo registro.
CREATE TABLE Auditoria_Pedido(
    Usuario VARCHAR2(30),
    Fecha VARCHAR2(30),
    Operacion NUMBER(1),
    Reg_antiguo VARCHAR2(200),
    Reg_nuevo VARCHAR2(200)
);

--Tercer disparador:
CREATE OR REPLACE TRIGGER control_auditoria_pedido
    AFTER INSERT OR DELETE OR UPDATE ON pedido
    FOR EACH ROW
BEGIN
    --En el caso de borrar un pedido, se inserta en la tabla auditoria pedido el cambio producido.
    IF DELETING THEN
        INSERT INTO auditoria_pedido VALUES ( USER, TO_CHAR(SYSDATE, 'DD/MM/YYYY / HH:MM:SS'), 3 , :OLD.codigo_pedido || '#' || :OLD.fecha_pedido || '#' || :OLD.fecha_esperada || '#' || :OLD.fecha_entrega || '#' || :OLD.estado || '#' || :OLD.comentarios || '#' || :OLD.codigo_cliente, '' );
    --En el caso de insertar un pedido, se inserta en la tabla auditoria pedido el cambio producido.
    ELSIF INSERTING THEN
        INSERT INTO auditoria_pedido VALUES ( USER, TO_CHAR(SYSDATE, 'DD/MM/YYYY / HH:MM:SS'), 1 , '', :NEW.codigo_pedido || '#' || :NEW.fecha_pedido || '#' || :NEW.fecha_esperada || '#' || :NEW.fecha_entrega || '#' || :NEW.estado || '#' || :NEW.comentarios || '#' || :NEW.codigo_cliente );
    --En el caso de actualizar un pedido, se inserta en la tabla auditoria pedido el cambio producido.
    ELSE
        INSERT INTO auditoria_pedido VALUES ( USER, TO_CHAR(SYSDATE, 'DD/MM/YYYY / HH:MM:SS'), 2 ,:OLD.codigo_pedido || '#' || :OLD.fecha_pedido || '#' || :OLD.fecha_esperada || '#' || :OLD.fecha_entrega || '#' || :OLD.estado || '#' || :OLD.comentarios || '#' || :OLD.codigo_cliente, :NEW.codigo_pedido || '#' || :NEW.fecha_pedido || '#' || :NEW.fecha_esperada || '#' || :NEW.fecha_entrega || '#' || :NEW.estado || '#' || :NEW.comentarios || '#' || :NEW.codigo_cliente);
    END IF;
    
    --Getión de exepciones
    EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ocurrió el error ' || SQLCODE ||'mensaje: ' || SQLERRM);
END;
/

/*----------------------------------------------------------------------------------------------------------------*/

--Disparador que controla la actualización de un detalle pedido, en el que modificamos el stock del producto, según la cantidad que tengamos en el
--detalle pedido.
CREATE OR REPLACE TRIGGER control_detalle_pedido
    BEFORE UPDATE ON detalle_pedido
    FOR EACH ROW

DECLARE
--variable que guarda la cantidad de stock de un producto
v_catidad_stock NUMBER;

BEGIN

    --Cursor que guarda en la varible v_catidad_stock la cantidad de stock de un producto determinado.
    SELECT cantidad_en_stock INTO v_catidad_stock FROM producto
        WHERE codigo_producto=:NEW.codigo_producto;
    
    --Condición que controla la exepción en el caso de que la cantidad de stock sea inferior a la cantidad de productos a comprar.
    IF v_catidad_stock < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20002,'No hay cantidad en stock suficiente.');
    END IF;
    
    IF :NEW.cantidad < :OLD.cantidad THEN
        --Actualización de la cantidad en stock restadole la diferencia entre la cantidad nueva y la antigua.
        UPDATE producto SET cantidad_en_stock=cantidad_en_stock-(:NEW.cantidad-:OLD.cantidad)
            WHERE codigo_producto=:NEW.codigo_producto;
    ELSE
        --Actualización de la cantidad en stock sumandole la diferencia entre la cantidad nueva y la antigua
        UPDATE producto SET cantidad_en_stock=cantidad_en_stock+(:OLD.cantidad-:NEW.cantidad)
            WHERE codigo_producto=:NEW.codigo_producto;
    END IF;
    
    --Gestión de exepciones.
    EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ocurrió el error ' || SQLCODE ||' mensaje: ' || SQLERRM);
    
END;
/