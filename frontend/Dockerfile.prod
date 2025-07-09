FROM node:18-alpine

# Set build argument for branch tracking
ARG BRANCH=prod
ENV GIT_BRANCH=${BRANCH}

WORKDIR /app

# Install production tools
RUN apk add --no-cache git curl vim

# Copy package files
COPY package*.json ./

# Install all dependencies (including prod dependencies)
RUN npm ci

# Copy source code
COPY . .

# Create production startup script that properly binds to all interfaces
RUN echo '#!/bin/sh\n\
echo "=== Dendreo Frontend Production Environment ==="\n\
echo "Branch: ${GIT_BRANCH}"\n\
echo "Environment: production"\n\
echo "Node Version: $(node --version)"\n\
echo "Host: ${HOST:-0.0.0.0}"\n\
echo "Port: ${PORT:-3000}"\n\
echo "==============================================="\n\
echo "Starting React production server on all interfaces..."\n\
export HOST=${HOST:-0.0.0.0}\n\
export PORT=${PORT:-3000}\n\
export GENERATE_SOURCEMAP=false\n\
export SKIP_PREFLIGHT_CHECK=true\n\
exec npm start\n\
' > /app/start-prod.sh && chmod +x /app/start-prod.sh

# Expose port for production server
EXPOSE 3000

# Health check for production server
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000 || exit 1

# Default production command
CMD ["/app/start-prod.sh"] 