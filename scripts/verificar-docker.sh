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
# Usar la misma imagen Node que el build Angular; no instalar jq ni Node en el host.
# Sin red ni volumen montado durante el análisis JSON; sin conversión MSYS de argumentos.
imagen_json=node:22-bookworm-slim
docker image inspect "$imagen_json" >/dev/null 2>&1 || docker pull "$imagen_json"
parser_json="$(cat scripts/verificar-json.cjs)"
json_qa() {
    MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker run --rm -i --pull never --network none "$imagen_json" node -e "$parser_json" -- "$@"
}
json_qa autoprueba </dev/null
dc config --quiet

# Base inicializada desde los SQL reales. JUnit comprueba motor, catálogo y rollback.
arrancar sqlserver
dc --profile test run --rm --build pruebas
dc --profile test down -v

# Arranque de los tres servicios desde un volumen limpio.
arrancar --build
url="http://127.0.0.1:$FRONTEND_PORT"
html="$(curl -fsS "$url/")"
grep -q '<app-root' <<<"$html"
# Las fuentes se sirven desde la imagen local, sin Google Fonts.
if grep -Eq 'fonts\.(googleapis|gstatic)\.com' <<<"$html"; then
    echo "El HTML todavía depende de fuentes remotas" >&2
    exit 1
fi
# Comprobar el CSS generado, no solo que Nginx tenga los archivos.
estilo="$(grep -oE 'styles\.[A-Za-z0-9_-]+\.css' <<<"$html" | sort -u)"
test -n "$estilo"
test "$(wc -l <<<"$estilo")" -eq 1
css="$(curl -fsS "$url/$estilo")"
if grep -Eq 'fonts\.(googleapis|gstatic)\.com' <<<"$css"; then
    echo "El CSS todavía depende de fuentes remotas" >&2
    exit 1
fi
for fuente in plus-jakarta-sans.ttf material-icons.ttf; do
    grep -Fq "/assets/fonts/$fuente" <<<"$css"
    esperado="$(git hash-object "frontend/src/assets/fonts/$fuente")"
    obtenido="$(curl -fsS "$url/assets/fonts/$fuente" | git hash-object --stdin)"
    test "$esperado" = "$obtenido"
done
echo "Fuentes locales: bytes de ambas fuentes verificados."
test "$(curl -fsS "$url/api/saludo")" = "Backend activo"
catalogo="$(curl -fsS "$url/api/cotizador/catalogo")"
zona="$(json_qa catalogo <<<"$catalogo")"
servicios="$(curl -fsS "$url/api/cotizador/servicios?tipo=REPARACION")"
producto="$(json_qa servicio <<<"$servicios")"
payload="$(json_qa payload "$zona" "$producto" </dev/null)"
codigo="$(curl -fsS -H 'Content-Type: application/json' -d "$payload" "$url/api/cotizador/cotizaciones" | json_qa codigo)"

# El registro debe sobrevivir a la eliminación y recreación de contenedores.
dc down
arrancar
curl -fsS "$url/api/cotizador/cotizaciones/$codigo" | json_qa persistencia "$codigo"
echo "OK ($modo): SQL Server real, API, frontend, transacciones y persistencia tras recrear contenedores."
