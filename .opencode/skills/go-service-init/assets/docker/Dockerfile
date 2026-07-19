FROM golang:<go-version>-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/app ./cmd/<binary>/

FROM alpine
COPY --from=build /bin/app /app
ENTRYPOINT ["/app"]
