FROM node:20-alpine

# Install dependencies for better compatibility
RUN apk add --no-cache libc6-compat curl

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies with error handling
RUN npm install --only=production --no-audit --no-fund && \
    npm cache clean --force && \
    rm -rf /tmp/*

# Copy source code
COPY . .

# Create non-root user
RUN addgroup -S app && adduser -S app -G app

# Set ownership of the app directory
RUN chown -R app:app /app

# Switch to non-root user
USER app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["npm", "start"]
