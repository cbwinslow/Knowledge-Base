# syntax=docker/dockerfile:1.7
FROM python:3.11-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

LABEL org.opencontainers.image.title="cloudcurio-bff" \
      org.opencontainers.image.description="CloudCurio KB component: cloudcurio-bff" \
      org.opencontainers.image.vendor="CBW" \
      org.opencontainers.image.source="https://github.com/OWNER/REPO" \
      org.opencontainers.image.licenses="Apache-2.0"

RUN adduser --system --uid 10001 --group app
COPY services/bff/requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip pip install -r requirements.txt
COPY services/bff /app
EXPOSE 8088
USER app
ENTRYPOINT ["uvicorn","main:APP","--host","0.0.0.0","--port","8088","--proxy-headers","--forwarded-allow-ips","*"]
