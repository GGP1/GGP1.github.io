FROM klakegg/hugo:0.111.3-alpine AS hugo

ENV HUGO_ENV="production hugo --gc --minify"

COPY . /blog

WORKDIR /blog

RUN hugo --config config.yml

# ----------

FROM nginx:1.29.0-alpine

COPY --from=hugo /blog/public /usr/share/nginx/html

WORKDIR /usr/share/nginx/html
