FROM ruby:2.6 as builder

RUN apt-get update -qq && apt-get install -y postgresql-client git

RUN mkdir -p /app/highway
RUN mkdir -p /gems/highway

WORKDIR /gems/highway
RUN git config --global http.sslVerify "false"
RUN git clone https://github.com/mcr/ruby-openssl.git && \
    git clone https://github.com/activescaffold/active_scaffold.git && \
    git clone --single-branch --branch master https://github.com/plataformatec/devise.git && \
    git clone --single-branch --branch binary_http_multipart https://github.com/AnimaGUS-minerva/multipart_body.git && \
    git clone --single-branch --branch ecdsa_interface_openssl https://github.com/AnimaGUS-minerva/ruby_ecdsa.git && \
    git clone https://github.com/mcr/ChariWTs.git && \
    git clone --single-branch --branch per-host-deploy-to https://github.com/mcr/capistrano.git && \
    git clone --single-branch --branch per-host-deploy-to https://github.com/mcr/bundler.git && \
    git clone --single-branch --branch per-host-deploy-to https://github.com/mcr/passenger.git 

WORKDIR /app/highway
ADD ./docker/Gemfile /app/highway/Gemfile
ADD ./docker/Gemfile.lock /app/highway/Gemfile.lock
ADD ./docker/Rakefile /app/highway/Rakefile

RUN bundle install --system --gemfile=/app/highway/Gemfile && bundle check

COPY . /app/highway
# Has to be duplicated, for reasons.
ADD ./docker/Gemfile /app/highway/Gemfile
ADD ./docker/Gemfile.lock /app/highway/Gemfile.lock
ADD ./docker/Rakefile /app/highway/Rakefile

ADD ./docker/config/database.yml /app/highway/config/database.yml
RUN bundle exec rake db:migrate 
RUN bundle exec rake highway:bootstrap_ca && \
    bundle exec rake highway:bootstrap_masa 

RUN rm -f /app/highway/tmp/pids/server.pid

#FROM docker-registry.infra.01.k-ciralabs.ca/lestienne/distroless-ruby:2.6.0

#COPY --from=builder /app /app
#COPY --from=builder /usr/local/bundle /usr/local/bundle

ENV PATH="/usr/local/bundle/bin:${PATH}"

WORKDIR /app/highway

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"] 
