# AGENTS.md — Guía del proyecto para agentes/LLM

## 1. TL;DR (qué es esto)

Infraestructura como código (**Terraform + GCP**) que despliega un **balanceador
HTTP global** con **una sola IP pública** que reparte el tráfico entre dos
servicios independientes —**Producción** y **Contingencia**— según **pesos
definidos por variables**. Todo se levanta con un único `terraform apply` y el
comportamiento del tráfico se cambia editando **solo** `terraform.tfvars`.

- Plataforma: Google Cloud Platform, proyecto `equipo7-terraform`.
- Región/zona: `us-central1` / `us-central1-a`.
- Repositorio plano (sin módulos): un solo estado, un solo `apply`.

Mensajes exactos que sirve cada servicio (son requisito, no cambiarlos):
- Producción: `Bienvenido al Servicio Principal - Versión Producción`
- Contingencia: `Error 503 - Sitio en Mantenimiento Programado`

---

## 2. Datos rápidos (invariantes del proyecto)

| Concepto | Valor | Nota |
|----------|-------|------|
| Prefijo de nombres | `equipo7` | variable `name_prefix`; todo recurso se llama `equipo7-<algo>` |
| Escala de pesos | `0`–`1000` | NO son porcentajes; proporción = peso / suma de pesos |
| Puerto de los servicios | `80` | variable `backend_port` |
| Named port de los MIG | `http` → `80` | el backend service lo referencia con `port_name = "http"` |
| Esquema del balanceador | `EXTERNAL_MANAGED` | obligatorio para el reparto por pesos |
| Tipo de máquina | `e2-micro` | optimización de costos |
| Imagen | `debian-cloud/debian-12` | el HTML se sirve con `python3 -m http.server 80` |
| Acceso SSH | bloqueado | el firewall niega el puerto 22 desde internet |

---

## 3. Mapa de archivos (dónde vive cada cosa)

Todos los `.tf` están en la raíz. Para modificar algo, edita el archivo indicado;
no crees módulos ni subcarpetas.

| Archivo | Responsable | Qué contiene |
|---------|-------------|--------------|
| `provider.tf` | Moni | Provider `google ~> 5.0` y versión mínima de Terraform |
| `variables.tf` | Moni | Las 11 variables del proyecto (incluye los pesos) |
| `network.tf` | Moni | VPC `equipo7-vpc` + subred `equipo7-subnet` (`10.0.0.0/24`) |
| `firewall.tf` | Moni | Allow health-checks al :80; Deny SSH :22 |
| `ip.tf` | Moni | IP pública global `equipo7-lb-ip` |
| `compute.tf` | Mario | 2 instance templates, 2 MIG regionales, 2 health checks |
| `loadbalancer.tf` | Mafe | 2 backend services, url map con pesos, proxy, forwarding rule |
| `iam.tf` | Todos | Rol `roles/editor` al profesor y al equipo |
| `outputs.tf` | Todos | 12 outputs (IP, red, MIGs, health checks) |
| `terraform.tfvars.example` | — | Plantilla de variables con los 3 escenarios |
| `CONVENCIONES.txt` | — | Contrato de integración (nombres y costuras acordadas) |
| `terraform.tfvars` | Local | NO está en git (`.gitignore`). Se crea del `.example` |

---

## 4. Arquitectura y flujo del tráfico

```
Internet
   │
   ▼
IP pública global (google_compute_global_address.lb_ip)   [ip.tf]
   │
   ▼
Global Forwarding Rule ──► Target HTTP Proxy ──► URL Map   [loadbalancer.tf]
                                                    │
                                    host_rule ["*"] → path_matcher
                                                    │
                                     route_action → weighted_backend_services
                                    ┌───────────────┴───────────────┐
                                    ▼ (peso producción)             ▼ (peso contingencia)
                          Backend Service prod            Backend Service cont   [loadbalancer.tf]
                                    │                               │
                          MIG prod (regional)           MIG cont (regional)      [compute.tf]
                                    │                               │
                          VM e2-micro :80                 VM e2-micro :80
                          "Producción"                    "Error 503"
```

Puntos clave:
- **Punto de entrada único:** una sola IP global. Las VMs no tienen IP pública,
  así que los usuarios nunca ven sus IPs internas.
