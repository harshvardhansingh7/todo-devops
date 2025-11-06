# Step 1: Use official OpenJDK 17 base image
FROM eclipse-temurin:17-jdk

# Step 2: Set working directory
WORKDIR /app

# Step 3: Copy JAR file
COPY target/todo-0.0.1-SNAPSHOT.jar app.jar

# Step 4: Expose app port
EXPOSE 8080

# Step 5: Run app
ENTRYPOINT ["java", "-jar", "app.jar"]
