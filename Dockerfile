# syntax = docker/dockerfile:1

ARG NODE_VERSION=20.14.0
# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.1
FROM node:$NODE_VERSION-bookworm-slim AS node_base
FROM ruby:$RUBY_VERSION-slim AS base

ENV TZ="UTC"

# Rails app lives here
WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    git \
    libpq-dev \
    libvips \
    openssh-client \
    vim && \
    apt-get upgrade -y

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test:cli"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    pkg-config

COPY --from=node_base /usr/local/bin /usr/local/bin
COPY --from=node_base /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm

# Install application gems
RUN gem install bundler -v 2.6.3
RUN bundle config set --global jobs $(nproc)

COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Final stage for app image
FROM base

# Clear apt
RUN rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application, assets
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

RUN mkdir -p db log storage tmp && \
    chown -R nobody:nogroup db log storage tmp && \
    chmod 700 db log storage tmp

# Run and own only the runtime files as a non-root user for security
RUN useradd doubler --create-home --shell /bin/bash && \
    chown -R doubler:doubler db log storage tmp

# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
