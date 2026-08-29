
FROM node:20-alpine AS dependencies

WORKDIR /app

COPY package*.json ./

RUN npm ci



FROM node:20-alpine

WORKDIR /app

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

EXPOSE 3000

CMD ["./node_modules/.bin/babel-node", "src/index.js"]
