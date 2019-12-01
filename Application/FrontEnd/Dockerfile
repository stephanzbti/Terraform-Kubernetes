FROM node:10.17.0 as builder
LABEL maintainer="Stephan Bartkowiak - stephanzbti@gmail.com"

RUN mkdir /apps
WORKDIR /apps
COPY . .

RUN npm install
RUN npm run build

FROM nginx:1.17.0-alpine as nginx
LABEL maintainer="Stephan Bartkowiak - stephanzbti@gmail.com"

COPY --from=builder /apps/build /usr/share/nginx/html