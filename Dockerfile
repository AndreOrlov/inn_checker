# syntax=docker/dockerfile:experimental

FROM elixir:1.10.2-alpine AS builder

# The following are build arguments used to change variable parts of the image.
# The name of your application/release (required)
ARG APP_NAME
# The version of the application we are building (required)
ARG APP_VSN
# The environment to build with
ARG MIX_ENV=prod

ENV APP_NAME=${APP_NAME} \
    APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV}

# By convention, /opt is typically used for applications
WORKDIR /opt/app

# This step installs all the build tools we'll need
RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache \
    git \
    openssh-client \
    build-base && \
  mix local.rebar --force && \
  mix local.hex --force

RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan git.programmovichi.ru >> ~/.ssh/known_hosts

# This copies our app source code into the build container
COPY . .

RUN --mount=type=ssh mix do deps.get, deps.compile, compile, phx.digest, release

#RUN \
#  mkdir -p /opt/built && \
#  mix release
#  cp _build/${MIX_ENV}/rel/${APP_NAME}/releases/${APP_VSN}/${APP_NAME}.tar.gz /opt/built && \
#  cd /opt/built && \
#  tar -xzf ${APP_NAME}.tar.gz && \
#  rm ${APP_NAME}.tar.gz

# From this line onwards, we're in a new image, which will be the image used in production
FROM alpine:3.9

# The name of your application/release (required)
ARG APP_NAME
ARG MIX_ENV=prod

RUN apk update && \
    apk add --no-cache \
      bash \
      openssl-dev \
      imagemagick \
      file

ENV REPLACE_OS_VARS=true \
    APP_NAME=${APP_NAME} \
    MIX_ENV=${MIX_ENV}

WORKDIR /opt/app

COPY --from=builder /opt/app/_build/${MIX_ENV}/rel/${APP_NAME} .

CMD trap 'exit' INT; /opt/app/bin/${APP_NAME} start