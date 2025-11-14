# Step 1: Lightweight Java runtime
FROM eclipse-temurin:17-jre-alpine

# Step 2: Working directory
WORKDIR /app

# Step 3: Copy jar (make sure mvn package creates this)
COPY target/todo-0.0.1-SNAPSHOT.jar app.jar

# Step 4: Expose port
EXPOSE 8080

# Step 5: Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
