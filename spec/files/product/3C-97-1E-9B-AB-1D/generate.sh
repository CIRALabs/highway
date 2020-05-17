#!/bin/sh

IP6_ULA=fd9e:7354:b359::1
IP6_ULA_PREFIX=fd9e:7354:b359::/48
ULA_HOSTNAME=n9e7354.r.dasblinkenled.org

printf "[ req ]\ndistinguished_name=shg\n[shg]\n[distinguished_name]\n[SAN]\nsubjectAltName=DNS:${ULA_HOSTNAME},DNS:mud.${ULA_HOSTNAME}\n" >shg.ossl.cnf


openssl req -new -newkey ec \
        -pkeyopt ec_paramgen_curve:prime256v1 -pkeyopt ec_param_enc:named_curve \
        -nodes -subj "/CN=${ULA_HOSTNAME}" \
                -keyout key.pem -out request.csr -outform DER \
                -reqexts SAN \
                -config shg.ossl.cnf

openssl ec -in key.pem -pubout -outform der | base64 >pub.b64

