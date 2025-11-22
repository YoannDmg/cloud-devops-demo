# =============================================================================
# DOCKERFILE - Frontend (Angular)
# =============================================================================
# Multi-stage build with Nginx for production serving
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder
# -----------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (better layer caching)
COPY package*.json ./
RUN npm ci --prefer-offline

# Copy source and build for production
COPY . .
RUN npm run build -- --configuration=production

# -----------------------------------------------------------------------------
# Stage 2: Production Server (Nginx)
# -----------------------------------------------------------------------------
FROM nginx:alpine AS runner

# Add labels for image metadata
LABEL maintainer="DevOps Team"
LABEL description="Cloud DevOps Demo - Frontend Application"
LABEL org.opencontainers.image.source="https://github.com/ydmg/cloud-devops-demo"

# Remove default nginx config and add custom one
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built application from builder stage
COPY --from=builder /app/dist/frontend/browser /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
