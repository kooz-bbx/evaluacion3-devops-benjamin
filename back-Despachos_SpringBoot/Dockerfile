# Stage 1: Build con Maven
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /build

# Copiar pom.xml primero para aprovechar caché de dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar el código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Imagen final liviana solo con el JAR
FROM eclipse-temurin:17-jre-alpine

# Usuario sin privilegios de root (buena práctica de seguridad)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /build/target/*.jar app.jar

RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

# Opciones JVM optimizadas para contenedores
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
