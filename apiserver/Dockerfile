FROM node:16-alpine as builder

WORKDIR /usr/src/app

COPY package.json .
COPY package-lock.json .

RUN npm install && npm install -g typescript
COPY . .

RUN npm run build

FROM --platform=linux/amd64 node:16-alpine

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/package*.json ./
RUN npm install --production
COPY --from=builder /usr/src/app/dist ./dist

EXPOSE 3000

ENTRYPOINT [ "node", "dist/index.js" ]