# Stage 1: Install dependencies
FROM node:20-alpine AS dependencies

WORKDIR /app

COPY package*.json ./

RUN npm ci


# Stage 2: Create the final image
FROM node:20-alpine

WORKDIR /app

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

EXPOSE 3000

USER node

CMD ["./node_modules/.bin/babel-node", "src/index.js"]
