# Multi-stage Dockerfile for SmartClass Backend
# Targets: dev | build | production

# ----------------------------------------------------
# Stage 1: Base (Node 24 Debian-slim with OpenSSL)
# ----------------------------------------------------
FROM node:24-bookworm-slim AS base
WORKDIR /app
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------
# Stage 2: Development (with dev dependencies & hot reload)
# ----------------------------------------------------
FROM base AS dev
ENV NODE_ENV=development
COPY package*.json ./
RUN npm install
COPY . .
RUN npx prisma generate || true
EXPOSE 3000
CMD ["npm", "run", "dev"]

# ----------------------------------------------------
# Stage 3: Build (Compiles TypeScript & prunes dev dependencies)
# ----------------------------------------------------
FROM base AS build
ENV NODE_ENV=development
COPY package*.json ./
RUN npm install
COPY . .
RUN npx prisma generate || true
RUN npm run build
RUN npm prune --omit=dev

# ----------------------------------------------------
# Stage 4: Production (Minimal, non-root user 'node')
# ----------------------------------------------------
FROM base AS production
ENV NODE_ENV=production
USER node
WORKDIR /app

COPY --chown=node:node package*.json ./
COPY --chown=node:node --from=build /app/node_modules ./node_modules
COPY --chown=node:node --from=build /app/dist ./dist
COPY --chown=node:node prisma ./prisma

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/health/live').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "dist/main.js"]
