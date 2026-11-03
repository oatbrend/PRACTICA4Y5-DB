
CREATE TABLE cliente (
  numeroCliente    INTEGER      NOT NULL,
  razonSocial      VARCHAR(150) NOT NULL,
  correoCliente    VARCHAR(100),
  telefonoCliente  VARCHAR(20),
  tipoCliente      VARCHAR(15)  NOT NULL,         
  RFC              VARCHAR(13),
  regimenFiscal    VARCHAR(100),
  estadoOrigen     VARCHAR(50),
  idFiscalGlobal   VARCHAR(30),
  paisReceptor     VARCHAR(50),
  CONSTRAINT pk_cliente PRIMARY KEY (numeroCliente),
  CONSTRAINT uq_cliente_rfc UNIQUE (RFC),
  CONSTRAINT uq_cliente_idfiscal UNIQUE (idFiscalGlobal),
  CONSTRAINT ck_tipo_cliente CHECK (tipoCliente IN ('NACIONAL','EXPORTACION')),
  CONSTRAINT ck_subtipo_cliente CHECK (
    (tipoCliente = 'NACIONAL'
      AND RFC IS NOT NULL AND regimenFiscal IS NOT NULL AND estadoOrigen IS NOT NULL
      AND idFiscalGlobal IS NULL AND paisReceptor IS NULL)
    OR
    (tipoCliente = 'EXPORTACION'
      AND idFiscalGlobal IS NOT NULL AND paisReceptor IS NOT NULL
      AND RFC IS NULL AND regimenFiscal IS NULL AND estadoOrigen IS NULL)
  )
);


CREATE TABLE transportista (
  claveTransportista VARCHAR(10)  NOT NULL,
  nombreEmpresa      VARCHAR(100) NOT NULL,
  telefonoAtencion   VARCHAR(20),
  email              VARCHAR(100),
  esNacional         BOOLEAN NOT NULL DEFAULT FALSE,
  esInternacional    BOOLEAN NOT NULL DEFAULT FALSE,
  RFC                VARCHAR(13),
  codigoAduanal      VARCHAR(20),
  agenciaAduanal     VARCHAR(100),
  CONSTRAINT pk_transportista PRIMARY KEY (claveTransportista),
  CONSTRAINT ck_transp_total CHECK (esNacional OR esInternacional),
  CONSTRAINT ck_transp_nacional CHECK (
    (esNacional AND RFC IS NOT NULL) OR (NOT esNacional AND RFC IS NULL)),
  CONSTRAINT ck_transp_internacional CHECK (
    (esInternacional AND codigoAduanal IS NOT NULL AND agenciaAduanal IS NOT NULL)
    OR (NOT esInternacional AND codigoAduanal IS NULL AND agenciaAduanal IS NULL))
);


CREATE TABLE producto (
  claveProducto      VARCHAR(10)   NOT NULL,
  costoUnitarioUSD   NUMERIC(12,2) NOT NULL,
  precioUnitarioUSD  NUMERIC(12,2) NOT NULL,
  tipoProducto       VARCHAR(10)   NOT NULL,       
  provMaquinaria     VARCHAR(100),
  provTransformador  VARCHAR(100),
  provTransporte     VARCHAR(100),
  CONSTRAINT pk_producto PRIMARY KEY (claveProducto),
  CONSTRAINT ck_producto_costo  CHECK (costoUnitarioUSD  >= 0),
  CONSTRAINT ck_producto_precio CHECK (precioUnitarioUSD >= 0),
  CONSTRAINT ck_tipo_producto CHECK (tipoProducto IN ('OMNIGOLD','HYVOLT','HYPRENE')),
  CONSTRAINT ck_subtipo_producto CHECK (
    (tipoProducto = 'OMNIGOLD' AND provMaquinaria IS NOT NULL
       AND provTransformador IS NULL AND provTransporte IS NULL)
    OR
    (tipoProducto = 'HYVOLT' AND provTransformador IS NOT NULL
       AND provMaquinaria IS NULL AND provTransporte IS NULL)
    OR
    (tipoProducto = 'HYPRENE' AND provTransporte IS NOT NULL
       AND provMaquinaria IS NULL AND provTransformador IS NULL)
  )
);


