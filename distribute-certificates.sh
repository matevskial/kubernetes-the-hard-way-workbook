#!/usr/bin/env bash

# prerequisites 
# - should have ssh keys already set up so login works
# - jumpbox should have basic prerequisites setup
# - jumpbox should already have hosts set up

baseCertificatesDir="./certificates"

while read IP FQDN HOST SUBNET CLUSTER_ROLE; do
    if [[ "${CLUSTER_ROLE}" == "server" ]]; then
	   scp -P 1703 "$baseCertificatesDir/"ca.key "$baseCertificatesDir/"ca.key "$baseCertificatesDir/"ca.crt "$baseCertificatesDir/"kube-api-server.key "$baseCertificatesDir/"kube-api-server.crt "$baseCertificatesDir/"service-accounts.key "$baseCertificatesDir/"service-accounts.crt root@${HOST}:~/
   else
	   ssh root@${HOST} -p 1703 mkdir -p /var/lib/kubelet/
	   scp -P 1703 "$baseCertificatesDir/"ca.crt root@${HOST}:/var/lib/kubelet/
	   scp -P 1703 "$baseCertificatesDir/"${HOST}.crt root@${HOST}:/var/lib/kubelet/kubelet.crt
	   scp -P 1703 "$baseCertificatesDir/"${HOST}.key root@${HOST}:/var/lib/kubelet/kubelet.key
    fi
done < machines.txt
