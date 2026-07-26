FROM --platform=$BUILDPLATFORM golang:1.24.5 AS build

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags='-s -w' -o /out/hello ./services/hello

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/hello /hello

EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/hello"]
