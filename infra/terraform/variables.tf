variable "aws_region" {
  description = "Región de AWS donde se crea la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para los recursos"
  type        = string
  default     = "duo-portfolio"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.small"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
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
