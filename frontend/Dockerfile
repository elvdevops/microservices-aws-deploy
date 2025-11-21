FROM node:20-alpine AS builder
WORKDIR /app
RUN npm init -y
RUN npm i react react-dom
RUN npm i -D esbuild
COPY public ./public
COPY src ./src


# bundle with esbuild into a single app.js
RUN npx esbuild src/App.jsx --bundle --outfile=public/app.js --format=esm


FROM nginx:stable-alpine
COPY public /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]