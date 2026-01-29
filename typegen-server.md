# TypeGen API

<p align="center">
  <img src="docs/assets/logo.jpg" width="100" height="100" alt="TypeGen Logo" />
</p>

<p align="center">
  <strong>Core code generation and schema engine for TypeGen</strong><br/>
  Fast • Secure • Extensible
</p>

<p align="center">
  <img src="https://img.shields.io/badge/go-1.25+-00ADD8?logo=go&logoColor=white" />
  <img src="https://img.shields.io/badge/platform-linux%20|%20macOS%20|%20windows-blue" />
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" />
  <img src="https://img.shields.io/badge/status-production--ready-success" />
</p>

---

### **TypeGen API (`typegen-api`)**

The **TypeGen API** is the core backend service of the TypeGen platform. It is responsible for database schema
introspection, validation, and deterministic code generation across supported languages and styles. The API exposes
generation capabilities used by the CLI and Dashboard while enforcing strict option schemas, security controls, and
runtime validation.

> **Important:**
> The TypeGen API is **not intended to be run as a standalone service**.
> Its lifecycle, configuration, and runtime environment are fully managed by **TypeGenCLI (`typegenctl`)**, which acts
> as the control
> plane for the entire TypeGen ecosystem.

| How to use | Description                                                                  |
|:-----------|:-----------------------------------------------------------------------------|
| TypeGenCLI | [TypeGenCLI GitHub](https://github.com/khanalsaroj/typegenctl).              |
| Dashboard  | [TypeGen-Dashboard GitHub](https://github.com/khanalsaroj/typegen-dashboard) |

## ✨ Features

- **Current Support Database Connection**: MySQL/Mariadb and PostgreSQL.
- **Code Generation**:
    - **Typescript**: DTOs and Zod schemas.
    - **Java**: Records and DTOs.
    - **Mappers**: Java XML and Annotation-based mappers.
- **Security**: Rate limiting, and CORS support.
- **Health Monitoring**: Integrated health check endpoints.

---

## 🐋 Docker Image

Pre-built Docker images are available for this project and can be pulled from the registry:

```bash
docker pull ghcr.io/khanalsaroj/typegen-api:latest
```

### 📂 Project Structure

```text
├── cmd/
│   └── api/                # Application entry point
├── data/                   # SQLite database files
├── internal/
│   ├── config/             # Configuration loading (Viper)
│   ├── domain/             # Domain models and interfaces
│   ├── infrastructure/     # DB connectors (MySQL, Postgres)
│   ├── middleware/         # Gin middlewares (CORS, Logger, Rate Limit)
│   ├── modules/            # Business logic by module
│   │   ├── connection/     # Connection management
│   │   ├── gentype/        # Type generation logic
│   │   ├── health/         # Health check logic
│   │   └── mapper/         # Mapper generation logic
│   ├── pkg/                # Shared utilities (Crypto, Logger, Response)
│   ├── query/              # SQL queries
│   └── server/             # HTTP server setup and routing
├── .env.dev                # Development environment variables
├── Dockerfile              # Multi-stage Docker build
└── go.mod                  # Go module definition
```

## 🌐 API Endpoints (Summary)

### 1. `GET /api/v1/health` – Health Check

**Response:**

```json
{
  "status": "ok",
  "version": "v1.2.3",
  "uptime": 172800,
  "database": {
    "connected": true,
    "latency": 12
  }
}
```

**HTTP Status:** `200 OK`

---

### 2. `POST /api/v1/connections/test` – Create a New DB Connection

**Request Body Example:**

```json
{
  "dbType": "postgres",
  "host": "localhost",
  "port": 5432,
  "username": "admin",
  "password": "securepassword",
  "schemaName": "public",
  "databaseName": "mydb"
}
```

**Response Example:**

```json
{
  "connectionId": 123,
  "message": "Connection established successfully",
  "success": true,
  "pingMs": 15,
  "tablesFound": 3,
  "sizeMb": 42.7,
  "tables": [
    {
      "name": "users",
      "columnCount": 12
    },
    {
      "name": "orders",
      "columnCount": 8
    }
  ]
}
```

**HTTP Status:** `200 OK`

---

### 3. `GET /api/v1/connections` – List All Connections

**Response Example:**

```json
[
  {
    "connectionId": 101,
    "name": "main-db",
    "dbType": "postgres",
    "host": "localhost",
    "port": 5432,
    "databaseName": "mydb",
    "schemaName": "public",
    "username": "admin"
  },
  {
    "connectionId": 102,
    "name": "analytics-db",
    "dbType": "mysql",
    "host": "db.example.com",
    "port": 3306,
    "databaseName": "analytics",
    "schemaName": "default",
    "username": "root"
  }
]

```

**HTTP Status:** `200 OK`

---

### 4. `POST /api/v1/type` – Generate Code Types

**Request Body Example:**

> **Note:**
> The `options` object is dynamic.
> Its available fields differ depending on the chosen `language` and `style`, as each combination exposes its own configuration options.
> For the full list of supported options, see the documentation [here](https://github.com/khanalsaroj/typegen-dashboard).

```json
{
  "connectionId": 102,
  "options": {
    "getter": true,
    "setter": true,
    "noArgsConstructor": true,
    "allArgsConstructor": true,
    "builder": true,
    "data": true,
    "swaggerAnnotations": true,
    "serializable": true,
    "jacksonAnnotations": true,
    "extraSpacing": true
  },
  "prefix": "Foo",
  "suffix": "Response",
  "style": "DTO",
  "language": "java",
  "tableNames": [
    "users",
    "orders"
  ]
}
```

**Response Example:**

```json
"generated message"
```

**HTTP Status:** `200 OK`

---

### 5. `POST /api/v1/mapper` – Generate Mappers

**Request Body Example:**

```json
{
  "connectionId": 123,
  "options": {
    "allCrud": true
  },
  "prefix": "Db",
  "suffix": "Type",
  "style": "struct",
  "language": "go",
  "tableNames": [
    "users",
    "orders"
  ]
}
```

**Response Example:**

```json
"generated message"
```

**HTTP Status:** `200 OK`

---

### 🔍 Contact

- **GitHub Issues:** [Report bugs and feature requests](https://github.com/sarojkhanal/typegenctl/issues)
- **Developer:** Khanal Saroj (waytosarojkhanal@gmail.com)

