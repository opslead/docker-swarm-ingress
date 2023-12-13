{{ range $index, $element := . -}}
server {
  listen 80;
  server_name {{ $element.ServiceDomain }};

  client_max_body_size {{ $element.ServiceMaxBodySize }};

  # Endpoint used for performing domain verification with Let's Encrypt.
  location /.well-known/acme-challenge/ {
    content_by_lua_block {
      auto_ssl:challenge_server()
    }
  }

  {{ if $element.ServiceRedirectSSL -}}
  location / {
    return 301 https://$host$request_uri;
  }
  {{ else -}}
  location / {
    resolver 127.0.0.11;

    set $service {{ $element.ServiceName }};

    proxy_send_timeout {{ $element.ServiceProxyTimeout }};
    proxy_read_timeout {{ $element.ServiceProxyTimeout }};
    proxy_connect_timeout {{ $element.ServiceProxyTimeout }};

    proxy_pass http://$service:{{ $element.ServicePort }}{{ $element.ServicePath }};
  }
  {{- end }}
}

{{ if $element.ServiceSSL -}}
server {
  listen 443 ssl;
  server_name {{ $element.ServiceDomain }};
  
  client_max_body_size {{ $element.ServiceMaxBodySize }};

  # Dynamic handler for issuing or returning certs for SNI domains.
  ssl_certificate_by_lua_block {
    auto_ssl:ssl_certificate()
  }

  location / {
    resolver 127.0.0.11;

    set $service {{ $element.ServiceName }};
    
    proxy_send_timeout {{ $element.ServiceProxyTimeout }};
    proxy_read_timeout {{ $element.ServiceProxyTimeout }};
    proxy_connect_timeout {{ $element.ServiceProxyTimeout }};

    proxy_pass http://$service:{{ $element.ServicePort }}{{ $element.ServicePath }};
  }

  ssl_certificate /etc/ssl/resty-auto-ssl-fallback.crt;
  ssl_certificate_key /etc/ssl/resty-auto-ssl-fallback.key;
}
{{ end }}
{{ end -}}
