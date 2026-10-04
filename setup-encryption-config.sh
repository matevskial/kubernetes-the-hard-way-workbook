#!/usr/bin/env bash

# prerequisites 
# - jumpbox should have basic prerequisites setup

# sets kubernetes encryption at rest for kubernetes resources(secrets, etc)

encryptionConfigTmpDir="./encryption-config-tmp"

mkdir -p $encryptionConfigTmpDir
rm -rf $encryptionConfigTmpDir/*

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64) envsubst < kubernetes-the-hard-way/configs/encryption-config.yaml \
  > "$encryptionConfigTmpDir/"encryption-config.yaml

while read IP FQDN HOST SUBNET CLUSTER_ROLE; do
    if [[ "${CLUSTER_ROLE}" == "server" ]]; then
        scp -P 1703 "$encryptionConfigTmpDir/"encryption-config.yaml root@${HOST}:~/
    fi
done < machines.txt
