CREATE OR REPLACE TRIGGER trg_actualizar_stock
AFTER INSERT ON movimientos
FOR EACH ROW
DECLARE
  v_stock producto.stock_actual%TYPE;
BEGIN

  SELECT stock_actual
    INTO v_stock
    FROM producto
   WHERE id_producto = :new.id_producto
     FOR UPDATE;

  IF :new.tipo = 'entrada' THEN
    UPDATE producto
       SET stock_actual       = stock_actual + :new.cantidad,
           fecha_modificacion = SYSTIMESTAMP,
           usuario_modificacion = :new.usuario_creacion
     WHERE id_producto = :new.id_producto;
  ELSE  -- 'salida'
    IF v_stock < :new.cantidad THEN
      RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente para el movimiento. Producto ID='||:new.id_producto);
    END IF;

    UPDATE producto
       SET stock_actual       = stock_actual - :new.cantidad,
           fecha_modificacion = SYSTIMESTAMP,
           usuario_modificacion = :new.usuario_creacion
     WHERE id_producto = :new.id_producto;
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'Producto no encontrado (movimientos -> id_producto='||:new.id_producto||')');
END trg_actualizar_stock;

CREATE OR REPLACE TRIGGER trg_validar_pedido
BEFORE INSERT ON detalle_pedido
FOR EACH ROW
DECLARE
  v_stock producto.stock_actual%TYPE;
BEGIN
  SELECT stock_actual
    INTO v_stock
    FROM producto
   WHERE id_producto = :new.id_producto;

  IF v_stock < :new.cantidad THEN
    RAISE_APPLICATION_ERROR(-20003, 'No hay stock suficiente para el producto ID='||:new.id_producto||' (solicitado='||:new.cantidad||', disponible='||v_stock||')');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20004, 'Producto no encontrado al validar pedido. ID='||:new.id_producto);
END trg_validar_pedido;


CREATE OR REPLACE TRIGGER trg_generar_codigo
BEFORE INSERT ON pedido
FOR EACH ROW
DECLARE
  v_seq NUMBER;
BEGIN
  IF :new.codigo IS NULL THEN
    SELECT seq_codigo_pedido.NEXTVAL INTO v_seq FROM dual;
    :new.codigo := 'P-' || TO_CHAR(SYSDATE,'YYYY') || '-' || LPAD(v_seq,6,'0');
  END IF;
END trg_generar_codigo;

CREATE OR REPLACE TRIGGER trg_actualizar_total_pedido
AFTER INSERT OR UPDATE OR DELETE ON detalle_pedido
FOR EACH ROW
DECLARE
  v_id_pedido detalle_pedido.id_pedido%TYPE;
  v_total    NUMBER(12,2);
BEGIN
  IF INSERTING OR UPDATING THEN
    v_id_pedido := :new.id_pedido;
  ELSE
    v_id_pedido := :old.id_pedido;
  END IF;

  SELECT NVL(SUM(subtotal),0) INTO v_total
    FROM detalle_pedido
   WHERE id_pedido = v_id_pedido;

  UPDATE pedido
     SET total = v_total,
         fecha_modificacion = SYSTIMESTAMP
   WHERE id_pedido = v_id_pedido;
END trg_actualizar_total_pedido;

CREATE OR REPLACE TRIGGER trg_auditar_productos
AFTER UPDATE OR DELETE ON producto
FOR EACH ROW
DECLARE
  v_accion VARCHAR2(10);
  v_detalles VARCHAR2(4000);
  v_usuario VARCHAR2(50);
BEGIN
  IF UPDATING THEN
    v_accion := 'UPDATE';
    v_usuario := NVL(:new.usuario_modificacion, :old.usuario_modificacion);
    v_detalles := 'ANTES -> nombre='||NVL(:old.nombre,'NULL')||', precio='||NVL(TO_CHAR(:old.precio),'NULL') ||
                  ' | DESPUES -> nombre='||NVL(:new.nombre,'NULL')||', precio='||NVL(TO_CHAR(:new.precio),'NULL');
  ELSE
    v_accion := 'DELETE';
    v_usuario := NVL(:old.usuario_modificacion, :old.usuario_creacion);
    v_detalles := 'ELIMINADO -> nombre='||NVL(:old.nombre,'NULL')||', precio='||NVL(TO_CHAR(:old.precio),'NULL');
  END IF;

  INSERT INTO auditoria_producto (id_producto, fecha_auditoria, usuario, accion, detalles)
       VALUES (NVL(:old.id_producto, :new.id_producto), SYSTIMESTAMP, v_usuario, v_accion, v_detalles);
END trg_auditar_productos;
