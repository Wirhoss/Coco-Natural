create table categoria (
   id_categoria         number
      generated always as identity
   primary key,
   nombre               varchar2(32) not null,
   descripcion          varchar2(32),
   fecha_creacion       timestamp default systimestamp not null,
   usuario_creacion     varchar2(50) not null,
   fecha_modificacion   timestamp,
   usuario_modificacion varchar2(50)
);

create table proveedor (
   id_proveedor         number
      generated always as identity
   primary key,
   nombre               varchar2(32) not null,
   telefono             varchar2(20),
   email                varchar2(64) not null,
   direccion            varchar2(256) not null,
   fecha_creacion       timestamp default systimestamp not null,
   usuario_creacion     varchar2(50) not null,
   fecha_modificacion   timestamp,
   usuario_modificacion varchar2(50)
);

create table producto (
   id_producto          number
      generated always as identity
   primary key,
   nombre               varchar2(32) not null,
   descripcion          varchar2(32),
   precio               number(10,2) not null,
   stock_minimo         number not null,
   stock_actual         number not null,
   id_categoria         number not null,
   id_proveedor         number not null,
   fecha_creacion       timestamp default systimestamp not null,
   usuario_creacion     varchar2(50) not null,
   fecha_modificacion   timestamp,
   usuario_modificacion varchar2(50),
   constraint fk_categoria foreign key ( id_categoria )
      references categoria ( id_categoria ),
   constraint fk_proveedor foreign key ( id_proveedor )
      references proveedor ( id_proveedor ),
   constraint chk_stock check ( stock_actual >= 0 )
);

create table cliente (
   id_cliente           number
      generated always as identity
   primary key,
   nombre               varchar2(32) not null,
   telefono             varchar2(20) not null,
   email                varchar2(64) not null,
   direccion            varchar2(256) not null,
   fecha_creacion       timestamp default systimestamp not null,
   usuario_creacion     varchar2(50) not null,
   fecha_modificacion   timestamp,
   usuario_modificacion varchar2(50)
);

create table pedido (
   id_pedido            number
      generated always as identity
   primary key,
   fecha_pedido         date default sysdate not null,
   fecha_entrega        date,
   estado               varchar2(16) default 'pendiente' check ( estado in ( 'pendiente',
                                                               'completado',
                                                               'cancelado' ) ),
   total                number(10,2) default 0,
   id_cliente           number not null,
   fecha_creacion       timestamp default systimestamp not null,
   usuario_creacion     varchar2(50) not null,
   fecha_modificacion   timestamp,
   usuario_modificacion varchar2(50),
   constraint fk_cliente foreign key ( id_cliente )
      references cliente ( id_cliente )
);

create table detalle_pedido (
   id_detalle       number
      generated always as identity
   primary key,
   cantidad         number not null check ( cantidad > 0 ),
   precio           number(10,2) not null,
      subtotal         number(10,2) generated always as ( cantidad * precio ) virtual,
   id_pedido        number not null,
   id_producto      number not null,
   fecha_creacion   timestamp default systimestamp not null,
   usuario_creacion varchar2(50) not null,
   constraint fk_pedido foreign key ( id_pedido )
      references pedido ( id_pedido ),
   constraint fk_producto_detalle foreign key ( id_producto )
      references producto ( id_producto )
);

create table movimientos (
   id_movimiento    number
      generated always as identity
   primary key,
   tipo             varchar2(32) not null check ( tipo in ( 'entrada',
                                                'salida' ) ),
   cantidad         number not null check ( cantidad > 0 ),
   fecha            timestamp default systimestamp not null,
   id_producto      number not null,
   usuario_creacion varchar2(50) not null,
   constraint fk_producto_movimiento foreign key ( id_producto )
      references producto ( id_producto )
);

create table alertas_stock (
   id_alerta        number
      generated always as identity
   primary key,
   id_producto      number not null,
   mensaje          varchar2(256) not null,
   fecha            date default sysdate not null,
   usuario_creacion varchar2(50) not null,
   constraint fk_producto_alerta foreign key ( id_producto )
      references producto ( id_producto )
);

create table auditoria_movimientos (
   id_auditoria    number
      generated always as identity
   primary key,
   id_movimiento   number not null,
   fecha_auditoria timestamp default systimestamp not null,
   usuario         varchar2(50) not null,
   accion          varchar2(10) not null check ( accion in ( 'INSERT',
                                                    'UPDATE',
                                                    'DELETE' ) )
);

ALTER TABLE pedido ADD (codigo VARCHAR2(32));

CREATE SEQUENCE seq_codigo_pedido START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE auditoria_producto (
  id_auditoria        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_producto         NUMBER NOT NULL,
  fecha_auditoria     TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
  usuario             VARCHAR2(50),
  accion              VARCHAR2(10) NOT NULL CHECK (accion IN ('UPDATE','DELETE')),
  detalles            VARCHAR2(4000)
);

alter table auditoria_movimientos
   add constraint fk_auditoria_movimiento foreign key ( id_movimiento )
      references movimientos ( id_movimiento );

-- Indices
create index idx_producto_categoria on
   producto (
      id_categoria
   );
create index idx_producto_proveedor on
   producto (
      id_proveedor
   );
create index idx_movimientos_producto_fecha on
   movimientos (
      id_producto,
      fecha
   );
create index idx_detallepedido_pedido on
   detalle_pedido (
      id_pedido
   );
create unique index ux_cliente_email on
   cliente (
      email
   );
create unique index ux_proveedor_email on
   proveedor (
      email
   );

-- Otros arreglos:
alter table pedido modify (
   fecha_pedido timestamp default systimestamp not null
);
alter table producto add constraint chk_precio_nonneg check ( precio >= 0 );
alter table pedido add constraint chk_total_nonneg check ( total >= 0 );