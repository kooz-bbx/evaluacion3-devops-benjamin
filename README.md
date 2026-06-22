# Evaluación Parcial N°3 — Orquestación y CI/CD en AWS EKS

**Asignatura:** ISY1101 - Introducción a Herramientas DevOps  
**Institución:** DuocUC  
**Proyecto:** Innovatech Chile — Sistema de Ventas y Despachos

---

## 📐 Arquitectura General

```
Internet
   │
   ▼
[Application Load Balancer / ELB]
   │  Puerto 80
   ▼
[Frontend — React + Nginx]  ← subred pública
   │
   ├──/api/v1/ventas──────► [back-ventas — Spring Boot :8080]  ← subred privada
   │                                │
   └──/api/v1/despachos───► [back-despachos — Spring Boot :8081]  ← subred privada
                                    │
                              [MySQL :3306 — ClusterIP]
                                    │
                              [PersistentVolume 5Gi gp2]
```

Toda la infraestructura corre sobre **AWS EKS** (Kubernetes administrado), dentro de una VPC dedicada con subredes públicas y privadas en 2 Availability Zones.

---

## 🗂️ Estructura del Repositorio

```
Eval22-main/
├── infra/                          # Infraestructura como Código (Terraform)
│   ├── main.tf                     # Provider AWS y configuración base
│   ├── variables.tf                # Variables parametrizables
│   ├── networking.tf               # VPC, subredes, IGW, NAT, route tables
│   ├── security-groups.tf          # Security Groups para EKS y nodos
│   ├── iam.tf                      # Roles IAM: cluster role, node role, pod execution role
│   ├── eks.tf                      # Clúster EKS y Node Group
│   ├── ecr.tf                      # Repositorios ECR + política de ciclo de vida
│   ├── cloudwatch.tf               # Log groups y alarmas de métricas
│   └── outputs.tf                  # Valores exportados (endpoint, URLs ECR, etc.)
│
├── k8s/                            # Manifiestos Kubernetes
│   ├── 00-namespace.yml            # Namespace: eval2
│   ├── 01-configmap.yml            # Variables de entorno no sensibles
│   ├── 02-secret.yml               # Plantilla de Secret (sin valores reales)
│   ├── 03-mysql.yml                # Deployment + Service + PVC de MySQL
│   ├── 04-back-ventas.yml          # Deployment + Service del microservicio Ventas
│   ├── 05-back-despachos.yml       # Deployment + Service del microservicio Despachos
│   ├── 06-frontend.yml             # Deployment + Service LoadBalancer del Frontend
│   └── 07-hpa.yml                  # HorizontalPodAutoscaler para los 3 servicios
│
├── back-Despachos_SpringBoot/      # Microservicio de Despachos (Java / Spring Boot)
│   └── src/...
│
├── front_despacho/                 # Frontend React + Vite + Tailwind CSS
│   ├── Dockerfile                  # Build multistage: node → nginx
│   ├── nginx.conf                  # Proxy reverso hacia los backends
│   └── src/...
│
├── docker-compose.yml              # Entorno local de desarrollo
├── .github/
│   └── workflows/
│       └── deploy.yml              # Pipeline CI/CD: build → push ECR → deploy EKS
└── README.md
```

---

## ☁️ Infraestructura AWS (Terraform)

### Recursos creados

| Recurso | Descripción |
|---|---|
| **VPC** `10.0.0.0/16` | Red virtual aislada para todo el proyecto |
| **Subredes públicas** x2 | `10.0.1.0/24`, `10.0.2.0/24` — para LoadBalancer y NAT |
| **Subredes privadas** x2 | `10.0.11.0/24`, `10.0.12.0/24` — para nodos EKS y backends |
| **Internet Gateway** | Salida a internet para subredes públicas |
| **NAT Gateway** | Salida a internet segura para subredes privadas |
| **Security Group cluster** | Permite HTTPS al API server EKS desde la VPC |
| **Security Group nodos** | Permite tráfico entre nodos, HTTP/HTTPS desde internet |
| **IAM Role EKS Cluster** | Permite a EKS gestionar recursos de AWS |
| **IAM Role Nodos (EC2)** | Permite a los nodos descargar imágenes ECR y enviar logs |
| **Clúster EKS** `eval2-cluster` | Kubernetes 1.29, logs de plano de control habilitados |
| **Node Group** | 2 nodos `t3.medium` (min 1, max 4), subredes privadas |
| **Repositorios ECR** x3 | `eval2-back-ventas`, `eval2-back-despachos`, `eval2-frontend` |
| **Log Groups CloudWatch** | Logs de cluster y de cada servicio, retención 7 días |

### Desplegar infraestructura

```bash
cd infra/

# 1. Inicializar Terraform (descarga providers)
terraform init

# 2. Ver plan de cambios antes de aplicar
terraform plan

# 3. Aplicar (crea todos los recursos en AWS)
terraform apply

# 4. Ver outputs (endpoint del clúster, URLs de ECR, etc.)
terraform output
```

> ⚠️ Requiere AWS CLI configurado con credenciales de AWS Academy (`aws configure`).

---

## 🔑 Configuración de Secrets

### GitHub Secrets (para el pipeline CI/CD)

Ir a: `Repositorio → Settings → Secrets and variables → Actions`

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Clave de acceso de AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta de AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sesión temporal de AWS Academy |

### Secret de base de datos en Kubernetes

Crear el secret manualmente **antes del primer deploy**, reemplazando la contraseña:

```bash
kubectl create secret generic eval2-secret \
  --from-literal=MYSQL_ROOT_PASSWORD=TuPasswordSegura123 \
  --from-literal=DB_PASSWORD=TuPasswordSegura123 \
  -n eval2
```

