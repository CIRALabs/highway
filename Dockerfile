FROM ruby:2.6.1 as builder

RUN apt-get update -qq && apt-get install -y postgresql-client libgmp10-dev libgmp10
RUN apt-get remove -y git
RUN apt-get install -y git

RUN mkdir -p /app/highway
RUN mkdir -p /gems/highway

WORKDIR /gems/highway
RUN git config --global http.sslVerify "false"
RUN git clone https://github.com/CIRALabs/ruby-openssl.git && \
    git clone --single-branch --branch binary_http_multipart https://github.com/AnimaGUS-minerva/multipart_body.git && \
    git clone --single-branch --branch ecdsa_interface_openssl https://github.com/AnimaGUS-minerva/ruby_ecdsa.git && \
    git clone https://github.com/mcr/ChariWTs.git 

WORKDIR /app/highway
ADD ./docker/Gemfile /app/highway/Gemfile
ADD ./docker/Gemfile.lock /app/highway/Gemfile.lock
ADD ./docker/Rakefile /app/highway/Rakefile

RUN bundle install --system --gemfile=/app/highway/Gemfile && bundle check
RUN cat /app/highway/Gemfile.lock

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
