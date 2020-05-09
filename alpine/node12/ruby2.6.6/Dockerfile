FROM killua99/node-ruby:12-2.6-alpine AS apks

RUN set -eux; \
    \
    apk add --no-cache \
        build-base \
        protobuf-dev \
        libidn-dev \
        icu-dev \
        postgresql-dev \
        ncurses-dev \
        glib-dev \
        coreutils \
        linux-headers \
        dpkg-dev dpkg \
        ruby-dev \
        msgpack-c-dev \
        openssl-dev \
        openssl \
        procps \
        readline \
        libuv \
        git

FROM apks as yarn

COPY mastodon-upstream/package.json mastodon-upstream/yarn.lock /opt/mastodon/

RUN set -eux; \
    \
    cd /opt/mastodon; \
    until yarn install --check-files --pure-lockfile; \
    do \
        echo "Let's try again..."; \
    done

FROM apks as bundle

COPY mastodon-upstream/Gemfile* /opt/mastodon/

RUN set -eux; \
    \
    cd /opt/mastodon; \
    bundle config set deployment 'true'; \
    bundle config set without 'development test'; \
    bundle install -j$(nproc) --retry=30

FROM killua99/node-ruby:12-2.6-alpine

RUN set -eux; \
    \
    apk add --no-cache \
        ca-certificates \
        libprotobuf \
        icu \
        postgresql-dev \
        imagemagick \
        ffmpeg \
        libidn \
        yaml \
        tzdata \
        file \
        readline \
        tini

ARG UID=991
ARG GID=991

# Compiling assets.
RUN set -eux; \
    \
    addgroup --gid ${GID} mastodon; \
    adduser -D -u ${UID} -G mastodon -h /opt/mastodon mastodon; \
    cd /opt/mastodon; \
    ln -s /opt/mastodon /mastodon

# Copy mastodon
COPY --chown=991:991 mastodon-upstream /opt/mastodon
COPY --from=yarn --chown=991:991 /opt/mastodon /opt/mastodon
COPY --from=bundle --chown=991:991 /opt/mastodon /opt/mastodon
COPY --from=bundle /usr/local/bundle /usr/local/bundle

# Run mastodon services in prod mode
ENV RAILS_ENV="production"
ENV NODE_ENV="production"

# Tell rails to serve static files
ENV RAILS_SERVE_STATIC_FILES="true"
ENV BIND="0.0.0.0"
ENV PATH="${PATH}:/opt/mastodon/bin"

# Set the run user
USER mastodon

# Precompile assets
RUN set -eux; \
    \
    cd ~; \
    OTP_SECRET=precompile_placeholder SECRET_KEY_BASE=precompile_placeholder rails assets:precompile; \
    yarn cache clean

# Set the work dir and the container entry point
WORKDIR /opt/mastodon

ENTRYPOINT [ "/sbin/tini", "--" ]

EXPOSE 3000 4000
