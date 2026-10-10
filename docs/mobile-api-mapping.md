# QualiTrack Mobile — API Mapping

Fuente de verdad: `qualitrack-platform` v1.0.0 (rama `develop`, commit `a0e2ecc`).
Todas las rutas son relativas a `API_BASE_URL` (p. ej. `http://10.0.2.2:8080`) y comienzan con `/api/v1`.

La v1.0.0 del backend reorganizó la API: los recursos cuelgan de `laboratories/{laboratoryId}` y, en la mayoría de los casos, de `environments/{environmentId}`; las acciones de ciclo de vida son `POST` de acciones (`/releases`, `/acknowledgements`, …) en lugar de `PATCH` de estado. La app descubre los entornos con `GET /laboratories/{laboratoryId}/environments` (`EnvironmentDirectory`) y obtiene el entorno de un equipo, lote o material de sus propios recursos (`environmentId`).

## Reglas transversales verificadas en el backend

| Tema | Comportamiento real |
|---|---|
| Autenticación | `POST /api/v1/authentication/sign-in` es público. Todo lo demás exige `Authorization: Bearer <JWT>`. Sin token → `401`. |
| JWT | Claims: `sub`, `userId`, `laboratoryId`, `roles`, `exp`. Expira a los **7 días** (`authorization.jwt.expiration.days=7`). |
| Tenant | Cada ruta con `{laboratoryId}` se valida contra el laboratorio del token (`@tenantAccess`) → `403` si no coincide. |
| Onboarding | Si `GET /users/me/onboarding` no devuelve `nextStep = READY`, los endpoints operativos responden `403 {code: ONBOARDING_REQUIRED, nextStep}`. `nextStep ∈ {SUBSCRIPTION, LABORATORY, READY}`. |
| Roles | `ROLE_ADMIN`, `ROLE_QA_MANAGER`, `ROLE_LAB_OPERATOR`. Liberar y rechazar lotes exige `ROLE_QA_MANAGER` o `ROLE_ADMIN` en el servidor. |
| Errores | `ErrorResource {code, message, details}`. `VALIDATION_ERROR`→400, `*_NOT_FOUND`→404, `*_CONFLICT`→409, `UNEXPECTED_ERROR`→500, `ACCESS_DENIED`→403. |
| Paginación | No existe en ningún endpoint. Todas las listas son completas. |
| Fechas | Alertas y eventos guardan `timestamp` como **String** ISO-8601. Las lecturas de telemetría usan `measuredAt` y el filtro `from`/`to` acepta ISO-8601 con offset (por defecto, últimas 24 h). |

## Enums reales

| Enum | Valores |
|---|---|
| AlertStatus | `UNRESOLVED`, `ACKNOWLEDGED`, `RESOLVED` |
| AlertSeverity | `LOW`, `WARNING`, `CRITICAL` |
| BatchStatus | `PENDING`, `IN_PROGRESS`, `RELEASED`, `REJECTED` |
| TelemetryStatus | `OPERATIONAL`, `WARNING`, `CRITICAL`, `OFFLINE` |
| EquipmentStatus | `OPERATIONAL`, `MAINTENANCE`, `OUT_OF_SERVICE`, `INACTIVE` (se expone como String) |
| MaintenanceType | `PREVENTIVE`, `CORRECTIVE`, `CALIBRATION`, `INSPECTION`, `OTHER` |
| RawMaterialBatchStatus (recepción) | `QUARANTINED`, `RELEASED`, `OBSERVED`, `REJECTED` |
| SubscriptionStatus | `ACTIVE`, `INACTIVE`, `PENDING_PAYMENT`, `CANCELLED`, `EXPIRED` |
| PaymentStatus | `PENDING`, `PAID`, `FAILED`, `CANCELLED`, `REFUNDED` |
| BillingCycle | `MONTHLY`, `YEARLY` |
| PlanCode | `FREE`, `BASIC`, `PROFESSIONAL`, `ENTERPRISE` |
| KpiMetricStatus | `ON_TRACK`, `AT_RISK`, `CRITICAL`, `UNKNOWN` |
| AuditAction | `CREATE`, `UPDATE`, `DELETE`, `RELEASE`, `REJECT`, `APPROVE`, `REGISTER`, `REMOVE`, `EXPORT`, `GENERATE`, `LOGIN`, `LOGOUT`, `SYSTEM` |
| ReportType | `BATCH_TRACEABILITY`, `COMPLIANCE_PERIOD`, `EQUIPMENT_LOG`, `KPI_SUMMARY` |
| TrendDirection | `INCREASING`, `DECREASING`, `STABLE` |
| ComplianceEventType | `DEVIATION_ALERT_CREATED`, `DEVIATION_ALERT_ACKNOWLEDGED`, `DEVIATION_ALERT_RESOLVED`, `NOTIFICATION_PREFERENCE_UPDATED`, `BATCH_BLOCKED`, `BATCH_RELEASED`, `BATCH_REJECTED`, `RAW_MATERIAL_LOW_STOCK`, `EQUIPMENT_CALIBRATION_EXPIRED`, `EQUIPMENT_DEVIATION_DETECTED` |

