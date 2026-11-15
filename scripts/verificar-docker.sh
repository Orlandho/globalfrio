#!/usr/bin/env bash
# Pruebas integrales en proyectos Compose desechables (RF-SEM03-02, RF-SEM12-01).
set -euo pipefail
cd "$(dirname "$0")/.."

# Credenciales y nombres exclusivos de esta ejecución; no utiliza el volumen de trabajo.
export MYSQL_ROOT_PASSWORD="$(openssl rand -hex 24)"
export MYSQL_PASSWORD="$(openssl rand -hex 24)"
export MYSQL_DATABASE=globalfrio_db MYSQL_USER=globalfrio_backend
export MYSQL_PORT="${QA_MYSQL_PORT:-13306}"
export BACKEND_PORT="${QA_BACKEND_PORT:-18080}"
export FRONTEND_PORT="${QA_FRONTEND_PORT:-14200}"
project="globalfrio-qa-$(openssl rand -hex 6)"
dc() { docker compose -p "$project" "$@"; }
cleanup() {
    rc=$?
    if [ "$rc" -ne 0 ]; then dc logs --no-color || true; fi
    dc --profile test down -v --remove-orphans || true
    exit "$rc"
}
trap cleanup EXIT

docker compose version
dc config --quiet

# Base inicializada desde los SQL reales. JUnit comprueba motor, catálogo y rollback.
dc up -d --wait --wait-timeout 240 mysql
dc --profile test run --rm --build pruebas
dc --profile test down -v

# Arranque de los tres servicios desde un volumen limpio.
dc up -d --build --wait --wait-timeout 240
url="http://127.0.0.1:$FRONTEND_PORT"
curl -fsS "$url/" | grep -q '<app-root'
test "$(curl -fsS "$url/api/saludo")" = "Backend activo"
catalogo="$(curl -fsS "$url/api/cotizador/catalogo")"
jq -e '(.equipos | length) == 3 and (.zonas | length) == 6' <<<"$catalogo"
zona="$(jq -er '.zonas[] | select(.nombre == "Lima Norte") | .id' <<<"$catalogo")"
servicios="$(curl -fsS "$url/api/cotizador/servicios?tipo=REPARACION")"
producto="$(jq -er '.[] | select(.nombre == "Diagnóstico técnico") | .id' <<<"$servicios")"
payload="$(jq -nc --argjson zona "$zona" --argjson producto "$producto" '{tipoServicio:"REPARACION",tipoCliente:"HOGAR",zonaId:$zona,items:[{productoId:$producto,cantidad:1}]}')"
codigo="$(curl -fsS -H 'Content-Type: application/json' -d "$payload" "$url/api/cotizador/cotizaciones" | jq -er '.codigo')"

# El registro debe sobrevivir a la eliminación y recreación de contenedores.
dc down
dc up -d --wait --wait-timeout 240
curl -fsS "$url/api/cotizador/cotizaciones/$codigo" | jq -e --arg codigo "$codigo" '.codigo == $codigo and (.lineas | length) == 1'
echo "OK: MySQL real, API, frontend, transacciones y persistencia tras recrear contenedores."
