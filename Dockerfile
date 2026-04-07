FROM node:22-bookworm-slim AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY frontend/package*.json ./frontend/
RUN cd frontend && npm ci

COPY . .

RUN npm run clean \
    && cd frontend && npm run build \
    && cd .. \
    && npm run copy:frontend \
    && npm run build \
    && npm prune --omit=dev

FROM node:22-bookworm-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public

RUN mkdir -p /app/data /app/logs && chown -R node:node /app

VOLUME ["/app/data", "/app/logs"]
EXPOSE 3000

USER node
CMD ["node", "dist/index.js"]
