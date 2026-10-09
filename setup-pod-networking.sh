#!/usr/bin/env bash

# prerequisites 
# - should have ssh keys already set up so login works
# - jumpbox should have basic prerequisites setup
# - jumpbox should already have hosts set up
# - cluster should be initialized and running

# assumtions
# - server and nodes are either fedora server or alpine musl openrc

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

# add routes to server node
while read IP FQDN HOST SUBNET CLUSTER_ROLE OS ARCH; do
    if [[ "${CLUSTER_ROLE}" == "node" ]]; then
        # note for some specific networ setups
        # the below command may apply if ${IP} is not directly tied to the dev but is tied to another ip route entry
        # ssh root@${serverHost} -p 1703 ip route add ${SUBNET} via ${IP} dev <eth-device> onlink
        ssh root@${serverHost} -p 1703 ip route add ${SUBNET} via ${IP}
    fi
done < machines.txt

# add routes to worker nodes
while read IP FQDN HOST SUBNET CLUSTER_ROLE OS ARCH; do
    if [[ "${CLUSTER_ROLE}" == "node" ]]; then
        while read OTHER_IP OTHER_FQDN OTHER_HOST OTHER_SUBNET OTHER_CLUSTER_ROLE OTHER_OS OTHER_ARCH; do
            if [[ "${OTHER_CLUSTER_ROLE}" == "node" && "${OTHER_HOST}" != "${HOST}" ]]; then
                echo "comb: $HOST -> $OTHER_HOST"
                ssh root@${HOST} -p 1703 ip route add ${OTHER_SUBNET} via ${OTHER_IP}
            fi
        done < machines.txt
    fi
done < machines.txt
