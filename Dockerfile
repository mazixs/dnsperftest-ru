FROM alpine:latest

LABEL maintainer="mazixs" \
      description="DNS Performance & Stability Test (RU/Global)" \
      version="2.0.1"

RUN apk --no-cache add bash bind-tools \
    && mkdir /app \
    && wget -q https://raw.githubusercontent.com/mazixs/dnsperftest-ru/v2.0.1/dnstest.sh -O /app/dnstest.sh \
    && chmod +x /app/dnstest.sh

WORKDIR /app
ENTRYPOINT ["bash", "/app/dnstest.sh"]
