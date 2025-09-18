# syntax=docker/dockerfile:1.7
FROM node:20-bullseye AS deps
WORKDIR /app

LABEL org.opencontainers.image.title="cloudcurio-admin" \
      org.opencontainers.image.description="CloudCurio KB component: cloudcurio-admin" \
      org.opencontainers.image.vendor="CBW" \
      org.opencontainers.image.source="https://github.com/OWNER/REPO" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY apps/admin/package.json ./
RUN npm ci

FROM deps AS build
COPY apps/admin /app
RUN npm run build

FROM gcr.io/distroless/nodejs20-debian12 AS runtime
WORKDIR /app

LABEL org.opencontainers.image.title="cloudcurio-admin" \
      org.opencontainers.image.description="CloudCurio KB component: cloudcurio-admin" \
      org.opencontainers.image.vendor="CBW" \
      org.opencontainers.image.source="https://github.com/OWNER/REPO" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY --from=build /app/.next/standalone /app
COPY --from=build /app/.next/static /app/.next/static
COPY --from=build /app/public /app/public 2>/dev/null || true
USER 10001
ENV PORT=3050 NODE_ENV=production
EXPOSE 3050
CMD ["server.js"]
