#!/usr/bin/env bash

# prerequisites 
# - should have ssh keys already set up so login works
# - jumpbox should have basic prerequisites setup
# - jumpbox should already have hosts set up

set -euo pipefail

while read IP FQDN HOST SUBNET; do
    CMD="sed -i 's/^127.0.1.1.*/127.0.1.1\t${FQDN} ${HOST}/' /etc/hosts"
    ssh -n root@${HOST} -p 1703 "$CMD"
    scp -P 1703 hosts-to-append.txt root@${HOST}:~/
    ssh -n root@${HOST} -p 1703 "cat hosts-to-append.txt >> /etc/hosts"
done < machines.txt