## Tabla de mapeo

“Any” = cualquier rol autenticado cuyo laboratorio coincida. “QA/ADMIN (UI)” = la app sólo muestra la acción a `ROLE_QA_MANAGER` / `ROLE_ADMIN`.
`{lab}` = `{laboratoryId}`, `{env}` = `{environmentId}`.

| Mobile module | Screen | Backend endpoint | HTTP method | Read/Action | Role |
|---|---|---|---|---|---|
| iam | Sign In | `/authentication/sign-in` | POST | Action (login) | Public |
| iam | Splash / Session gate | `/users/me/onboarding` | GET | Read | Any |
| iam | Profile | `/users/{userId}` | GET | Read | Any (propio usuario) |
| laboratory | Command Center / Profile / Drawer header | `/laboratories/{lab}` | GET | Read | Any |
| laboratory | Environments (interno) | `/laboratories/{lab}/environments` | GET | Read | Any |
| laboratory | Products (catálogo = unión de los entornos) | `/laboratories/{lab}/environments/{env}/products` | GET | Read | Any |
| equipment | Equipment list | `/laboratories/{lab}/equipments` | GET | Read | Any |
| equipment | Equipment detail | `/laboratories/{lab}/equipments/{equipmentId}` | GET | Read | Any |
| equipment | Equipment detail → Maintenance | `/laboratories/{lab}/environments/{env}/equipments/{equipmentId}/maintenance-records` | GET | Read | Any |
| equipment / tracking | Equipment detail → BPM limits | `/laboratories/{lab}/equipments/{equipmentId}/bpm-configs` | GET | Read | Any |
| tracking | Telemetry Dashboard / Equipment list → connection status | `/laboratories/{lab}/environments/{env}/devices/{deviceId}/telemetry-status` | GET | Read (polling 15 s) | Any |
| tracking | Telemetry Dashboard / Raw log / chart and anomalies (container monitor) | `/laboratories/{lab}/environments/{env}/container-monitors/{deviceId}/telemetry-measurements?from&to` | GET | Read | Any |
| tracking | Telemetry Dashboard / Raw log / chart and anomalies (environmental device) | `/laboratories/{lab}/environments/{env}/telemetry-measurements?from&to` | GET | Read | Any |
| compliance | Compliance Alerts (unión de los entornos) | `/laboratories/{lab}/environments/{env}/deviation-alerts` | GET | Read | Any |
| compliance / batch | Batch detail → Alerts (alertas del laboratorio filtradas por `batchId`) | `/laboratories/{lab}/environments/{env}/deviation-alerts` | GET | Read | Any |
| compliance | Deviation Details | `/deviation-alerts/{alertId}` | GET | Read | Any |
| compliance | Deviation Details → Acknowledge | `/deviation-alerts/{alertId}/acknowledgements` | POST | Action (review) | QA/ADMIN (UI) |
| compliance | Deviation Details → Resolve (body `{resolutionNotes}`) | `/deviation-alerts/{alertId}/resolutions` | POST | Action (review) | QA/ADMIN (UI) |
| compliance | Equipment detail → Compliance timeline | `/laboratories/{lab}/equipments/{equipmentId}/compliance-events` | GET | Read | Any |
| compliance | Batch detail → Compliance timeline | `/batches/{batchId}/compliance-events` | GET | Read | Any |
| batch | Production Batches | `/laboratories/{lab}/batches` | GET | Read | Any |
| batch | Batch Detail → General Information | `/laboratories/{lab}/environments/{env}/products/{productId}/batches/{batchId}` | GET | Read | Any |
| batch | Batch Detail → Raw Materials Used | `/laboratories/{lab}/environments/{env}/products/{productId}/batches/{batchId}/traceability` (`rawMaterials`) | GET | Read | Any |
| batch | Release Batch (body `{releaseDate, notes}`) | `/laboratories/{lab}/environments/{env}/products/{productId}/batches/{batchId}/releases` | POST | Action (review) | QA/ADMIN |
| batch | Reject Batch (body `{rejectionDate, reason}`) | `/laboratories/{lab}/environments/{env}/products/{productId}/batches/{batchId}/rejections` | POST | Action (review) | QA/ADMIN |
| inventory | Raw Materials Inventory (unión de los entornos) | `/laboratories/{lab}/environments/{env}/raw-materials` | GET | Read | Any |
| inventory | Material detail → Receipts | `/laboratories/{lab}/environments/{env}/raw-materials/{materialId}/batches` | GET | Read | Any |
| inventory | Material detail → Movements | `/laboratories/{lab}/environments/{env}/raw-materials/{materialId}/movements` | GET | Read | Any |
| reporting | KPI Dashboard (conteos operativos y resumen de lecturas) | `/laboratories/{lab}/kpi-dashboards` | GET | Read (calculado en cada petición: sin `id` ni `overallHealthScore`; 404 ⇒ empty state) | Any |
| reporting | Report history | `/laboratories/{lab}/reports` | GET | Read | Any |
| reporting | Equipment detail → Deviation trends (filtradas por equipo) | `/laboratories/{lab}/environments/{env}/deviation-trends` | GET | Read | Any |
| reporting | Equipment detail → Audit log | `/laboratories/{lab}/equipments/{equipmentId}/audit-logs?dateFrom&dateTo` | GET | Read | Any |
| reporting | Batch detail → Audit log | `/batches/{batchId}/audit-logs?dateFrom&dateTo` | GET | Read | Any |
| subscription | Billing Summary → Current plan | `/laboratories/{lab}/subscriptions?status=ACTIVE` | GET | Read (lista vacía ⇒ sin suscripción activa) | Any |
| subscription | Billing Summary → Subscription history | `/laboratories/{lab}/subscriptions` | GET | Read | Any |
| subscription | Billing Summary → Payments | `/subscriptions/{subscriptionId}/payments` | GET | Read | Any |
| subscription | Billing Summary → Plan limits | `/subscription-plans` | GET | Read | Any |
| command_center | Command Center | (composición de UI) | GET | Read | Any |

