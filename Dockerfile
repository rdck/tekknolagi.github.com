FROM ruby:3-alpine as build_site
RUN apk add --no-cache build-base
RUN apk add --no-cache python3
RUN mkdir /site
COPY . /site
WORKDIR /site
RUN bundle
RUN bundle exec jekyll build

# Set things up
FROM alpine:latest as build_server
ARG VER=3.0.2
ARG COSMO=cosmos-$VER.zip
RUN wget https://github.com/jart/cosmopolitan/releases/download/$VER/$COSMO
WORKDIR cosmo
COPY --from=build_site /site/_site/. _site
RUN unzip ../$COSMO bin/ape.elf bin/assimilate bin/zip bin/redbean
WORKDIR _site
RUN sh ../bin/zip -A -r ../bin/redbean *
WORKDIR ..
RUN bin/ape.elf bin/assimilate bin/redbean

# Set up the container
FROM scratch as web
COPY --from=build_server /cosmo/bin/redbean .
EXPOSE 8000
ENTRYPOINT ["./redbean"]
