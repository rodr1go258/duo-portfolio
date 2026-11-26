variable "tenancy_ocid" {
  description = "OCID del tenancy de Oracle Cloud"
  type        = string
}

variable "user_ocid" {
  description = "OCID del usuario API de Oracle Cloud"
  type        = string
}

variable "fingerprint" {
  description = "Huella de la clave API"
  type        = string
}

variable "private_key" {
  description = "Contenido PEM de la clave API (sensitive)"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Región de OCI, por ejemplo us-ashburn-1"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  description = "OCID del compartment donde se crean los recursos"
  type        = string
}

variable "project_name" {
  description = "Prefijo para los recursos"
  type        = string
  default     = "duo-portfolio"
}

variable "instance_shape" {
  description = "Shape de la instancia OCI"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "vcn_cidr" {
  description = "CIDR de la VCN"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR de la subred pública"
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR de la subred privada"
  type        = string
  default     = "10.20.2.0/24"
}

variable "ssh_public_key" {
  description = "Clave pública SSH que se instalará en la VM"
  type        = string
  sensitive   = true
}

variable "ssh_cidr" {
  description = "CIDR autorizado para SSH y VNC"
  type        = string
  default     = "0.0.0.0/0"
}
