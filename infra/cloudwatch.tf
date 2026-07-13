########################################
# Log Groups en CloudWatch para cada servicio
# Retención de 7 días para no generar costos excesivos en AWS Academy
########################################

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name    = "${var.project_name}-eks-cluster-logs"
    Project = var.project_name
  }

  lifecycle {
    ignore_changes = [
      tags,
      retention_in_days
    ]
  }
}

resource "aws_cloudwatch_log_group" "back_ventas" {
  name              = "/eks/${var.project_name}/back-ventas"
  retention_in_days = 7

  tags = {
    Name    = "${var.project_name}-back-ventas-logs"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "back_despachos" {
  name              = "/eks/${var.project_name}/back-despachos"
  retention_in_days = 7

  tags = {
    Name    = "${var.project_name}-back-despachos-logs"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/eks/${var.project_name}/frontend"
  retention_in_days = 7

  tags = {
    Name    = "${var.project_name}-frontend-logs"
    Project = var.project_name
  }
}

########################################
# Alarma CloudWatch: CPU alta en nodos (referencial)
# Útil para demostrar monitoreo activo en la presentación
########################################
resource "aws_cloudwatch_metric_alarm" "high_cpu_nodes" {
  alarm_name          = "${var.project_name}-high-cpu-nodes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alerta cuando el uso de CPU de los nodos supera el 80%"

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name    = "${var.project_name}-high-cpu-alarm"
    Project = var.project_name
  }
}
