FROM nginx:1.13

COPY deploy/default.conf /etc/nginx/conf.d

RUN mkdir /files
COPY build/libs/app.jar /files/download
COPY src/install/install /files/install
