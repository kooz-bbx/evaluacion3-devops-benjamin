

########################################
# Clúster EKS
########################################
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  
  # Usamos el LabRole mandatorio de AWS Academy
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  vpc_config {
    subnet_ids = concat(
      aws_subnet.public[*].id,
      aws_subnet.private[*].id
    )
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_public_access  = true   
    endpoint_private_access = true   
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name    = var.cluster_name
    Project = var.project_name
  }

  # Removido el depends_on conflictivo para evitar trabas
}

########################################
# Node Group - Nodos worker EC2
########################################
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-workers"
  
  # Los nodos también se registran con el LabRole de AWS Academy
  node_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  subnet_ids = aws_subnet.private[*].id
  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  capacity_type = "ON_DEMAND"
  disk_size     = 20

  tags = {
    Name    = "${var.project_name}-worker-node"
    Project = var.project_name
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }
}