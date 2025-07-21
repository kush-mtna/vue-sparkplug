FROM node:alpine

WORKDIR /app

COPY frontend/package*.json .
# COPY frontend/package-lock.json .   # if you use package-lock.json

RUN npm install

COPY frontend/ ./

CMD ["npm", "run", "dev"]
