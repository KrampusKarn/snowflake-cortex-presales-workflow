# Gotenberg on Snowpark Container Services (SPCS)

Run the PDF converter **inside Snowflake** instead of external Docker/Cloud Run. `EXPORT_PROPOSAL` calls the SPCS service endpoint via External Access Integration (EAI).

## Architecture

```
EXPORT_PROPOSAL (Python SP)
    │  EAI egress HTTPS
    ▼
GOTENBERG_PDF_SERVICE (SPCS)
    └── gotenberg/gotenberg:8  →  POST /forms/chromium/convert/html
    │
    ▼
@CLIENT_DOCS/{client}/final/proposal-{run_id}.pdf
```

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| Snowpark Container Services | Enabled on your Snowflake account |
| Role privileges | `CREATE COMPUTE POOL`, `CREATE SERVICE`, `CREATE IMAGE REPOSITORY` |
| Docker (local) | One-time push of Gotenberg image to Snowflake registry |
| `deploy_config.sql` | Copy from `deploy_config.example.sql` |
| `PDF_API_EAI` | Created in `ingest/00_network_rule_and_secrets.sql` |

## Deploy order

### 1. Base config

```sql
!source nexus-agent-templates/deploy_config.sql
!source nexus-agent-templates/ingest/00_network_rule_and_secrets.sql
```

Create `PDF_API_EAI` with a placeholder host if the service does not exist yet — you will `ALTER` the network rule in step 5.

### 2. SPCS infrastructure

```sql
!source nexus-agent-templates/ingest/spcs-gotenberg/00_compute_pool_and_stage.sql
!source nexus-agent-templates/ingest/spcs-gotenberg/01_image_repository.sql
```

Copy `repository_url` from `SHOW IMAGE REPOSITORIES`.

### 3. Push Gotenberg image

```bash
cd nexus-agent-templates/ingest/spcs-gotenberg
chmod +x push_gotenberg_image.sh

# Login to Snowflake image registry
snow spcs image-registry login --database SPS_BUSINESS_INSIGHT --schema NEXUS

# Push image (use repository_url from step 2)
./push_gotenberg_image.sh myorg-myacct.registry.snowflakecomputing.com/sps_business_insight/nexus/gotenberg_repo
```

### 4. Upload service spec to stage

SnowSQL or Snowsight:

```sql
PUT file://gotenberg_service_spec.yaml @SPCS_SPECS/spcs-gotenberg/
  AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

### 5. Create service

```sql
!source nexus-agent-templates/ingest/spcs-gotenberg/02_create_service.sql
```

Wait until ready:

```sql
SELECT SYSTEM$GET_SERVICE_STATUS('GOTENBERG_PDF_SERVICE');
SHOW ENDPOINTS IN SERVICE GOTENBERG_PDF_SERVICE;
```

### 6. Wire endpoint to EAI + EXPORT_PROPOSAL

Edit `03_configure_pdf_endpoint.sql` — set `PDF_SPCS_ENDPOINT` to the `ingress_url` from `SHOW ENDPOINTS`, then:

```sql
!source nexus-agent-templates/ingest/spcs-gotenberg/03_configure_pdf_endpoint.sql
```

This updates:
- `PDF_API_NETWORK_RULE` — allows egress to the SPCS host
- `PIPELINE_CONFIG.PDF_API_BASE_URL` — read by `EXPORT_PROPOSAL`

### 7. Deploy / redeploy export procedure

```sql
!source nexus-agent-templates/ingest/07_export_proposal.sql
```

### 8. Smoke test

```sql
CALL EXPORT_PROPOSAL('<run_id>');
-- expect: export_status = COMPLETED, pdf_created = true

LIST @CLIENT_DOCS/<client>/final/;
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Service stuck STARTING | Check `GET_SERVICE_LOGS('GOTENBERG_PDF_SERVICE', 0, 'gotenberg')` — may need larger compute pool (CPU_X64_L) |
| PDF call times out | Gotenberg cold start; retry or set `AUTO_SUSPEND_SECS` higher |
| `pdf_created: false` | Verify `PIPELINE_CONFIG`, network rule host matches endpoint hostname exactly |
| EAI permission denied | `GRANT USAGE ON INTEGRATION PDF_API_EAI TO ROLE ...` |
| Image pull failed | Re-run `push_gotenberg_image.sh`; verify image path in spec matches repo |

## Cost notes

- `PDF_COMPUTE_POOL` with `MIN_NODES = 1` keeps one node warm
- `AUTO_SUSPEND_SECS = 600` suspends after 10 min idle
- For dev, suspend manually: `ALTER COMPUTE POOL PDF_COMPUTE_POOL SUSPEND;`

## Markdown-only fallback

If SPCS is not ready, leave `PDF_API_ENABLED = false` in `PIPELINE_CONFIG`. `EXPORT_PROPOSAL` still writes `.md` to `final/` with `COMPLETED_MD_ONLY`.
