FROM node:carbon-alpine

RUN apk update && \
    apk upgrade && \
    apk add git

RUN mkdir /app
WORKDIR /app

RUN npm install -g nodemon

COPY package.json package.json
RUN npm install && mv node_modules /node_modules

# If you are building your code for production
# RUN npm install --only=production

COPY . .

LABEL maintainer="KWJ <kevin.j.1914@gmail.com>"

EXPOSE 8080

CMD npm start
