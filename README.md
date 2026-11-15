# Global Frío — Solución Web y Sistema Distribuido HVAC

Proyecto desarrollado para el curso **Soluciones Web y Aplicaciones Distribuidas (SIST1402A)** en la **Universidad Privada del Norte (UPN)**, Facultad de Ingeniería, Periodo 2026-2.

* **Cátedra:** Ing. Mg. Carlos Alberto Ponte Ramírez  
* **Alineación Estratégica:** ODS 09 (Industria, Innovación e Infraestructura)  
* **Dominio:** Sistema integral de climatización, mantenimiento preventivo y comercialización de equipos HVAC para **Global Frío** (Callao / Ventanilla, Perú).

---

## 1. Arquitectura del Repositorio (Monorepo Desacoplado)

Siguiendo las directivas de arquitectura de software y la Sección 6 de [AGENTS.md](file:///C:/Users/Orlando/Desktop/globalfrio/AGENTS.md), el proyecto está organizado de manera modular e independiente:

```text
globalfrio/
├── AGENTS.md                               <- Especificación canónica y lista blanca técnica general
├── README.md                               <- Guía de instalación, arquitectura y comandos de arranque
├── .gitignore                              <- Filtro de exclusiones monorepo (Node, Angular, Maven, IDEs)
├── arquitectura_n_capas.*                  <- Diagrama de arquitectura física y lógica N-Capas
├── autenticacion_jwt_cors.*                <- Diagrama de flujo de autenticación stateless con JWT y CORS
│
├── backend/                                <- Proyecto Backend (Java 17/21 + Spring Boot 3 + Maven)
│   ├── AGENTS.md                           <- Especificación técnica y requerimientos exclusivos de Backend
│   ├── pom.xml                             <- Lista blanca estricta de dependencias Maven
│   ├── mvnw / mvnw.cmd                     <- Maven Wrapper (v3.9.9)
│   ├── src/main/java/pe/upn/sist1402a/
│   │   ├── config/                         <- SecurityConfig, CorsConfig, OpenApiConfig
│   │   ├── controller/                     <- SaludoController (/api/saludo), InicioViewController
│   │   ├── service/ & service/impl/        <- Lógica de negocio (Singleton / Service Pattern)
│   │   ├── repository/                     <- ProductoRepository (JpaRepository + JPQL parametrizado)
│   │   ├── entity/                         <- Producto (@Entity, Bean Validation, @Transient)
│   │   ├── dto/                            <- DTOs estandarizados (ErrorResponseDto, SaludoResponseDto)
│   │   └── exception/                      <- GlobalExceptionHandler (@RestControllerAdvice)
│   └── src/main/resources/
│       ├── application.properties          <- Configuración MySQL (predeterminado) / SQL Server opcional, JWT, Swagger
│       └── templates/                      <- Plantilla Thymeleaf para contraste server-side vs REST
│
└── frontend/                               <- Proyecto Frontend (Angular 18 SPA + TypeScript + SASS)
    ├── AGENTS.md                           <- Especificación técnica y requerimientos exclusivos de Frontend
    ├── package.json                        <- Dependencias oficiales autorizadas (Angular, Bootstrap 5, Material)
    ├── angular.json                        <- Configuración de compilación y workspace Angular CLI
    ├── tsconfig.json                       <- Configuración estricta de TypeScript
    ├── src/
    │   ├── index.html                      <- HTML raíz con tipografías Google Fonts (Barlow)
    │   ├── styles.scss                     <- Sistema de diseño industrial (blueprint, duotone, dark/light)
    │   ├── assets/                         <- Fotografías de proyectos y branding oficial de Global Frío
    │   ├── environments/                   <- Variables de entorno (API URL: http://localhost:8080/api)
    │   └── app/
    │       ├── core/                       <- AuthGuards y JWT Interceptor (plantillas preparadas)
    │       ├── models/                     <- Modelos tipados (Servicio, Trabajo, ItemMantenimiento, RedSocial)
    │       ├── services/                   <- ConfigService, AmbienteService (RxJS), ServiciosService, ModalService
    │       └── components/                 <- Header, Hero, Servicios, Trabajos, Mantenimiento, Ubicacion, Footer, Modal
    └── prototipo-vanilla/                  <- Prototipo estático original preservado con su historial git intacto
```

---

## 2. Sistema de Especificaciones Técnicas (3 Archivos AGENTS.md)

Para garantizar la autonomía modular y el cumplimiento de la lista blanca técnica tanto por desarrolladores humanos como por agentes de inteligencia artificial (Google Jules, Antigravity CLI), se disponen tres especificaciones:

1. **[AGENTS.md (Raíz)](file:///C:/Users/Orlando/Desktop/globalfrio/AGENTS.md):** Especificación canónica global que rige todo el proyecto, detallando el sílabo de 16 semanas, los hitos T1, T2, T3 y Final, las reglas mandatarias y la arquitectura compartida.
2. **[backend/AGENTS.md](file:///C:/Users/Orlando/Desktop/globalfrio/backend/AGENTS.md):** Ficha técnica especializada para la capa de servicios y persistencia (Java, Spring Boot, JPA, EntityManager, JpaRepository, Spring Security, JWT, REST y OpenAPI).
3. **[frontend/AGENTS.md](file:///C:/Users/Orlando/Desktop/globalfrio/frontend/AGENTS.md):** Ficha técnica especializada para la Single Page Application (Angular, TypeScript, SASS, Bootstrap 5, Angular Material, RxJS, Reactive Forms y Route Guards).

---

## 3. Instrucciones de Arranque y Ejecución

### 3.1. Arranque completo con Docker Compose (recomendado)

Requiere Docker Desktop con contenedores Linux o Docker Engine con Docker Compose v2. Hay dos configuraciones para distintos entornos, con el mismo código, esquema MySQL, credenciales y puertos:

| Configuración | Cuándo utilizarla | Referencia |
|---|---|---|
| `compose.yaml` | Computadora personal, desarrollo diario, actualización de dependencias y pruebas habituales. | Docker y Compose actualizados. |
| `compose.legacy.yaml` | Computadoras de la universidad, laboratorio, sustentación o contingencia en un equipo con Docker de 2024. | Docker Desktop 4.34.0 / Engine 27.2.0 / Compose 2.29.2 (objetivo de compatibilidad). |

La variante universitaria no obliga a instalar Docker antiguo: también se puede usar con versiones modernas. No se considera compatible con Compose v1 ni con motores anteriores sin pruebas específicas. No se recomienda degradar Docker en equipos personales ni exponer esta configuración de desarrollo a Internet. [Referencia oficial de versiones](https://docs.docker.com/desktop/release-notes/#4340).

Copia `.env.example` a `.env` (PowerShell: `Copy-Item .env.example .env`; Linux/macOS: `cp .env.example .env`). Edita `.env` y asigna contraseñas fuertes y distintas a `MYSQL_ROOT_PASSWORD` y `MYSQL_PASSWORD`.

**Computadora personal (desarrollo):**

```bash
docker compose config --quiet
docker compose up -d --build --wait
docker compose ps
```

**Computadora de la universidad (laboratorio o sustentación):**

Comprueba primero las versiones y que Docker use contenedores Linux.

```powershell
docker version
docker compose version
docker compose -f compose.legacy.yaml config --quiet
docker compose -f compose.legacy.yaml up -d --build
docker compose -f compose.legacy.yaml ps
```

Espera hasta ver los tres servicios saludables (`healthy`). Si hay errores, ejecuta `docker compose -f compose.legacy.yaml logs --tail 100`. Las dos variantes conservan los mismos endpoints:

- Angular: http://localhost:4200 (proxy /api del mismo origen).
- Backend: http://localhost:8080/api/saludo y http://localhost:8080/swagger-ui/index.html.
- MySQL 8.4: puerto local 3306, base y usuario de .env.
- Consulta SQL: `docker compose exec mysql mysql -u globalfrio_backend -p globalfrio_db -e "SELECT * FROM productos;"`.

`docker compose down` conserva el volumen. **No uses `down -v` sobre datos de trabajo**. Los scripts de `database/mysql/` se aplican solo en un volumen nuevo. Hibernate valida el esquema. No se trasladan automáticamente datos de SQL Server.

#### Cambio de configuración y contingencia sin Internet

Desde la misma carpeta y con el mismo nombre de proyecto Compose, ambas variantes comparten el volumen `mysql_data`. No las ejecutes simultáneamente sobre los mismos puertos. Detén la configuración activa con `docker compose down` o `docker compose -f compose.legacy.yaml down` antes de cambiar; nunca añadas `-v` a esos comandos si quieres conservar datos.

Para preparar una demostración sin conexión, en tu computadora personal con Internet, desde la raíz y con las credenciales de .env configuradas:

```powershell
docker compose -f compose.legacy.yaml pull mysql
docker compose -f compose.legacy.yaml build backend frontend
docker image save -o globalfrio-universidad.tar mysql:8.4 globalfrio-backend:universidad globalfrio-frontend:universidad
```

Lleva el archivo tar y una copia del repositorio en USB (sin contraseñas personales). Las imágenes deben corresponder al sistema Linux y arquitectura del equipo destino (habitualmente amd64). En la universidad crea un .env propio, copia el tar a la raíz y ejecuta:

```powershell
docker image load -i globalfrio-universidad.tar
docker compose -f compose.legacy.yaml up -d --no-build --pull never
docker compose -f compose.legacy.yaml ps
```

Las imágenes no incluyen las cotizaciones ya guardadas: para una base nueva se usan los scripts SQL del repositorio. Comprueba este procedimiento antes de la sustentación y conserva el volumen o haz un respaldo aparte si necesitas datos de trabajo. No guardes el tar en Git ni publiques credenciales.

### 3.2. Pruebas de integración (MySQL real)

El workflow de GitHub Actions prueba ambas configuraciones por separado: herramientas modernas del runner y versiones universitarias fijadas (Engine 27.2.0 / Compose 2.29.2 / Buildx 0.16.2). Consulta sus resultados antes de afirmar que la compatibilidad está validada. En Linux, WSL o Git Bash con Docker, curl, jq y openssl disponibles, se puede repetir la prueba con volúmenes desechables:

```bash
bash scripts/verificar-docker.sh moderna
bash scripts/verificar-docker.sh universidad
```

Para comprobar las versiones antiguas realmente, ejecuta la segunda variante en un equipo que las tenga instaladas. La prueba comprueba conexión MySQL, JUnit, frontend, API y persistencia tras recrear contenedores.



Usa un proyecto Compose desechable con puerto diferente al de la aplicación:

```powershell
$env:MYSQL_PORT = "3307"
docker compose -p globalfrio-test up -d --wait mysql
docker compose -p globalfrio-test --profile test run --rm --build pruebas
docker compose -p globalfrio-test --profile test down -v
Remove-Item Env:MYSQL_PORT
```

En Bash usa `export MYSQL_PORT=3307` y `unset MYSQL_PORT`. No ejecutes pruebas de escritura sobre la base de trabajo. JDBC comprueba que el motor es MySQL; las pruebas existentes verifican catálogo, guardado y rollback.

### 3.3. Backend (Spring Boot) fuera de Docker

En la variante moderna, ejecuta `docker compose up -d --wait mysql`. En la universidad, ejecuta `docker compose -f compose.legacy.yaml up -d mysql` y verifica que el servicio esté saludable. Exporta `DB_CLAVE` con el valor de `MYSQL_PASSWORD`; si cambiaste puerto, base o usuario ajusta `DB_URL` y `DB_USUARIO`.


El backend utiliza el Maven Wrapper integrado, por lo que **no requiere tener Maven instalado globalmente**.

```bash
# Navegar a la carpeta backend
cd backend

# Iniciar el servidor en modo desarrollo (puerto 8080)
./mvnw spring-boot:run    # En Linux/macOS
.\mvnw.cmd spring-boot:run # En Windows PowerShell
```

* **Endpoint de prueba (Semana 01):** `http://localhost:8080/api/saludo`
* **Swagger UI interactivo:** `http://localhost:8080/swagger-ui/index.html`
* **Vista tradicional Thymeleaf:** `http://localhost:8080/`

---

### 3.4. Frontend (Angular SPA)

Instala las dependencias con `npm ci` antes de iniciar el frontend.

```bash
# Navegar a la carpeta frontend
cd frontend

# Iniciar el servidor de desarrollo Angular (puerto 4200)
npm ci
npm start
# o
npx ng serve -o

# Compilar para producción
npm run build
```

La aplicación se abrirá automáticamente en `http://localhost:4200/` con:
* Barra de navegación adaptativa con alternador de tema claro/oscuro (persistente en `localStorage`).
* Sección Hero con métricas de servicio y marco técnico blueprint.
* Catálogo de servicios HVAC de Global Frío y galería de trabajos reales.
* Checklist semestral de mantenimiento preventivo.
* Ubicación de base operativa en Ventanilla con mapa interactivo y modal accesible de contacto directo.

---

## 4. Preservación del Trabajo Previo y Migración

Todo el avance visual, contenido textual, catálogo de servicios, galería fotográfica y datos de contacto de Edgar Sabalu preparados inicialmente en HTML/JS vanilla han sido **rescatados y transformados al 100%** en componentes modulares, servicios reactivos con RxJS y estilos SCSS de Angular. Los archivos fuente del prototipo estático inicial permanecen archivados y disponibles en [frontend/prototipo-vanilla/](file:///C:/Users/Orlando/Desktop/globalfrio/frontend/prototipo-vanilla/) con su trazabilidad de control de versiones intacta.
