# Build stage
FROM golang:1.24.5-alpine3.22 AS build_image

RUN apk add --update --no-cache -t build-deps curl gcc libc-dev libgcc
WORKDIR /go/src/github.com/adnanh/webhook

COPY webhook.version .
RUN curl -#L -o webhook.tar.gz https://api.github.com/repos/adnanh/webhook/tarball/$(cat webhook.version) && \
    tar -xzf webhook.tar.gz --strip 1 && \
    go get -d && \
    # Build a completely static binary with no external dependencies
    CGO_ENABLED=0 go build -ldflags="-s -w" -o /usr/local/bin/webhook

# Final stage
FROM alpine:3.22

RUN apk add --no-cache curl docker-cli docker-compose
COPY --from=build_image /usr/local/bin/webhook /usr/local/bin/webhook
WORKDIR /config

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/webhook"]
CMD ["-verbose", "-hotreload", "-hooks=hooks.yml"]
