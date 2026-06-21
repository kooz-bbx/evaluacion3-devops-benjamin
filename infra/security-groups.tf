########################################
# Security Group - Plano de control EKS
########################################
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security Group para el plano de control de EKS"
  vpc_id      = aws_vpc.main.id

  # Permite tráfico HTTPS desde los nodos worker al API server de EKS
  ingress {
    description = "HTTPS desde nodos worker"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Permite todo el tráfico saliente (para comunicación con nodos y AWS APIs)
  egress {
    description = "Todo el trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-eks-cluster-sg"
    Project = var.project_name
  }
}

########################################
# Security Group - Nodos worker EKS
########################################
resource "aws_security_group" "eks_nodes_sg" {
  name        = "${var.project_name}-eks-nodes-sg"
  description = "Security Group para los nodos worker de EKS"
  vpc_id      = aws_vpc.main.id

  # Comunicación entre nodos (requerida por Kubernetes)
  ingress {
    description = "Comunicacion entre nodos del cluster"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Tráfico desde el plano de control (kubelet, métricas, etc.)
  ingress {
    description     = "Trafico del plano de control hacia los nodos"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  # Permite acceso HTTP para el LoadBalancer del frontend
  ingress {
    description = "HTTP desde internet al frontend"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite acceso HTTPS
  ingress {
    description = "HTTPS desde internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite todo el tráfico saliente (para ECR, S3, CloudWatch, etc.)
  egress {
    description = "Todo el trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-eks-nodes-sg"
    Project = var.project_name
    # Requerido por EKS para asociar el SG automáticamente
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}
