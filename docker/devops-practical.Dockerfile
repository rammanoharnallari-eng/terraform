FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
ENV NODE_ENV=production
EXPOSE 3000
RUN addgroup -S app && adduser -S app -G app
USER app
CMD ["npm","start"]
