FROM alpine:3.23.3

COPY app/ /usr/share/nginx/html

EXPOSE 80
