FROM golang:1.21.4-alpine

WORKDIR /app

COPY go.mod ./
RUN go get -u github.com/stretchr/testify
RUN go mod download

COPY main.go ./

RUN go build -o /xyz-service

EXPOSE 8080

CMD ["/xyz-service"]