# Vault

```bash
. env.sh
```

```bash
vault login root
```

```bash
vault secrets enable database

vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="readonly" \
    connection_url="postgresql://{{username}}:{{password}}@irreverant-snake-postgresql:5432/gopher_search_production?sslmode=disable" \
    username="postgres" \
    password=""


vault write database/roles/readonly \
  db_name="postgresql" \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
```