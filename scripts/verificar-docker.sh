#!/usr/bin/env bash
# Pruebas integrales en proyectos Compose desechables (RF-SEM03-02, RF-SEM12-01).
set -euo pipefail
cd "$(dirname "$0")/.."

modo="${1:-moderna}"
case "$modo" in
    moderna) archivo=compose.yaml ;;
    universidad) archivo=compose.legacy.yaml ;;
    *) echo "Uso: bash scripts/verificar-docker.sh [moderna|universidad]" >&2; exit 2 ;;
esac

# Credenciales y nombres exclusivos de esta ejecución; no utiliza el volumen de trabajo.
export MSSQL_SA_PASSWORD="QaA1!$(openssl rand -hex 24)"
export DB_CLAVE="QaB2!$(openssl rand -hex 24)"
export SQLSERVER_PORT="${QA_SQLSERVER_PORT:-11433}"
export BACKEND_PORT="${QA_BACKEND_PORT:-18080}"
export FRONTEND_PORT="${QA_FRONTEND_PORT:-14200}"
project="globalfrio-qa-$(openssl rand -hex 6)"
dc() { docker compose -f "$archivo" -p "$project" "$@"; }
esperar_salud() {
    local servicio="$1" id estado intento
    for ((intento=0; intento<120; intento++)); do
        id="$(dc ps -a -q "$servicio")"
        if [ -n "$id" ]; then
            estado="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$id")"
            if [ "$estado" = healthy ]; then return 0; fi
            if [ "$estado" = unhealthy ] || [ "$estado" = exited ] || [ "$estado" = dead ]; then
                echo "Servicio no saludable: $servicio" >&2
                return 1
            fi
        fi
        sleep 2
    done
    echo "Tiempo agotado esperando a $servicio" >&2
    return 1
}
# La variante de aula evita depender de los flags de espera de Compose.
arrancar() {
    if [ "$modo" = moderna ]; then
        dc up -d --wait --wait-timeout 300 "$@"
    else
        dc up -d "$@"
        esperar_salud sqlserver
        if [ "${1:-}" != sqlserver ]; then
            esperar_salud backend
            esperar_salud frontend
        fi
    fi
}
cleanup() {
    rc=$?
    if [ "$rc" -ne 0 ]; then dc logs --no-color || true; fi
    dc --profile test down -v --remove-orphans || true
    exit "$rc"
}
trap cleanup EXIT

docker version
docker compose version
dc config --quiet

# Base inicializada desde los SQL reales. JUnit comprueba motor, catálogo y rollback.
arrancar sqlserver
dc --profile test run --rm --build pruebas
dc --profile test down -v

# Arranque de los tres servicios desde un volumen limpio.
arrancar --build
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
arrancar
curl -fsS "$url/api/cotizador/cotizaciones/$codigo" | jq -e --arg codigo "$codigo" '.codigo == $codigo and (.lineas | length) == 1'
echo "OK ($modo): SQL Server real, API, frontend, transacciones y persistencia tras recrear contenedores."
