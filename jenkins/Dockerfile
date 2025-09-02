# Temporary Docker file

FROM node:18-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM node:18-alpine AS backend-builder
WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app

RUN apk add --no-cache dumb-init

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 -G nodejs

COPY --from=backend-builder /app/backend/node_modules ./node_modules
COPY backend/ ./

COPY --from=frontend-builder /app/frontend/build ./public

RUN chown -R nodeuser:nodejs /app

USER nodeuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js

EXPOSE 3000

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]