CREATE TABLE sucursal (
  numeroCliente      INTEGER     NOT NULL,
  claveSucursal      VARCHAR(10) NOT NULL,
  nombrePlanta       VARCHAR(100) NOT NULL,
  telefonoEncargado  VARCHAR(20),
  calle              VARCHAR(100),
  numero             VARCHAR(10),
  ciudad             VARCHAR(60),
  estado             VARCHAR(60),
  pais               VARCHAR(60),
  CP                 VARCHAR(10),
  CONSTRAINT pk_sucursal PRIMARY KEY (numeroCliente, claveSucursal),
  CONSTRAINT fk_sucursal_cliente FOREIGN KEY (numeroCliente)
    REFERENCES cliente (numeroCliente)
    ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE pedido (
  folio          INTEGER     NOT NULL,
  numeroCliente  INTEGER     NOT NULL,
  estatus        VARCHAR(20) NOT NULL,
  dia            SMALLINT    NOT NULL,
  mes            SMALLINT    NOT NULL,
  anio           SMALLINT    NOT NULL,
  CONSTRAINT pk_pedido PRIMARY KEY (folio),
  CONSTRAINT fk_pedido_cliente FOREIGN KEY (numeroCliente)
    REFERENCES cliente (numeroCliente)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_pedido_dia  CHECK (dia  BETWEEN 1 AND 31),
  CONSTRAINT ck_pedido_mes  CHECK (mes  BETWEEN 1 AND 12),
  CONSTRAINT ck_pedido_anio CHECK (anio >= 2000)
);


CREATE TABLE detalle (
  folio             INTEGER       NOT NULL,
  claveParcial      INTEGER       NOT NULL,
  claveProducto     VARCHAR(10)   NOT NULL,
  costoProduccion   NUMERIC(12,2) NOT NULL,
  precioAplicado    NUMERIC(12,2) NOT NULL,
  cantidad          INTEGER       NOT NULL,
  CONSTRAINT pk_detalle PRIMARY KEY (folio, claveParcial),
  CONSTRAINT fk_detalle_pedido FOREIGN KEY (folio)
    REFERENCES pedido (folio)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_detalle_producto FOREIGN KEY (claveProducto)
    REFERENCES producto (claveProducto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_detalle_costo    CHECK (costoProduccion >= 0),
  CONSTRAINT ck_detalle_precio   CHECK (precioAplicado  >= 0)
);


CREATE TABLE envio (
  numeroGuia          VARCHAR(20)   NOT NULL,
  folio               INTEGER       NOT NULL,
  claveTransportista  VARCHAR(10)   NOT NULL,
  numeroCliente       INTEGER       NOT NULL,
  claveSucursal       VARCHAR(10)   NOT NULL,
  costoFlete          NUMERIC(12,2) NOT NULL,
  dia                 SMALLINT      NOT NULL,
  mes                 SMALLINT      NOT NULL,
  anio                SMALLINT      NOT NULL,
  CONSTRAINT pk_envio PRIMARY KEY (numeroGuia),
  CONSTRAINT uq_envio_folio UNIQUE (folio),
  CONSTRAINT fk_envio_pedido FOREIGN KEY (folio)
    REFERENCES pedido (folio)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_envio_transportista FOREIGN KEY (claveTransportista)
    REFERENCES transportista (claveTransportista)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_envio_sucursal FOREIGN KEY (numeroCliente, claveSucursal)
    REFERENCES sucursal (numeroCliente, claveSucursal)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_envio_flete CHECK (costoFlete >= 0),
  CONSTRAINT ck_envio_dia  CHECK (dia  BETWEEN 1 AND 31),
  CONSTRAINT ck_envio_mes  CHECK (mes  BETWEEN 1 AND 12),
  CONSTRAINT ck_envio_anio CHECK (anio >= 2000)
);