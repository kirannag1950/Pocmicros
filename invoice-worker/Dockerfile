FROM eclipse-temurin:21-jdk-alpine

WORKDIR /app

COPY invoice-worker.jar app.jar

ENTRYPOINT ["java","-jar","app.jar"]
