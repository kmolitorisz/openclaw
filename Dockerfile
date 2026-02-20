# --- 1. FÁZIS: ÉPÍTÉS (BUILDER) ---
# Itt használjuk a nagy képet az összes eszközzel
FROM node:22-bookworm AS builder

# Bun telepítése az építéshez [cite: 2]
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
RUN corepack enable

WORKDIR /app

# Függőségek másolása és telepítése [cite: 4]
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

# A teljes kód másolása és az alkalmazás felépítése [cite: 8]
COPY . .
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

# --- 2. FÁZIS: FUTTATÁS (RUNNER) ---
# Itt váltunk a "slim" verzióra, ami sokkal kisebb [cite: 1]
FROM node:22-slim AS runner

WORKDIR /app
ENV NODE_ENV=production

# CSAK a futtatáshoz szükséges fájlokat hozzuk át a builderből
# Így az összes építési eszköz (Bun, pnpm cache, forráskód) törlődik
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/ui/dist ./ui/dist
COPY --from=builder /app/openclaw.mjs ./
COPY --from=builder /app/package.json ./

# Jogosultságok beállítása a biztonság érdekében [cite: 9]
RUN chown -R node:node /app
USER node

# Indítás [cite: 10]
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
