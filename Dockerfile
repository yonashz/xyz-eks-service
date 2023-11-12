FROM golang:1.21.4-alpine as base
WORKDIR /app
COPY go.mod ./
RUN go get -u github.com/stretchr/testify
RUN go mod download
COPY main.go ./

FROM base as build
RUN go build -o /xyz-service

FROM build as test
COPY main_test.go ./
RUN go test -v -cover .

FROM build as development
EXPOSE 8080
CMD ["/xyz-service"]