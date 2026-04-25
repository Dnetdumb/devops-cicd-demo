# --- STAGE 1: Build Stage ---
FROM node:20.11.1-bookworm AS builder

WORKDIR /app

# Copy package files to reuse Docker Layer Cache for node_modules
COPY package*.json ./

# Install dependencies (include build-essential and C++ lib)
RUN npm install

# --- STAGE 2: Runtime Stage ---
FROM node:20.11.1-bookworm-slim

WORKDIR /app

#Create non-root user
RUN groupadd -r nodeapp && useradd -r -g nodeapp nodeapp

## Copy only needed files from stage builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app .

#Fix ownership
RUN chown -R nodeapp:nodeapp /app

USER nodeapp

EXPOSE 3000

CMD ["node", "app.js"]
