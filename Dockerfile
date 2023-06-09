FROM gradle:7.5.1-jdk17 AS builder
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle bootJar --no-daemon


FROM openjdk:17-alpine3.14
LABEL org.opencontainers.image.source="https://github.com/DataDog/vulnerable-java-application/"
EXPOSE 8080
RUN mkdir /app
WORKDIR /app
COPY --from=builder /home/gradle/src/build/libs/*.jar /app/spring-boot-application.jar

# Install Datadog agent
RUN wget -O dd-java-agent.jar https://github.com/DataDog/dd-trace-java/releases/download/v1.9.0/dd-java-agent-1.9.0.jar && \
    echo "794f28a64d8dca1b911ae27d05fa22e3b4fab23c5cefb89502a153f05fe6e294  dd-java-agent.jar" > SHA256SUMS && \
    sha256sum -c SHA256SUMS

# Utility
RUN apk add curl wget

#CMD ["sh", "-c", "export INSTANCE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4); export DD_TRACE_AGENT_URL=http://$INSTANCE_IP:8126; java -javaagent:/app/dd-java-agent.jar -jar /app/spring-boot-application.jar"]
CMD ["java", "-javaagent:/app/dd-java-agent.jar", "-jar", "/app/spring-boot-application.jar"]
