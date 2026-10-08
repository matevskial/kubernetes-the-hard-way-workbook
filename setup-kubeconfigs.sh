#!/usr/bin/env bash

# prerequisites 
# - jumpbox should have basic prerequisites setup

# set up the certificate authority(CA) that will be used to generate all certificates

set -euo pipefail

baseCertificatesDir="./certificates"
baseKubeconfigsDir="./kubeconfigs"

ensureBaseKubeconfigsDirExists() {
    mkdir -p $baseKubeconfigsDir
}

ensureBaseKubeconfigsDirExists

serverHost=""
while read IP FQDN HOST SUBNET CLUSTER_ROLE OS ARCH; do
    if [[ "${CLUSTER_ROLE}" == "server" ]]; then
        serverHost=$FQDN
    fi
done < machines.txt

if [[ -z "${serverHost}" ]]; then
    echo "serverHost of kubernetes cluster not determined, is machines.txt set right?"
    exit 1
fi

# set up kubeconfigs for nodes
while read IP FQDN HOST SUBNET CLUSTER_ROLE OS ARCH; do
    if [[ "${CLUSTER_ROLE}" == "node" ]]; then
        kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority="$baseCertificatesDir/"ca.crt \
    --embed-certs=true \
    --server=https://"$serverHost":6443 \
    --kubeconfig="$baseKubeconfigsDir/"${HOST}.kubeconfig

        kubectl config set-credentials system:node:${HOST} \
    --client-certificate="$baseCertificatesDir/"${HOST}.crt \
    --client-key="$baseCertificatesDir/"${HOST}.key \
    --embed-certs=true \
    --kubeconfig="$baseKubeconfigsDir/"${HOST}.kubeconfig

        kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${HOST} \
    --kubeconfig="$baseKubeconfigsDir/"${HOST}.kubeconfig

        kubectl config use-context default \
    --kubeconfig="$baseKubeconfigsDir/"${HOST}.kubeconfig
    fi
done < machines.txt

# setup kubeconfigs for kube-proxy, kube-controller-manager, kube-scheduler, admin
components=(
    "kube-proxy" "kube-controller-manager"
    "kube-scheduler" "admin"
)

for c in ${components[*]}; do
    kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority="$baseCertificatesDir/"ca.crt \
    --embed-certs=true \
    --server=https://"$serverHost":6443 \
    --kubeconfig="$baseKubeconfigsDir/"$c.kubeconfig

    kubectl config set-credentials system:$c \
    --client-certificate="$baseCertificatesDir/"$c.crt \
    --client-key="$baseCertificatesDir/"$c.key \
    --embed-certs=true \
    --kubeconfig="$baseKubeconfigsDir/"$c.kubeconfig

    kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:$c \
    --kubeconfig="$baseKubeconfigsDir/"$c.kubeconfig

    kubectl config use-context default \
    --kubeconfig="$baseKubeconfigsDir/"$c.kubeconfig
done
