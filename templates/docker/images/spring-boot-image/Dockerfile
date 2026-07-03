ARG BASE_IMAGE=eclipse-temurin:25-alpine

FROM $BASE_IMAGE AS builder
ENV APP_NAME=app-jar-name
ARG JAR_FILE=target/$APP_NAME*.jar
COPY ${JAR_FILE} $APP_NAME.jar

RUN java -Djarmode=layertools -jar $APP_NAME.jar extract

FROM $BASE_IMAGE

LABEL org.opencontainers.image.title='Image Title'
LABEL org.opencontainers.image.description='Image Description'
LABEL org.opencontainers.image.authors='Author Name'
LABEL org.opencontainers.image.source='GITHUB_REPO_URL'

RUN apk update &&  \
    apk upgrade &&  \
    addgroup -S spring &&  \
    adduser -S spring -G spring
WORKDIR /usr/app

RUN chown spring:spring /usr/app
USER spring:spring
EXPOSE 8080

COPY --chown=spring:spring --from=builder dd-java-agent.jar ./
COPY --chown=spring:spring --from=builder dependencies/ ./
COPY --chown=spring:spring --from=builder spring-boot-loader/ ./
COPY --chown=spring:spring --from=builder snapshot-dependencies/ ./
COPY --chown=spring:spring --from=builder application/ ./

ARG GIT_COMMIT=unspecified

ENV DD_VERSION=${GIT_COMMIT}
ENV JAVA_OPTS=""
ENV PROXY_JAVA_AWS ""

ENTRYPOINT java ${PROXY_JAVA_AWS} $JAVA_OPTS \
"org.springframework.boot.loader.launch.JarLauncher"
