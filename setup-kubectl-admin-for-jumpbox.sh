#!/usr/bin/env bash

# Set up kubectl admin for the Kubernetes The Hard Way jumpbox on Fedora.
# prerequisites 
# - jumpbox should have basic prerequisites setup

set -euo pipefail

baseCertificatesDir="./certificates"

kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority="$baseCertificatesDir/"ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443

kubectl config set-credentials admin \
    --client-certificate="$baseCertificatesDir/"admin.crt \
    --client-key="$baseCertificatesDir/"admin.key

kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

kubectl config use-context kubernetes-the-hard-way
