-- ═══════════════════════════════════════════════════════════════════
-- SYNC_SKILLS_FROM_GIT — Read skills/pre-sales/*/SKILL.md from Git repo
-- Requires: Snowflake Git repo stage (SKILLS_GIT_REPO in deploy_config)
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FILE FORMAT IF NOT EXISTS UTF8_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = NONE
  RECORD_DELIMITER = '\n'
  SKIP_HEADER = 0
  ESCAPE = NONE
  ESCAPE_UNENCLOSED_FIELD = NONE;

CREATE OR REPLACE PROCEDURE SYNC_SKILLS_FROM_GIT()
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'sync_skills_from_git'
EXECUTE AS CALLER
AS
$$
import re

DB = "SPS_BUSINESS_INSIGHT"
SCHEMA = "NEXUS"


def _git_base(session):
    rows = session.sql(f"""
        SELECT CONFIG_VALUE FROM {DB}.{SCHEMA}.PIPELINE_CONFIG
        WHERE CONFIG_KEY = 'SKILLS_GIT_PATH'
    """).collect()
    git_path = rows[0]["CONFIG_VALUE"] if rows else "branches/DEMO/skills/pre-sales"
    return f"@{DB}.{SCHEMA}.SKILLS_GIT_REPO/{git_path}"


def _parse_frontmatter(content):
    name = None
    description = None
    m = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if m:
        for line in m.group(1).splitlines():
            if line.startswith("name:"):
                name = line.split(":", 1)[1].strip().strip('"').strip("'")
            elif line.startswith("description:"):
                description = line.split(":", 1)[1].strip().strip('"').strip("'")
    return name, description


def sync_skills_from_git(session):
    try:
        git_base = _git_base(session)
        dirs = session.sql(f"""
            SELECT DISTINCT REGEXP_SUBSTR(RELATIVE_PATH, '[^/]+') AS FOLDER
            FROM DIRECTORY({git_base})
            WHERE RELATIVE_PATH LIKE '%SKILL.md'
        """).collect()

        synced = []
        for row in dirs:
            folder = row["FOLDER"]
            if not folder or folder == "SKILL.md":
                continue
            git_path = f"{git_base}/{folder}/SKILL.md"
            content_rows = session.sql(f"""
                SELECT $1 AS line FROM {git_path}
                (FILE_FORMAT => '{DB}.{SCHEMA}.UTF8_FORMAT')
            """).collect()
            if not content_rows:
                continue
            content = "\n".join(r["LINE"] for r in content_rows)
            skill_name, description = _parse_frontmatter(content)
            if not skill_name:
                skill_name = folder

            session.sql(f"""
                MERGE INTO {DB}.{SCHEMA}.SKILLS t
                USING (SELECT ? AS SKILL_NAME) s
                ON t.SKILL_NAME = s.SKILL_NAME
                WHEN MATCHED THEN UPDATE SET
                    FOLDER_NAME = ?, DESCRIPTION = ?, CONTENT = ?,
                    GIT_PATH = ?, SYNCED_AT = CURRENT_TIMESTAMP()
                WHEN NOT MATCHED THEN INSERT
                    (SKILL_NAME, FOLDER_NAME, DESCRIPTION, CONTENT, GIT_PATH)
                VALUES (?, ?, ?, ?, ?)
            """, params=[
                skill_name, folder, description, content, f"skills/pre-sales/{folder}/SKILL.md",
                skill_name, folder, description, content, f"skills/pre-sales/{folder}/SKILL.md",
            ]).collect()
            synced.append(skill_name)

        session.sql(f"ALTER CORTEX SEARCH SERVICE {DB}.{SCHEMA}.SKILLS_SEARCH_SERVICE REFRESH").collect()

        return {"status": "SUCCESS", "skills_synced": len(synced), "skill_names": synced}
    except Exception as e:
        return {"status": "ERROR", "error": str(e)}
$$;

CREATE TASK IF NOT EXISTS TASK_SYNC_SKILLS_FROM_GIT
  WAREHOUSE = IDENTIFIER($DEPLOY_WAREHOUSE)
  SCHEDULE = 'USING CRON 0 7 * * * UTC'
  COMMENT = 'Daily refresh of SKILLS table from Git repo'
AS
  CALL SYNC_SKILLS_FROM_GIT();
