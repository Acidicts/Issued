# syntax=docker/dockerfile:1

# Production image for Coolify and Cloudflare Tunnel deployments.
# Make sure RUBY_VERSION matches the version in .ruby-version.
ARG RUBY_VERSION=3.4.9
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Runtime dependencies only. The base image is Debian trixie, so the libvips
# runtime package is `libvips42t64` (on bookworm it is `libvips42`).
# PostgreSQL client libs are required: the app uses the `pg` gem, not SQLite.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      curl \
      libjemalloc2 \
      libvips42t64 \
      libpq5 \
      postgresql-client \
      tzdata \
      wget && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Preload jemalloc through ldconfig instead of a hardcoded
# /usr/lib/$(uname -m)-linux-gnu path, which only resolves on amd64 and makes
# the container abort on arm64 (Apple Silicon / any aarch64 builder).
RUN ldconfig && \
    echo "/usr/lib/$(dpkg-architecture --query DEB_HOST_MULTIARCH)" > /etc/ld.so.conf.d/$(uname -m)-linux-gnu.conf && \
    ldconfig && \
    rm -f /usr/local/lib/libjemalloc.so

ENV RAILS_ENV="production" \
    RACK_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true" \
    PORT="3000" \
    LD_PRELOAD="libjemalloc.so.2"

FROM base AS build

# Build dependencies for native gems. `libpq-dev` is what the `pg` gem compiles
# against; without it `bundle install` fails on this app.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
COPY vendor ./vendor

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # -j 1 disables parallel compilation to avoid QEMU build issues.
    bundle exec bootsnap precompile -j 1 --gemfile

COPY . .

RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Precompile assets without needing RAILS_MASTER_KEY at build time.
# config/initializers/active_storage.rb refuses to boot the production app
# without R2 credentials, so pass build-time placeholders; real credentials are
# injected by the platform at runtime and are never baked into the image.
RUN SECRET_KEY_BASE_DUMMY=1 \
    R2_ACCOUNT_ID=build-placeholder \
    R2_BUCKET=build-placeholder \
    R2_ACCESS_KEY_ID=build-placeholder \
    R2_SECRET_ACCESS_KEY=build-placeholder \
    ./bin/rails assets:precompile

FROM base AS app

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

USER rails:rails

# Entrypoint prepares the database on startup.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Coolify can use this to detect readiness.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["sh", "-c", "wget -q -O /dev/null http://127.0.0.1:${PORT:-3000}/up || exit 1"]

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
