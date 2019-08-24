FROM alpine:3.4

RUN apk update
RUN apk add vim
RUN apk add curl
