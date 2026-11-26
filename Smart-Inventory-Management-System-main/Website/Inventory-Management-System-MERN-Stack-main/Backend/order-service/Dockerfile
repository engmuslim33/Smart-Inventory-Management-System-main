# ---------- Stage 1: install production dependencies ----------
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund

# ---------- Stage 2: runtime image ----------
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production \
    ORDER_SERVICE_PORT=4003
COPY --from=deps /app/node_modules ./node_modules
COPY --chown=node:node . .
USER node
EXPOSE 4003
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:${ORDER_SERVICE_PORT}/health || exit 1
CMD ["node", "server.js"]