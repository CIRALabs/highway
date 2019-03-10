FROM mcr314/shg_ruby_all:marchbreak as builder
#FROM docker-registry.infra.01.k-ciralabs.ca/lestienne/distroless-ruby:2.6.1
FROM ruby:2.6.1

COPY --from=builder /usr/lib/x86_64-linux-gnu/libgmp* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /gems/highway /gems/highway
COPY --from=builder /bin/sash     /bin/sash
COPY --from=builder /usr/bin/env  /usr/bin/env
ENV PATH="/usr/local/bundle/bin:${PATH}"

WORKDIR /app/highway

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
