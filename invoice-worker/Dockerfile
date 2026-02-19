FROM eclipse-temurin:21-jdk-alpine

WORKDIR /app

COPY invoice-worker-0.1.0-SNAPSHOT.jar app.jar

# invoice-api runs on port 8081
EXPOSE 8081

# Optimized JVM settings for ECS/Docker
ENTRYPOINT ["java","-XX:+UseContainerSupport","-XX:MaxRAMPercentage=75.0","-XX:+UseG1GC","-jar","app.jar"]

