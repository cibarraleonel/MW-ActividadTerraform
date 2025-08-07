variable "key_name" {
  type        = string
  default     = "mikroways-key"
  description = "Nombre para el key pair"
}

variable "public_key_path" {
  type        = string
  default     = "~/.ssh/aws.pub"
  description = "Ruta al archivo de clave pública"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.10.0.0/16"
  description = "Bloque CIDR para la VPC"
}

variable "subnet_a_cidr" {
  type        = string
  default     = "10.10.1.0/24"
  description = "CIDR para la subred pública A"
}

variable "subnet_b_cidr" {
  type        = string
  default     = "10.10.2.0/24"
  description = "CIDR para la subred pública B"
}
