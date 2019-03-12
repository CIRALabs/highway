FROM mcr314/shg_ruby_all:marchbreak as builder
FROM docker-registry.infra.01.k-ciralabs.ca/lestienne/distroless-ruby:2.6.1
#FROM ruby:2.6.1

COPY --from=builder /lib/x86_64-linux-gnu/liblzma*    \
     /lib/x86_64-linux-gnu/libcom_err*  \
     /lib/x86_64-linux-gnu/libkeyutils* \
     /lib/x86_64-linux-gnu/libgcc_s.so* \
     /lib/x86_64-linux-gnu/libidn.so*   /lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libgmp* \
     /usr/lib/x86_64-linux-gnu/libpq*                      \
     /usr/lib/x86_64-linux-gnu/libgss*                     \
     /usr/lib/x86_64-linux-gnu/libldap*                    \
     /usr/lib/x86_64-linux-gnu/libk5crypto*                \
     /usr/lib/x86_64-linux-gnu/liblber-2.4*                \
     /usr/lib/x86_64-linux-gnu/libsasl2.so*                \
     /usr/lib/x86_64-linux-gnu/libgnutls.so*               \
     /usr/lib/x86_64-linux-gnu/libp11-kit*                 \
     /usr/lib/x86_64-linux-gnu/libkrb*                     \
     /usr/lib/x86_64-linux-gnu/libtasn1*                   \
     /usr/lib/x86_64-linux-gnu/libnettle.so*               \
     /usr/lib/x86_64-linux-gnu/libhogweed.so*              \
     /usr/lib/x86_64-linux-gnu/libstdc++.so*               \
     /usr/lib/x86_64-linux-gnu/libffi.so*     /usr/lib/x86_64-linux-gnu/
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /usr/local/lib/ruby /usr/local/lib/ruby
COPY --from=builder /usr/share/zoneinfo/UTC /etc/localtime
COPY --from=builder /gems/highway /gems/highway
COPY --from=builder /bin/sash     /bin/sash
COPY --from=builder /usr/bin/strace /usr/bin/strace
COPY --from=builder /usr/bin/env  /usr/bin/env
ENV PATH="/usr/local/bundle/bin:${PATH}"
ENV GEM_HOME="/usr/local/bundle"
ENV CERTDIR=/app/certificates

COPY . /app/highway

WORKDIR /app/highway

EXPOSE 9443

CMD ["bundle", "_2.0.1_", "exec", "thin", "start", "--ssl",      \
    "--address", "::", "--port", "9443",                         \
    "--ssl-cert-file", "/app/certificates/server_prime256v1.crt",\
    "--ssl-key-file",  "/app/certificates/server_prime256v1.key" ]

