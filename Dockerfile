FROM golang AS build

COPY . /src
RUN cd /src/controller && go build

FROM openresty/openresty:jammy

LABEL maintainer="opslead"
LABEL repository="https://github.com/opslead/docker-swarm-ingress"

ENV DOCKER_HOST="unix:///var/run/docker.sock" \
	UPDATE_INTERVAL="1" \
	OUTPUT_FILE="/usr/local/openresty/nginx/conf/conf.d/proxy.conf" \
	TEMPLATE_FILE="/opt/ingress/proxy.tpl"

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http

RUN openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/CN=sni-support-required-for-valid-ssl' \
	-keyout /etc/ssl/resty-auto-ssl-fallback.key \
	-out /etc/ssl/resty-auto-ssl-fallback.crt

RUN mkdir -p /etc/resty-auto-ssl
RUN mkdir -p /usr/local/openresty/nginx/conf/conf.d
RUN mkdir -p /opt/ingress

ADD controller/proxy.tpl /opt/ingress
ADD config/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

COPY --from=build /src/controller/controller /opt/ingress/controller

HEALTHCHECK --interval=15s --timeout=3s \
	CMD curl -f http://localhost/health || exit 1

CMD ["/opt/ingress/controller"]