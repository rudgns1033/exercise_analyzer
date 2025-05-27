FROM golang:1.24-alpine as builder

WORKDIR /src

ADD go.mod .
ADD go.sum .
ADD vendor .
RUN go mod tidy
ADD . .

RUN CGO_ENABLED=1 go build -mod=vendor -o arnold ./cmd/arnold

FROM alpine

WORKDIR /opt

COPY --from=builder /src/arnold .
RUN chmod +x ./arnold

ENTRYPOINT ["/opt/arnold"]
