FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY angular.json tsconfig.json tsconfig.app.json ./
COPY src ./src
# La instalación de dependencias puede necesitar red; compilar Angular no.
RUN --network=none npm run build -- --configuration production

FROM nginx:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/globalfrio-frontend/ /usr/share/nginx/html/
EXPOSE 80