- **Aislamiento de fallos:** producción y contingencia viven en MIG y máquinas
  **separadas**. Si uno cae, el otro sigue operando.
- **Reparto por pesos:** el `url_map` usa `weighted_backend_services`; el modo se
  cambia solo con las variables de peso.

---

## 5. Cómo operar los 3 escenarios

Se cambian **solo** dos variables en `terraform.tfvars` y se vuelve a aplicar.
Escala 0–1000.

| Escenario | `weight_produccion` | `weight_contingencia` | Efecto |
|-----------|---------------------|-----------------------|--------|
| 1 — Producción activa | `1000` | `0` | Todo el tráfico ve Producción |
| 2 — Mantenimiento total | `0` | `1000` | Todo el tráfico ve el Error 503 |
| 3 — Balance equitativo | `500` | `500` | El tráfico alterna entre ambos |

Ciclo de operación:

```bash
# (una sola vez) crear el tfvars local
cp terraform.tfvars.example terraform.tfvars

# desplegar
terraform init
terraform apply

# obtener la IP pública para probar
terraform output lb_ip_address

# cambiar de escenario: editar los pesos en terraform.tfvars, luego:
terraform apply     # esperar 1-2 min a que el balanceador propague
```

Prueba del reparto (útil sobre todo en el escenario 50/50):

```bash
for i in $(seq 1 10); do curl -s http://<IP>/ | grep -o '<h1>.*</h1>'; done
```

---

## 6. Costuras de integración (cómo se conectan las capas)

Referencias directas entre recursos (repositorio plano, sin módulos):

- **loadbalancer.tf → compute.tf:** el backend service usa
  `google_compute_region_instance_group_manager.mig_*.instance_group` como
  `backend.group`, y `google_compute_health_check.hc_*.id` como `health_checks`.
- **loadbalancer.tf → ip.tf:** el forwarding rule usa
  `google_compute_global_address.lb_ip.address` como IP.
- **compute.tf → network.tf:** los instance templates usan `var.network_name`,
  `google_compute_subnetwork.subnet.name` y `tags = [var.backend_network_tag]`.
- **firewall.tf ↔ compute.tf:** el firewall abre el :80 a las VMs por el tag
  `http-server`.

Contrato de nombres: el MIG declara `named_port { name = "http" }` y el backend
service usa `port_name = "http"`. Si cambias uno, cambia el otro.

---

## 7. Restricciones no obvias (no romper)

1. **`load_balancing_scheme = "EXTERNAL_MANAGED"`** en los backend services, el
   target proxy y el forwarding rule. El esquema clásico `EXTERNAL` no soporta
   `weighted_backend_services`; sin esto, los pesos no aplican.
2. **El `url_map` necesita `host_rule`** apuntando al `path_matcher`. Sin ese
   enganche, GCP ignora el reparto y todo va al `default_service` (producción),
   y el `apply` puede fallar.
3. **Pesos en escala 0–1000, no porcentajes.**
4. **`project_id` debe seguir siendo una variable** (nunca hardcodearlo): el
   repositorio se ejecuta en cualquier proyecto sin editar los `.tf`.
5. **Los MIG deben permanecer separados** (aislamiento de fallos): no fusionar
   producción y contingencia en una sola instancia o plantilla.
6. **Nada se configura por SSH ni por consola:** todo vive en el código; el HTML
   lo pinta el `startup-script` de cada template.

---

## 8. Reglas para el agente

Enrutamiento de cambios:

- **Cambiar el reparto de tráfico** → editar los pesos en `terraform.tfvars`
  (no tocar archivos `.tf`).
- **Cambiar textos, tipo de máquina o el arranque de las VMs** → `compute.tf`.
- **Cambiar el balanceador (pesos por defecto, timeouts, url map)** →
  `loadbalancer.tf` y/o `variables.tf`.
- **Cambiar red, firewall o IP** → `network.tf`, `firewall.tf`, `ip.tf`.

Invariantes a preservar en cualquier cambio:

- Mantener el prefijo `equipo7` en todos los nombres de recursos.
- No hardcodear `project_id`; mantenerlo como variable.
- Respetar las restricciones de la sección 7.
- Antes de entregar: ejecutar `terraform fmt -recursive` y, al final,
  `terraform destroy` para dejar la cuenta vacía.