---

## 🚀 Pipeline CI/CD (GitHub Actions)

El archivo `.github/workflows/deploy.yml` automatiza el flujo completo:

```
Push a rama 'deploy'
        │
        ▼
1. Checkout del código
2. Configurar credenciales AWS (desde GitHub Secrets)
3. Login en Amazon ECR
4. Obtener Account ID dinámicamente
5. Build imagen back-ventas  ──► Push a ECR (:sha + :latest)
6. Build imagen back-despachos ─► Push a ECR (:sha + :latest)
7. Build imagen frontend ──────► Push a ECR (:sha + :latest)
8. Instalar kubectl
9. Conectar al clúster EKS
10. Aplicar manifiestos k8s/
11. kubectl set image → back-ventas
12. kubectl set image → back-despachos
13. kubectl set image → frontend
14. Esperar rollout back-ventas
15. Esperar rollout back-despachos
16. Esperar rollout frontend
17. Mostrar URL pública del frontend
```

**Trigger:** push a la rama `deploy` o ejecución manual (`workflow_dispatch`).

---

## ⚖️ Autoscaling (HPA)

Los tres servicios tienen `HorizontalPodAutoscaler` configurado con `autoscaling/v2`:

| Servicio | Min réplicas | Max réplicas | Umbral CPU |
|---|---|---|---|
| `back-ventas` | 2 | 5 | 70% |
| `back-despachos` | 2 | 5 | 70% |
| `frontend` | 2 | 4 | 70% |

**Justificación del 70% de CPU:** se eligió este umbral para iniciar el escalado antes de llegar a saturación, dejando margen de respuesta mientras se levantan nuevos pods (que tardan ~40s en estar listos por los `initialDelaySeconds` de Spring Boot).

Verificar estado del HPA:
```bash
kubectl get hpa -n eval2
kubectl describe hpa back-ventas-hpa -n eval2
```

---

## 🛠️ Entorno local (Docker Compose)

Para desarrollo y pruebas locales sin necesidad de AWS:

```bash
# Crear archivo .env con las variables requeridas
echo "MYSQL_ROOT_PASSWORD=localpassword" > .env
echo "MYSQL_DATABASE=eval2db" >> .env

# Levantar todos los servicios
docker compose up --build

# Acceder al frontend
open http://localhost:80

# Verificar los backends
curl http://localhost:8080/actuator/health   # back-ventas
curl http://localhost:8081/actuator/health   # back-despachos
```

---

## 📋 Despliegue manual en EKS (paso a paso)

```bash
# 1. Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name eval2-cluster

# 2. Crear el secret de base de datos
kubectl create secret generic eval2-secret \
  --from-literal=MYSQL_ROOT_PASSWORD=TuPassword \
  --from-literal=DB_PASSWORD=TuPassword \
  -n eval2

# 3. Aplicar todos los manifiestos en orden
kubectl apply -f k8s/

# 4. Verificar el estado de los pods
kubectl get pods -n eval2

# 5. Obtener la URL pública del frontend
kubectl get service frontend -n eval2

# 6. Ver logs de un servicio específico
kubectl logs -l app=back-despachos -n eval2 --tail=50
kubectl logs -l app=back-ventas -n eval2 --tail=50
kubectl logs -l app=frontend -n eval2 --tail=50
```

---

## 📊 Logs y Métricas

### CloudWatch
Los logs del plano de control de EKS se envían automáticamente a:
```
/aws/eks/eval2-cluster/cluster
```

Los logs de cada servicio se pueden configurar con el agente de CloudWatch:
```
/eks/eval2/back-ventas
/eks/eval2/back-despachos
/eks/eval2/frontend
```

### kubectl logs (directo)
```bash
# Logs en tiempo real de despachos
kubectl logs -f -l app=back-despachos -n eval2

# Logs de todos los pods del namespace
kubectl logs -l app=back-ventas -n eval2

# Eventos del namespace (útil para debugging)
kubectl get events -n eval2 --sort-by='.lastTimestamp'
```

---

## 🔍 Comunicación entre servicios

El frontend (Nginx) actúa como proxy reverso hacia los backends usando los **DNS internos de Kubernetes**:

```nginx
location /api/v1/ventas {
    proxy_pass http://back-ventas:8080;   # Resuelve al ClusterIP de back-ventas
}

location /api/v1/despachos {
    proxy_pass http://back-despachos:8081;  # Resuelve al ClusterIP de back-despachos
}
```

Dentro del namespace `eval2`, los services se descubren por nombre corto. Kubernetes DNS resuelve `back-ventas` → `back-ventas.eval2.svc.cluster.local` automáticamente.

---

## 🧰 Herramientas requeridas

- AWS CLI + credenciales de AWS Academy
- Terraform >= 1.3.0
- kubectl
- Docker Desktop
- Git
- Visual Studio Code

---

## 🚀 Acceso al Proyecto Desplegado

El proyecto ha sido completamente automatizado mediante un pipeline de CI/CD utilizando GitHub Actions, Docker, AWS ECR y AWS EKS.

* **URL Pública del Frontend (LoadBalancer):** http://a14ff2ffd70424e36ab2e0250eab6b2a-857952864.us-east-1.elb.amazonaws.com

### 🛠️ Comandos de Monitoreo Utilizados

Para verificar el estado de la infraestructura en Kubernetes, se utilizan los siguientes comandos:

```bash
# Ver el estado de todos los Pods en el namespace eval2
kubectl get pods -n eval2

# Obtener los servicios activos y las URLs de acceso
kubectl get svc -n eval2