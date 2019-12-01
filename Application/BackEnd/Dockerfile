FROM node:10.17.0
LABEL maintainer="Stephan Bartkowiak - stephanzbti@gmail.com"

RUN mkdir /apps
WORKDIR /apps
COPY . .

RUN npm install

CMD ["./scripts/entrypoint.sh"]