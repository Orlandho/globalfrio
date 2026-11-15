#!/usr/bin/env bash
# RF-SEM03-02: inicialización no destructiva y usuario sin permisos DDL.
set -euo pipefail
if [[ ! "${DB_CLAVE:-}" =~ ^[A-Za-z0-9_!@%+=.-]{12,128}$ ]] || [[ "$DB_CLAVE" == "$MSSQL_SA_PASSWORD" ]]; then
    echo "DB_CLAVE debe tener 12-128 caracteres permitidos y ser distinta de la clave sa." >&2
    exit 1
fi
sqlcmd=/opt/mssql-tools18/bin/sqlcmd
export SQLCMDPASSWORD="$MSSQL_SA_PASSWORD"
admin() { "$sqlcmd" -S sqlserver,1433 -U sa -C -b -l 15 -f 65001 "$@"; }
admin -d master -Q "IF DB_ID(N'globalfrio_db') IS NULL CREATE DATABASE globalfrio_db"
tablas="$(admin -d globalfrio_db -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.tables" | tr -d '[:space:]')"
if [[ "$tablas" == 0 ]]; then
    admin -i /init/01_esquema_y_datos.sql
else
    admin -d globalfrio_db -Q "IF (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID(N'dbo') AND name IN (N'tipo_servicio',N'tipo_cliente',N'zona',N'productos',N'cotizacion',N'detalle_cotizacion',N'servicio_web',N'trabajo',N'item_mantenimiento')) <> 9 THROW 50002, 'Esquema parcial: revisar la base sin eliminar el volumen.', 1"
fi
admin -i /init/02_usuario_backend.sql
SQLCMDPASSWORD="$DB_CLAVE" "$sqlcmd" -S sqlserver,1433 -U globalfrio_backend -C -b -l 15 -d globalfrio_db -Q "SELECT TOP (1) id FROM dbo.productos"
echo "SQL Server preparado: esquema validable y usuario de aplicación disponible."
