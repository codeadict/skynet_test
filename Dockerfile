FROM elixir:1.13-alpine AS build

WORKDIR /app

# set build ENV
ENV MIX_ENV=prod

# install build dependencies
RUN apk add --no-cache build-base && \
  mix local.hex --force && \
  mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get --only prod && \
  mix deps.compile

COPY lib lib
COPY rel rel

# compile and build release
RUN mix release

# prepare final image
FROM alpine:3.13.3 AS app

RUN apk add --no-cache ca-certificates libstdc++ openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/skynet ./

ENV HOME=/app
ENV MIX_ENV=prod
ENV SKYNET_PORT=4000

EXPOSE ${SKYNET_PORT}

ENTRYPOINT [ "bin/skynet" ]
CMD ["start"]
