FROM ruby:2.6.1 as builder

RUN apt-get update -qq && apt-get install -y postgresql-client libgmp10-dev libgmp10 && \ 
    apt-get remove -y git && \ 
    apt-get install -y git && \
    mkdir -p /app/highway && \
    mkdir -p /gems/highway && cd /gems/highway && \
    git config --global http.sslVerify "false" && \
    git clone https://github.com/CIRALabs/ruby-openssl.git && \
    git clone --single-branch --branch binary_http_multipart https://github.com/AnimaGUS-minerva/multipart_body.git && \
    git clone --single-branch --branch ecdsa_interface_openssl https://github.com/AnimaGUS-minerva/ruby_ecdsa.git && \
    git clone --single-branch --branch v0.6.0 https://github.com/mcr/ChariWTs.git 

WORKDIR /app/highway
ADD ./docker/Gemfile /app/highway/Gemfile
ADD ./docker/Gemfile.lock /app/highway/Gemfile.lock
ADD ./docker/Rakefile /app/highway/Rakefile

RUN bundle update && \
    bundle install --system --no-deployment --gemfile=/app/highway/Gemfile && \
    bundle check

COPY . /app/highway
# Has to be duplicated, for reasons.
ADD ./docker/Gemfile /app/highway/Gemfile
ADD ./docker/Gemfile.lock /app/highway/Gemfile.lock
ADD ./docker/Rakefile /app/highway/Rakefile

RUN rm -f /app/highway/tmp/pids/server.pid

FROM docker-registry.infra.01.k-ciralabs.ca/lestienne/distroless-ruby:2.6.1

COPY --from=builder /usr/lib/x86_64-linux-gnu/libgmp* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /gems/highway /gems/highway
ENV PATH="/usr/local/bundle/bin:${PATH}"

WORKDIR /app/highway

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"] 
