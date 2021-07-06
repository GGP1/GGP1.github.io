FROM klakegg/hugo:0.83.1-alpine as hugo

ENV HUGO_ENV="production hugo --gc --minify"

COPY . /blog

WORKDIR /blog

RUN hugo --config config.yml

# ----------

FROM nginx:1.21.0-alpine

COPY --from=hugo /blog/public /usr/share/nginx/html

WORKDIR /usr/share/nginx/html