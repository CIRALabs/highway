FROM ruby:2.6.1 as builder

RUN apt-get update -qq && apt-get install -y postgresql-client libgmp10-dev libgmp10 sash busybox dnsutils && \
    apt-get remove -y git &&  \
    apt-get install -y git && \
    mkdir -p /app/highway && \
    mkdir -p /gems/highway && cd /gems/highway && \
    git config --global http.sslVerify "false" && \
    git clone --single-branch --branch cms-added https://github.com/CIRALabs/ruby-openssl.git && \
    git clone --single-branch --branch binary_http_multipart https://github.com/AnimaGUS-minerva/multipart_body.git && \
    git clone --single-branch --branch ecdsa_interface_openssl https://github.com/AnimaGUS-minerva/ruby_ecdsa.git && \
    git clone --single-branch --branch v0.6.0 https://github.com/mcr/ChariWTs.git

# build custom openssl with ruby-openssl patches

# remove directory with broken opensslconf.h,
# build in /src, as we do not need openssl once installed
RUN rm -rf /usr/include/x86_64-linux-gnu/openssl
RUN mkdir -p /src/highway
RUN cd /src/highway && git clone -b dtls-listen-refactor-1.1.1b git://github.com/mcr/openssl.git
RUN cd /src/highway/openssl && ./Configure --prefix=/usr --openssldir=/usr/lib/ssl --libdir=lib/linux-x86_64 no-idea no-mdc2 no-rc5 no-zlib no-ssl3 enable-unit-test linux-x86_64 && id && make
RUN cd /src/highway/openssl && make install_sw
RUN gem install rake-compiler
RUN cd /gems/highway/ruby-openssl && rake compile

WORKDIR /app/highway
RUN gem install bundler --source=http://rubygems.org

# install gems with extensions explicitely so that layers are cached.
RUN gem install -v1.10.1 nokogiri && \
    gem install -v1.2.7 eventmachine && \
    gem install -v2.3.1 nio4r && \
    gem install -v3.1.12 bcrypt && \
    gem install -v1.10.0 ffi && \
    gem install -v0.21.0 pg && \
    gem install -v1.7.2 thin && \
    gem install -v0.1.3 websocket-extensions && \
    gem install -v0.5.9.3 cbor
ADD ./docker/Gemfile /app/highway/Gemfile
ADD ./docker/Gemfile.lock /app/highway/Gemfile.lock
ADD ./docker/Rakefile /app/highway/Rakefile
RUN bundle _2.0.1_ install --system --no-deployment --gemfile=/app/highway/Gemfile && \
    bundle _2.0.1_ check

RUN rm -f /app/highway/tmp/pids/server.pid

FROM docker-registry.infra.01.k-ciralabs.ca/lestienne/distroless-ruby:2.6.1

COPY --from=builder ["/lib/x86_64-linux-gnu/liblzma*", \
        "/lib/x86_64-linux-gnu/libcom_err*", \
        "/lib/x86_64-linux-gnu/libkeyutils*", \
        "/lib/x86_64-linux-gnu/libgcc_s.so*", \
        "/lib/x86_64-linux-gnu/libidn.so*", \
        "/lib/x86_64-linux-gnu/libtinfo.so.5*", \
        "/lib/x86_64-linux-gnu/libncurses*", \
        "/lib/x86_64-linux-gnu/libreadline.so.7*", \
	"/lib/x86_64-linux-gnu/libjson-c.so.3*", \
	"/lib/x86_64-linux-gnu/libkeyutils.so*", \
	"/lib/x86_64-linux-gnu/liblzma.so*", \
        "/lib/x86_64-linux-gnu/"]
COPY --from=builder ["/usr/lib/x86_64-linux-gnu/libgmp*", \
     "/usr/lib/x86_64-linux-gnu/libbind9.so*", \
     "/usr/lib/x86_64-linux-gnu/libcrypto.so*", \
     "/usr/lib/x86_64-linux-gnu/libdns.so*", \
     "/usr/lib/x86_64-linux-gnu/libffi.so*", \
     "/usr/lib/x86_64-linux-gnu/libGeoIP.so*", \
     "/usr/lib/x86_64-linux-gnu/libgnutls.so*", \
     "/usr/lib/x86_64-linux-gnu/libgss*", \
     "/usr/lib/x86_64-linux-gnu/libgssapi_krb5.so*", \
     "/usr/lib/x86_64-linux-gnu/libhogweed.so*", \
     "/usr/lib/x86_64-linux-gnu/libicudata.so*", \
     "/usr/lib/x86_64-linux-gnu/libicuuc.so*", \
     "/usr/lib/x86_64-linux-gnu/libisccfg.so*", \
     "/usr/lib/x86_64-linux-gnu/libisc.so*", \
     "/usr/lib/x86_64-linux-gnu/libk5crypto*", \
     "/usr/lib/x86_64-linux-gnu/libkrb*", \
     "/usr/lib/x86_64-linux-gnu/libkrb5.so*", \
     "/usr/lib/x86_64-linux-gnu/libkrb5support.so*", \
     "/usr/lib/x86_64-linux-gnu/liblber-2.4*", \
     "/usr/lib/x86_64-linux-gnu/libldap*", \
     "/usr/lib/x86_64-linux-gnu/liblwres.so*", \
     "/usr/lib/x86_64-linux-gnu/libnettle.so*", \
     "/usr/lib/x86_64-linux-gnu/libp11-kit*", \
     "/usr/lib/x86_64-linux-gnu/libpq*", \
     "/usr/lib/x86_64-linux-gnu/libsasl2.so*", \
     "/usr/lib/x86_64-linux-gnu/libstdc++.so*", \
     "/usr/lib/x86_64-linux-gnu/libtasn1*", \
     "/usr/lib/x86_64-linux-gnu/libxml2.so*", \
     "/usr/lib/x86_64-linux-gnu/"]
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /usr/local/lib/ruby /usr/local/lib/ruby
COPY --from=builder /usr/share/zoneinfo/UTC /etc/localtime
COPY --from=builder /gems/highway /gems/highway
COPY --from=builder /bin/sash     /bin/sash
COPY --from=builder /usr/bin/env  /usr/bin/env
COPY --from=builder /bin/busybox  /bin/busybox

ENV PATH="/usr/local/bundle/bin:${PATH}"

COPY . /app/highway
ADD ./docker/Gemfile /app/highway/Gemfile
ADD ./docker/Gemfile.lock /app/highway/Gemfile.lock
ENV GEM_HOME="/usr/local/bundle"

WORKDIR /app/highway

EXPOSE 9443

CMD ["bundle", "_2.0.1_", "exec", "thin", "start", "--ssl",      \
    "--address", "0.0.0.0", "--port", "9443",                         \
    "--ssl-cert-file", "/app/certificates/server_prime256v1.crt",\
    "--ssl-key-file",  "/app/certificates/server_prime256v1.key" ]

