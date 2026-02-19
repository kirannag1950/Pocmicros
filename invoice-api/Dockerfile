FROM eclipse-temurin:21-jdk-alpine

WORKDIR /app

# Copy invoice-api jar
COPY invoice-api-0.1.0-SNAPSHOT.jar app.jar

# invoice-api runs on port 8080
EXPOSE 8080

# Optimized JVM settings for ECS/Docker
ENTRYPOINT ["java","-XX:+UseContainerSupport","-XX:MaxRAMPercentage=75.0","-XX:+UseG1GC","-jar","app.jar"]
