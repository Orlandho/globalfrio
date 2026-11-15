-- Global Frío: modelo físico MySQL 8.4 (RF01-RF05).
-- Inicialización única sobre un volumen nuevo; conserva los datos existentes.

-- Paso 1 del cotizador: instalación, mantenimiento o reparación
CREATE TABLE tipo_servicio (
    id          BIGINT AUTO_INCREMENT,
    codigo      VARCHAR(20)  NOT NULL,
    nombre      VARCHAR(60)  NOT NULL,
    descripcion VARCHAR(255),
    activo      BIT(1)       NOT NULL DEFAULT b'1',
    CONSTRAINT pk_tipo_servicio PRIMARY KEY (id),
    CONSTRAINT uq_tipo_servicio_codigo UNIQUE (codigo),
    CONSTRAINT ck_tipo_servicio_codigo CHECK (codigo IN ('INSTALACION','MANTENIMIENTO','REPARACION'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Paso 2 del cotizador: casa, negocio o empresa
CREATE TABLE tipo_cliente (
    id            BIGINT AUTO_INCREMENT,
    codigo        VARCHAR(20)  NOT NULL,
    nombre        VARCHAR(60)  NOT NULL,
    descripcion   VARCHAR(255),
    factor_precio DECIMAL(4,2) DEFAULT 1.00 NOT NULL,
    activo        BIT(1)       NOT NULL DEFAULT b'1',
    CONSTRAINT pk_tipo_cliente PRIMARY KEY (id),
    CONSTRAINT uq_tipo_cliente_codigo UNIQUE (codigo),
    CONSTRAINT ck_tipo_cliente_codigo CHECK (codigo IN ('HOGAR','NEGOCIO','EMPRESA')),
    CONSTRAINT ck_tipo_cliente_factor CHECK (factor_precio > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Zonas de atención y costo de traslado
CREATE TABLE zona (
    id             BIGINT AUTO_INCREMENT,
    nombre         VARCHAR(60)   NOT NULL,
    distritos      VARCHAR(400),
    costo_traslado DECIMAL(10,2) NOT NULL,
    activo         BIT(1)       NOT NULL DEFAULT b'1',
    CONSTRAINT pk_zona PRIMARY KEY (id),
    CONSTRAINT uq_zona_nombre UNIQUE (nombre),
    CONSTRAINT ck_zona_costo CHECK (costo_traslado >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Catálogo de equipos y servicios (entidad Producto)
CREATE TABLE productos (
    id               BIGINT AUTO_INCREMENT,
    nombre           VARCHAR(100)  NOT NULL,
    descripcion      VARCHAR(255),
    precio           DECIMAL(10,2) NOT NULL,
    stock            INTEGER       NOT NULL,
    categoria        VARCHAR(50)   NOT NULL,
    activo           BIT(1)       NOT NULL DEFAULT b'1',
    capacidad_btu    INTEGER,
    area_max_m2      INTEGER,
    tipo_servicio_id BIGINT,
    CONSTRAINT pk_productos PRIMARY KEY (id),
    CONSTRAINT fk_productos_tipo_servicio FOREIGN KEY (tipo_servicio_id) REFERENCES tipo_servicio(id),
    CONSTRAINT ck_productos_categoria CHECK (categoria IN ('EQUIPO','SERVICIO')),
    CONSTRAINT ck_productos_precio CHECK (precio > 0),
    CONSTRAINT ck_productos_stock CHECK (stock >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Cabecera de la cotización (RF04)
CREATE TABLE cotizacion (
    id                 BIGINT AUTO_INCREMENT,
    codigo             VARCHAR(20)   NOT NULL,
    fecha              DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    tipo_servicio_id   BIGINT        NOT NULL,
    tipo_cliente_id    BIGINT        NOT NULL,
    zona_id            BIGINT        NOT NULL,
    area_m2            DECIMAL(6,2),
    btu_recomendado    INTEGER,
    subtotal_equipos   DECIMAL(10,2) DEFAULT 0 NOT NULL,
    subtotal_mano_obra DECIMAL(10,2) DEFAULT 0 NOT NULL,
    costo_traslado     DECIMAL(10,2) DEFAULT 0 NOT NULL,
    total              DECIMAL(10,2) NOT NULL,
    estado             VARCHAR(15)   DEFAULT 'GENERADA' NOT NULL,
    CONSTRAINT pk_cotizacion PRIMARY KEY (id),
    CONSTRAINT uq_cotizacion_codigo UNIQUE (codigo),
    CONSTRAINT fk_cotizacion_tipo_servicio FOREIGN KEY (tipo_servicio_id) REFERENCES tipo_servicio(id),
    CONSTRAINT fk_cotizacion_tipo_cliente FOREIGN KEY (tipo_cliente_id) REFERENCES tipo_cliente(id),
    CONSTRAINT fk_cotizacion_zona FOREIGN KEY (zona_id) REFERENCES zona(id),
    CONSTRAINT ck_cotizacion_total CHECK (total = subtotal_equipos + subtotal_mano_obra + costo_traslado),
    CONSTRAINT ck_cotizacion_estado CHECK (estado IN ('GENERADA','CONTACTADO','ACEPTADA','DESCARTADA'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Líneas de la cotización
CREATE TABLE detalle_cotizacion (
    id              BIGINT AUTO_INCREMENT,
    cotizacion_id   BIGINT        NOT NULL,
    producto_id     BIGINT        NOT NULL,
    cantidad        INTEGER       DEFAULT 1 NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_detalle_cotizacion PRIMARY KEY (id),
    CONSTRAINT fk_detalle_cotizacion FOREIGN KEY (cotizacion_id) REFERENCES cotizacion(id) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id) REFERENCES productos(id),
    CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_subtotal CHECK (subtotal = cantidad * precio_unitario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===================== CONTENIDO DE LA PÁGINA WEB =====================
-- Secciones Servicios, Trabajos y Mantenimiento: el frontend las pide a /api/contenido/...

CREATE TABLE servicio_web (
    id          BIGINT AUTO_INCREMENT,
    titulo      VARCHAR(60)  NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    icono       VARCHAR(40)  NOT NULL,
    orden       INT          NOT NULL,
    activo      BIT(1)       NOT NULL DEFAULT b'1',
    CONSTRAINT pk_servicio_web PRIMARY KEY (id),
    CONSTRAINT ck_servicio_web_orden CHECK (orden > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE trabajo (
    id                BIGINT AUTO_INCREMENT,
    pie               VARCHAR(120) NOT NULL,
    imagen            VARCHAR(200) NOT NULL,
    texto_alternativo VARCHAR(200) NOT NULL,
    orden             INT          NOT NULL,
    activo            BIT(1)       NOT NULL DEFAULT b'1',
    CONSTRAINT pk_trabajo PRIMARY KEY (id),
    CONSTRAINT ck_trabajo_orden CHECK (orden > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE item_mantenimiento (
    id          BIGINT AUTO_INCREMENT,
    titulo      VARCHAR(60)  NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    orden       INT          NOT NULL,
    activo      BIT(1)       NOT NULL DEFAULT b'1',
    CONSTRAINT pk_item_mantenimiento PRIMARY KEY (id),
    CONSTRAINT ck_item_mantenimiento_orden CHECK (orden > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
