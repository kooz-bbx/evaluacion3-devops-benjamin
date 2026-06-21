variable "aws_region" {
  description = "Región AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo en los recursos"
  type        = string
  default     = "eval2"
}

variable "cluster_name" {
  description = "Nombre del clúster EKS"
  type        = string
  default     = "eval2-cluster"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes para el clúster EKS"
  type        = string
  default     = "1.30"
}

# -------------------------
# Networking
# -------------------------
variable "vpc_cidr" {
  description = "CIDR block de la VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las subredes públicas (una por AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subredes privadas (una por AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# -------------------------
# EKS Node Group
# -------------------------
variable "node_instance_type" {
  description = "Tipo de instancia EC2 para los nodos worker de EKS"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Número deseado de nodos worker"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Número mínimo de nodos worker"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Número máximo de nodos worker"
  type        = number
  default     = 4
}

# -------------------------
# ECR
# -------------------------
variable "ecr_repos" {
  description = "Lista de repositorios ECR a crear"
  type        = list(string)
  default     = ["eval2-back-ventas", "eval2-back-despachos", "eval2-frontend"]
}