## Endpoints existentes que mobile NO usará (y por qué)

| Endpoint | Motivo |
|---|---|
| `POST /authentication/sign-up`, password recovery y cambio de contraseña | Registro y credenciales permanecen en Web. |
| `POST/PUT /laboratories`, `…/environments`, `…/staff`, `…/devices` | Configuración y administración en Web. |
| `POST` de equipos, mantenimiento, BPM, productos, lotes, usos de materia prima/equipos/personal, materias primas, recepciones y reviews | Registro y operación en Web. |
| `POST …/telemetry-measurements`, `…/actuation-events`, `PUT …/environmental-profile/*` | Adquisición IoT (Edge). El móvil nunca publica telemetría. |
| `GET …/environmental-profile`, `…/actuation-events` | Fuera de alcance en esta etapa. |
| `POST …/deviation-alerts`, `POST /deviation-alerts/{id}/email-notifications` | Las alertas las genera el sistema. |
| Notificaciones y preferencias (`/users/me/notifications`, `NotificationPreference`) | No hay push real todavía. |
| `GET /users`, `PUT /users/{id}/roles/{role}`, `GET /roles` | Administración de usuarios en Web. |
| Generación de reportes (`POST …/compliance-reports`, `…/inventory/reports`, `…/log-reports`, `/batches/{id}/reports`), `GET /reports/{id}` y `/content` | Se generan y descargan en Web; el historial sí se muestra. |
| `POST /subscription-checkout-sessions`, cancelaciones, `POST /stripe/webhooks` | Checkout, cancelación y Stripe permanecen en Web. |
| `GET …/inventory/legacy-materials`, `…/raw-material-usages` legados | Catálogo y usos legados; Inventory es la fuente actual. |

## Brechas detectadas (no se modifica el backend)

1. **Acknowledge/resolve de alertas**: el backend usa el usuario autenticado, pero no restringe por rol. La app los muestra sólo a `ROLE_QA_MANAGER`/`ROLE_ADMIN`; esto no sustituye la autorización del servidor.
2. **Agregación por entorno**: no existen listados por laboratorio de alertas, productos ni materias primas; la app consulta cada entorno (`EnvironmentDirectory`) y los une.
3. **Alertas por lote**: no existe `GET /batches/{id}/deviation-alerts`; se filtran las alertas del laboratorio por `batchId`.
4. **Anomalías de telemetría**: ya no hay un campo `isAnomaly`; se consideran anomalías las lecturas con `state` `WARNING` o `CRITICAL`. Las lecturas sin valor numérico (por ejemplo `RFID_TAG`) no se grafican.
5. **Estado de telemetría**: sólo existe `CONNECTED` / `REQUIRES_REVIEW` (la app lo muestra como operativo / sin conexión). Un equipo sin dispositivo IoT (`deviceType` nulo) no tiene telemetría.
6. **Métricas del mockup sin fuente** (latencia en ms, “Sampling rate”, distribución porcentual): se omiten; `overallHealthScore` sólo se muestra si el KPI dashboard lo trae (el backend lo calcula en cada petición y hoy lo devuelve nulo).
7. **Recibo PDF de pagos**: no hay endpoint → no se muestra.
