# Playground — Azure Container Workloads mit Terramate & Terraform

Dieses Repository enthält eine [Terramate](https://terramate.io/)-Monorepo-Struktur zum Bereitstellen von Azure Container Apps. Die Terraform-Module liegen direkt im Repo unter `modules/` und werden per Git-URL referenziert.

## Voraussetzungen

- [Terramate](https://terramate.io/docs/cli/installation) >= 0.11.0
- [Terraform](https://developer.hashicorp.com/terraform/install) ~> 1.9
- [Azure CLI](https://learn.microsoft.com/de-de/cli/azure/install-azure-cli) — für `az login`
- Git

## Repository-Struktur

```
.
├── config.tm.hcl                      # Root-Globals (Tenant, Location, Provider-Versionen, Modul-URLs)
├── terramate.tm.hcl                   # Terramate-Konfiguration (Git, Plugin-Cache)
├── generate.tm.hcl                    # Code-Generierung: _tm_provider.tf + _tm_backend.tf (alle Stacks)
├── generate_container_workload.tm.hcl # Code-Generierung: _tm_main.tf (nur "container-workload"-Stacks)
├── modules/
│   ├── container-app/
│   ├── container-app-environment/
│   ├── resource-group/
│   └── user-assigned-identity/
└── stacks/
    └── monitoring/
        ├── config.tm.hcl              # Workload-Globals (Name, Subscriptions, Container Apps)
        ├── prod/
        │   ├── config.tm.hcl          # Umgebungs-Globals (environment=prod, subscription_id)
        │   └── container-workload/
        │       └── stack.tm.hcl       # Stack "monitoring-prod-container-workload"
        └── test/
            ├── config.tm.hcl          # Umgebungs-Globals (environment=test, subscription_id)
            └── container-workload/
                └── stack.tm.hcl       # Stack "monitoring-test-container-workload"
```

## Erste Schritte

### 1. Azure-Login

```bash
az login
```

### 2. Konfiguration anpassen

In [config.tm.hcl](config.tm.hcl) die Tenant-ID eintragen:

```hcl
globals "azure" {
  tenant_id = "<deine-tenant-id>"
}
```

In [stacks/monitoring/config.tm.hcl](stacks/monitoring/config.tm.hcl) die echten Subscription-IDs eintragen:

```hcl
subscription_ids = {
  test = "<test-subscription-id>"
  prod = "<prod-subscription-id>"
}
```

### 3. Terraform-Code generieren

Terramate generiert die `_tm_*.tf`-Dateien automatisch aus den `.tm.hcl`-Templates:

```bash
terramate generate
```

### 4. Stacks initialisieren

```bash
terramate run terraform init
```

### 5. Plan & Apply

```bash
# Plan für alle Stacks
terramate run terraform plan

# Nur geänderte Stacks (seit letztem Commit)
terramate run --changed terraform plan

# Apply
terramate run terraform apply
```

## Einen neuen Workload hinzufügen

Jeder Workload besteht aus drei Ebenen: **Workload-Globals → Umgebungs-Globals → Stacks**.

1. Verzeichnis unter `stacks/<workload-name>/` anlegen.
2. `config.tm.hcl` mit Workload-Globals erstellen (Name, Subscriptions, Container Apps).
3. Pro Umgebung ein Unterverzeichnis (`test/`, `prod/`, …) mit eigener `config.tm.hcl` für die Umgebungs-Globals anlegen.
4. Unterhalb der Umgebung Stacks anlegen — z.B. `container-workload/`:
   ```bash
   terramate create stacks/<workload>/dev/container-workload
   ```
5. Den generierten `stack.tm.hcl` mit dem gewünschten Namen und den Tags versehen.
6. `terramate generate` ausführen — `_tm_main.tf` wird für alle Stacks mit Tag `container-workload` generiert.

Beispiel für eine neue Umgebung:

```
stacks/<workload>/
  config.tm.hcl               # Workload-Globals
  dev/
    config.tm.hcl             # Umgebungs-Globals
    container-workload/
      stack.tm.hcl            # Stack-Definition
```

```hcl
# stacks/<workload>/dev/config.tm.hcl
globals "azure" {
  environment     = "dev"
  subscription_id = global.azure.workload.subscription_ids["dev"]
}

globals "azure" "tags" {
  environment = "dev"
}
```

```hcl
# stacks/<workload>/dev/container-workload/stack.tm.hcl
stack {
  name        = "<workload>-dev-container-workload"
  description = "..."
  id          = "<uuid>"   # wird von terramate create automatisch gesetzt
  tags        = ["<workload>", "dev", "container-workload"]
}
```

Weitere Stacks (z.B. `networking/`) können parallel neben `container-workload/` angelegt werden und erben dieselben Umgebungs-Globals.

## Container Apps konfigurieren

Container Apps werden in `config.tm.hcl` des jeweiligen Workloads als Map definiert:

```hcl
container_apps = {
  gatus = {
    image = "ghcr.io/twinproduction/gatus:latest"
    port  = 8080
  }
  nginx = {
    image = "nginx:1.27-alpine"
    port  = 80
  }
}
```

Pro Eintrag werden automatisch eine User Assigned Identity und eine Container App erstellt. Um in Prod eine gepinnte Image-Version zu verwenden, kann die Map in `stacks/<workload>/prod/config.tm.hcl` überschrieben werden (siehe Kommentar in [stacks/monitoring/prod/config.tm.hcl](stacks/monitoring/prod/config.tm.hcl)).

## Generierte Dateien

Dateien mit dem Präfix `_tm_` werden von Terramate verwaltet und dürfen nicht manuell bearbeitet werden:

| Datei | Inhalt |
|---|---|
| `_tm_provider.tf` | AzureRM-Provider-Konfiguration |
| `_tm_backend.tf` | Lokales Terraform-Backend (State unter `.terraform-state/`) |
| `_tm_main.tf` | Azure-Ressourcen des Workloads (nur bei Tag `container-workload`) |

## Nützliche Befehle

```bash
# Alle Stacks auflisten
terramate list

# Nur geänderte Stacks anzeigen
terramate list --changed

# Einen neuen Stack anlegen
terramate create stacks/<workload>/<env>/<stack-name>
```
