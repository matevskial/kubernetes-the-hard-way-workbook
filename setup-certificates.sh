#!/usr/bin/env bash

# prerequisites 
# - jumpbox should have basic prerequisites setup

# set up the certificate authority(CA) that will be used to generate all certificates

set -euo pipefail

baseCertificatesDir="./certificates"

ensureBaseCertificatesDirExists() {
    mkdir -p $baseCertificatesDir
}

ensureBaseCertificatesDirExists

# private key of CA
openssl genrsa -out "$baseCertificatesDir/"ca.key 4096

# CA certificate
openssl req -x509 -new -sha512 -noenc \
    -key "$baseCertificatesDir/"ca.key -days 3653 \
    -config ca.conf \
    -out "$baseCertificatesDir/"ca.crt

certs=(
  "admin" "matevskilabs-peroslaptop"
  "kube-proxy" "kube-scheduler"
  "kube-controller-manager"
  "kube-api-server"
  "service-accounts"
)

for i in ${certs[*]}; do
  # private key
  openssl genrsa -out "$baseCertificatesDir/""${i}.key" 4096

  # signing request: contains public key, information about entity and signature
  # it's safe to delete after a certificate is issued
  # sometimes it's kept for documentation purposes
  openssl req -new -key "$baseCertificatesDir/""${i}.key" -sha256 \
    -config "ca.conf" -section ${i} \
    -out "$baseCertificatesDir/""${i}.csr"

  # the actual certificate issued by the CA
  openssl x509 -req -days 3653 -in "$baseCertificatesDir/""${i}.csr" \
    -copy_extensions copyall \
    -sha256 -CA "$baseCertificatesDir/""ca.crt" \
    -CAkey "$baseCertificatesDir/""ca.key" \
    -CAcreateserial \
    -out "$baseCertificatesDir/""${i}.crt"
done

