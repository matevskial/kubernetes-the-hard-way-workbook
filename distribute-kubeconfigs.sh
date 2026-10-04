#!/usr/bin/env bash

# prerequisites 
# - should have ssh keys already set up so login works
# - jumpbox should have basic prerequisites setup
# - jumpbox should already have hosts set up

baseKubeconfigsDir="./kubeconfigs"

# copy kubeconfigs to nodes: kubeconfigs for kubelet and kube-proxy
while read IP FQDN HOST SUBNET CLUSTER_ROLE; do
    if [[ "${CLUSTER_ROLE}" == "node" ]]; then
        ssh root@${HOST} -p 1703 "mkdir -p /var/lib/{kube-proxy,kubelet}"

        scp -P 1703 "$baseKubeconfigsDir/"kube-proxy.kubeconfig \
            root@${HOST}:/var/lib/kube-proxy/kubeconfig \

        scp -P 1703 "$baseKubeconfigsDir/"${HOST}.kubeconfig \
            root@${HOST}:/var/lib/kubelet/kubeconfig
    fi
done < machines.txt

# copy kubeconfigs to server: kubeconfigs for admin, kube-controller-manager, kube-scheduler
while read IP FQDN HOST SUBNET CLUSTER_ROLE; do
    if [[ "${CLUSTER_ROLE}" == "server" ]]; then
        scp -P 1703 "$baseKubeconfigsDir/"admin.kubeconfig \
            "$baseKubeconfigsDir/"kube-controller-manager.kubeconfig \
            "$baseKubeconfigsDir/"kube-scheduler.kubeconfig \
            root@${HOST}:~/
    fi
done < machines.txt
