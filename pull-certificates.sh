#!/usr/bin/env bash

# prerequisites 
# - should have ssh keys already set up so login works
# - jumpbox should have basic prerequisites setup
# - jumpbox should already have hosts set up

#  pull the certificates that are configured and used by this cluster

# currently, only ca cert


baseCertificatesDir="./certificates-distributed"

ensureBaseCertificatesDirExists() {
    mkdir -p $baseCertificatesDir
}

ensureBaseCertificatesDirExists

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

# pull ca cert

scp -P 1703 root@${serverHost}:/var/lib/kubernetes/ca.crt "$baseCertificatesDir/"
scp -P 1703 root@${serverHost}:/var/lib/kubernetes/ca.key "$baseCertificatesDir/"
