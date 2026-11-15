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

Requiere Docker Desktop con contenedores Linux o Docker Engine con Compose v2.

Copia `.env.example` a `.env` (PowerShell: `Copy-Item .env.example .env`; Linux/macOS: `cp .env.example .env`). Edita `.env` y asigna contraseñas fuertes y distintas a `MYSQL_ROOT_PASSWORD` y `MYSQL_PASSWORD`.

```bash
docker compose config --quiet
docker compose up -d --build --wait
docker compose ps
```

- Angular: http://localhost:4200 (proxy /api del mismo origen).
- Backend: http://localhost:8080/api/saludo y http://localhost:8080/swagger-ui/index.html.
- MySQL 8.4: puerto local 3306, base y usuario de .env.
- Consulta SQL: `docker compose exec mysql mysql -u globalfrio_backend -p globalfrio_db -e "SELECT * FROM productos;"`.

`docker compose down` conserva el volumen. **No uses `down -v` sobre datos de trabajo**. Los scripts de `database/mysql/` se aplican solo en un volumen nuevo. Hibernate valida el esquema. No se trasladan automáticamente datos de SQL Server.

### 3.2. Pruebas de integración (MySQL real)

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

Primero ejecuta `docker compose up -d --wait mysql`. Exporta `DB_CLAVE` con el valor de `MYSQL_PASSWORD`; si cambiaste puerto, base o usuario ajusta `DB_URL` y `DB_USUARIO`.


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
