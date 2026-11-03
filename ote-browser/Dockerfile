FROM mcr.microsoft.com/playwright:v1.57.0-noble

LABEL org.opencontainers.image.title="OTE Browser for Home Assistant"
LABEL org.opencontainers.image.description="Experimental headless Chromium with a persistent profile"
LABEL org.opencontainers.image.source="https://github.com/zpevakp-ui/ha-ote-browser"

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data /etc/opt/chrome/policies/managed /etc/chromium/policies/managed \
    && printf '%s\n' '{"AutoSelectCertificateForUrls":["{\"pattern\":\"https://portal.ote-cr.cz\",\"filter\":{}}"]}' > /etc/opt/chrome/policies/managed/ote.json \
    && cp /etc/opt/chrome/policies/managed/ote.json /etc/chromium/policies/managed/ote.json

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

EXPOSE 9222
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -fsS http://127.0.0.1:9222/json/version >/dev/null || exit 1

CMD ["/run.sh"]
