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


-- Esto hay que refinarlo, lo escribi a las 12 pm asi que no lo he ni probado
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