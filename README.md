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
│       ├── application.properties          <- Configuración SQL Server, JWT, Swagger
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

## 3. Instrucciones de arranque y ejecución

El motor único de persistencia es **Microsoft SQL Server 2022 Express (16.x)**. Docker ejecuta Angular, Spring Boot y SQL Server en contenedores independientes. El servicio auxiliar `db-init` utiliza el modelo y los datos del script original con inicialización no destructiva; termina con código 0 y no es un servidor permanente.

| Archivo | Cuándo utilizarlo | Referencia |
|---|---|---|
| `compose.yaml` | Computadora personal, desarrollo diario y pruebas habituales. | Docker Engine y Compose v2 actualizados. |
| `compose.legacy.yaml` | Computadoras de la universidad, laboratorio, sustentación o contingencia. | Docker Desktop 4.34.0 / Engine 27.2.0 / Compose 2.29.2 (objetivo sujeto a pruebas). |

No hay que degradar Docker en equipos actualizados. Ambas configuraciones utilizan el mismo código, SQL Server, puertos y volumen. Requieren contenedores Linux en un equipo x86-64/amd64 y al menos 2 GB de memoria para el motor; se recomienda asignar al menos 4 GB a Docker para el conjunto y más durante la compilación. No se garantiza compatibilidad con Compose v1 ni con equipos ARM.

### 3.1. Configurar credenciales locales

En la raíz, copia `.env.example` a `.env`:

```powershell
Copy-Item .env.example .env
notepad .env
```

Asigna dos claves fuertes y distintas, con mayúsculas, minúsculas, números y símbolos. Para `DB_CLAVE` se admiten 12-128 caracteres: letras, números y símbolos `_!@%+=.-` (sin espacios, comillas ni dólar), por seguridad de la sustitución de sqlcmd. Si cambias las claves de una instancia ya inicializada, debes rotarlas también en SQL Server; editar .env no cambia las credenciales persistentes.

`sa` solo se utiliza para inicialización y diagnóstico; Spring Boot utiliza `globalfrio_backend` con permisos de lectura y escritura, no DDL. No subas .env a Git. Acepta las condiciones de licencia de Microsoft antes del arranque; Compose fija ACCEPT_EULA=Y.

### 3.2. Computadora personal (desarrollo)

```powershell
docker compose config --quiet
docker compose up -d --build --wait
docker compose ps -a
```

### 3.3. Computadora de la universidad (laboratorio o sustentación)

```powershell
docker version
docker compose version
docker compose -f compose.legacy.yaml config --quiet
docker compose -f compose.legacy.yaml up -d --build
docker compose -f compose.legacy.yaml ps -a
```

Comprueba que sqlserver, backend y frontend estén saludables y que db-init haya terminado con código 0. Para diagnosticar errores: `docker compose -f compose.legacy.yaml logs --tail 100`.

| Servicio | Dirección |
|---|---|
| Frontend | http://localhost:4200 |
| Backend | http://localhost:8080/api/saludo |
| Swagger | http://localhost:8080/swagger-ui/index.html |
| SQL Server | localhost,1433; base globalfrio_db; usuario globalfrio_backend |

Consulta SQL real con SSMS o sqlcmd. Ejemplo usando la variante moderna (solicita la contraseña):

```powershell
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U globalfrio_backend -C -d globalfrio_db
```

```sql
SELECT * FROM productos;
SELECT * FROM cotizacion;
GO
```

Para detener el programa: `docker compose down` (o el mismo comando con `-f compose.legacy.yaml`). El volumen `sqlserver_data` conserva los datos; no uses `down -v` con datos de trabajo. Ambas variantes comparten el volumen si se ejecutan desde la misma carpeta con el mismo nombre de proyecto; detén una antes de iniciar la otra. Si tienes un SQL Server instalado localmente y ocupa el puerto 1433, cambia `SQLSERVER_PORT` en .env (el contenedor conserva el 1433 interno).

### 3.4. Contingencia sin Internet

En tu computadora con Internet y .env configurado:

```powershell
docker compose -f compose.legacy.yaml pull sqlserver db-init
docker compose -f compose.legacy.yaml build backend frontend
docker image save -o globalfrio-universidad.tar mcr.microsoft.com/mssql/server:2022-latest globalfrio-backend:universidad globalfrio-frontend:universidad
```

Lleva el TAR y una copia del repositorio (sin tus credenciales). En la universidad, configura un .env propio:

```powershell
docker image load -i globalfrio-universidad.tar
docker compose -f compose.legacy.yaml up -d --no-build --pull never
docker compose -f compose.legacy.yaml ps -a
```

El frontend incluye localmente Plus Jakarta Sans y Material Icons con sus licencias. La fase de compilación Angular del Dockerfile se ejecuta sin red; obtener las imágenes base y ejecutar `npm ci` o descargar dependencias Maven durante una reconstrucción puede seguir requiriendo Internet. Los mapas o enlaces externos conservan sus propios requisitos de conectividad.

El TAR no contiene los datos persistentes de una base previa: se crea una nueva con los datos iniciales. Para trasladar cotizaciones exporta un respaldo de SQL Server aparte. Prueba el procedimiento antes de la sustentación.

### 3.5. Pruebas de integración y persistencia

GitHub Actions configura dos entornos: versiones actuales y Engine 27.2.0 / Compose 2.29.2 / Buildx 0.16.2. En Linux, WSL o Git Bash con Docker, Git, curl y openssl disponibles (no requiere jq ni Node.js en el host; utiliza Node 22 dentro de un contenedor sin red para validar JSON):

```bash
bash scripts/verificar-docker.sh moderna
bash scripts/verificar-docker.sh universidad
```

Cada ejecución usa credenciales y volúmenes desechables aislados. Comprueba SQL Server por JDBC, ejecuta JUnit (catálogo, cotizaciones y rollback), verifica la API y el frontend y guarda una cotización que debe sobrevivir a la recreación de contenedores. Consulta los resultados del workflow antes de afirmar la compatibilidad real. No ejecutes las pruebas de escritura contra tu base de trabajo.

### 3.6. Ejecución nativa con SQL Server

Para utilizar una instancia SQL Server existente sin Docker, configura TCP/IP y la base `globalfrio_db` siguiendo [la guía de BD](backend/database/LEEME_BD.md). El script manual [BD_GLOBALFRIO.sql](database/BD_GLOBALFRIO.sql) borra y recrea tablas: no lo ejecutes contra una base con datos de trabajo. El backend valida el esquema, no lo crea ni modifica. No se migran datos externos automáticamente al volumen Docker.

En PowerShell, exporta DB_CLAVE y, si corresponde, DB_URL o DB_USUARIO (también puedes usar backend/bd-local.properties). Después ejecuta:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

En otra terminal, desde la raíz:

```powershell
cd frontend
npm ci
npm start
```

El frontend de desarrollo mantiene la URL localhost:8080/api; la compilación de producción en Docker usa /api con Nginx.

---

## 4. Preservación del Trabajo Previo y Migración

Todo el avance visual, contenido textual, catálogo de servicios, galería fotográfica y datos de contacto de Edgar Sabalu preparados inicialmente en HTML/JS vanilla han sido **rescatados y transformados al 100%** en componentes modulares, servicios reactivos con RxJS y estilos SCSS de Angular. Los archivos fuente del prototipo estático inicial permanecen archivados y disponibles en [frontend/prototipo-vanilla/](file:///C:/Users/Orlando/Desktop/globalfrio/frontend/prototipo-vanilla/) con su trazabilidad de control de versiones intacta.
