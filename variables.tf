variable "project_id" {
  description = "ID del proyecto GCP (obligatorio por rúbrica)"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo para nombres de recursos en GCP"
  type        = string
  default     = "equipo7"
}

variable "region" {
  description = "Región GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona GCP para instancias y MIGs"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Nombre de la VPC"
  type        = string
  default     = "equipo7-vpc"
}

variable "subnet_name" {
  description = "Nombre de la subred"
  type        = string
  default     = "equipo7-subnet"
}

variable "subnet_cidr" {
  description = "CIDR de la subred"
  type        = string
  default     = "10.0.0.0/24"
}

variable "backend_network_tag" {
  description = "Network tag para VMs detrás del balanceador"
  type        = string
  default     = "http-server"
}

variable "backend_port" {
  description = "Puerto HTTP de los servicios"
  type        = number
  default     = 80
}

# --- Variables de Mafe (balanceo por pesos) ---

variable "weight_produccion" {
  description = "Peso del servicio principal (0-1000)"
  type        = number
  default     = 1000

  validation {
    condition     = var.weight_produccion >= 0 && var.weight_produccion <= 1000
    error_message = "weight_produccion debe estar entre 0 y 1000."
  }
}

variable "weight_contingencia" {
  description = "Peso del servicio de contingencia (0-1000)"
  type        = number
  default     = 0

  validation {
    condition     = var.weight_contingencia >= 0 && var.weight_contingencia <= 1000
    error_message = "weight_contingencia debe estar entre 0 y 1000."
  }
}
