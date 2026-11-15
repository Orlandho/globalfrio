FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system globalfrio && useradd --system --gid globalfrio globalfrio
COPY --from=build /app/target/globalfrio-backend-1.0.0-SNAPSHOT.jar /app/app.jar
USER globalfrio
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
