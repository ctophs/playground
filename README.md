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
        ├── prod/stack.tm.hcl          # Stack "monitoring-prod"
        └── test/stack.tm.hcl          # Stack "monitoring-test"
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
# Plugin-Cache-Verzeichnis anlegen (einmalig)
mkdir -p .terraform-plugin-cache

# Alle Stacks initialisieren
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

1. Verzeichnis unter `stacks/<workload-name>/` anlegen.
2. `config.tm.hcl` mit Workload-Globals erstellen (Name, Subscriptions, Container Apps).
3. Pro Umgebung ein Unterverzeichnis (`test/`, `prod/`, …) mit `stack.tm.hcl` anlegen und das Tag `container-workload` setzen.
4. `terramate generate` ausführen — `_tm_main.tf` wird automatisch generiert.

Beispiel für eine neue Umgebung in einem Workload:

```hcl
# stacks/<workload>/dev/stack.tm.hcl
stack {
  name        = "<workload>-dev"
  description = "..."
  id          = "<uuid>"          # terramate create . erzeugt eine neue ID
  tags        = ["<workload>", "dev", "container-workload"]
}

globals "azure" {
  environment     = "dev"
  subscription_id = global.azure.workload.subscription_ids["dev"]
}
```

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

Pro Eintrag werden automatisch eine User Assigned Identity und eine Container App erstellt. Um in Prod eine gepinnte Image-Version zu verwenden, kann die Map im `stack.tm.hcl` der jeweiligen Umgebung überschrieben werden (siehe Kommentar in [stacks/monitoring/prod/stack.tm.hcl](stacks/monitoring/prod/stack.tm.hcl)).

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
terramate create stacks/<workload>/<env>
```
