#!/usr/bin/env bash

# Set up the Kubernetes The Hard Way jumpbox on Fedora.
# Steps follow kubernetes-the-hard-way/docs/02-jumpbox.md.
#   bash setup-jumpbox.sh
#   or
#   ./setup-jumpbox.sh

set -euo pipefail

echo "==> Install command line utilities"
sudo dnf -y install wget curl vim openssl git

echo "==> Append hostnames of cluster machines"
cat hosts-to-append.txt | sudo tee -a /etc/hosts > /dev/null

echo "==> Sync GitHub repository"
if [[ ! -d kubernetes-the-hard-way/.git ]]; then
  git clone --depth 1 \
    https://github.com/kelseyhightower/kubernetes-the-hard-way.git
fi

# Download lists and archive names in the lab use Debian architecture names.
case "$(uname -m)" in
  x86_64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *)
    echo "Unsupported architecture: $(uname -m). Expected x86_64 or aarch64." >&2
    exit 1
    ;;
esac

ARCHES=("amd64" "arm64")

for a in ${ARCHES[*]}; do
  mkdir -p downloads-${a}

  if [[ -x downloads-${a}/client/kubectl \
    && -x downloads-${a}/controller/kube-apiserver \
    && -x downloads-${a}/worker/kubelet \
    && -x downloads-${a}/worker/runc \
    && -d downloads-${a}/cni-plugins ]]; then
    echo "==> Binaries already organized under downloads-${a}/; skipping download and extract"
  else
    echo "==> Download binaries (${a})"
    wget -q --show-progress \
      --https-only \
      --timestamping \
      -P downloads-${a} \
      -i kubernetes-the-hard-way/"downloads-${a}.txt"
    
    if [[ -f "downloads-${a}-musl-compatible.txt" ]]; then
          echo "==> Also Download binaries (${a} musl)"
      wget -q --show-progress \
        --https-only \
        --timestamping \
        -P downloads-${a} \
        -i "downloads-${a}-musl-compatible.txt"
    fi

    echo "==> Extract and organize binaries"
    mkdir -p downloads-${a}/{client,cni-plugins,controller,worker}
    tar -xvf "downloads-${a}/crictl-v1.32.0-linux-${a}.tar.gz" \
      -C downloads-${a}/worker/
    tar -xvf "downloads-${a}/containerd-2.1.0-beta.0-linux-${a}.tar.gz" \
      --strip-components 1 \
      -C downloads-${a}/worker/
    tar -xvf "downloads-${a}/cni-plugins-linux-${a}-v1.6.2.tgz" \
      -C downloads-${a}/cni-plugins/
    tar -xvf "downloads-${a}/etcd-v3.6.0-rc.3-linux-${a}.tar.gz" \
      -C downloads-${a}/ \
      --strip-components 1 \
      "etcd-v3.6.0-rc.3-linux-${a}/etcdctl" \
      "etcd-v3.6.0-rc.3-linux-${a}/etcd"
    mv downloads-${a}/{etcdctl,kubectl} downloads-${a}/client/
    mv downloads-${a}/{etcd,kube-apiserver,kube-controller-manager,kube-scheduler} \
      downloads-${a}/controller/
    mv downloads-${a}/{kubelet,kube-proxy} downloads-${a}/worker/
    mv "downloads-${a}/runc.${a}" downloads-${a}/worker/runc

    if [[ -f "downloads-${a}-musl-compatible.txt" ]]; then
        echo "==> Also extract and organize binaries for musl"
        mkdir -p downloads-${a}/worker-musl

        tar -xvf "downloads-${a}/containerd-static-2.1.0-beta.0-linux-${a}.tar.gz" \
          --strip-components 1 \
          -C downloads-${a}/worker-musl
        
        tar -xvf "downloads-${a}/kubelet-1.33.1-r5.apk" \
          --strip-components 2 \
          -C downloads-${a}/worker-musl \
          usr/bin/kubelet
    fi

    shopt -s nullglob   # so that archives evaluates/expands to empty array instead of an array with the element that is the literal `downloads/*gz`
    archives=(downloads-${a}/*gz downloads-${a}/*apk)
    if ((${#archives[@]})); then
      rm -rf "${archives[@]}"
    fi
    shopt -u nullglob

    chmod +x downloads-${a}/{client,cni-plugins,controller,worker}/*
  fi
done

echo "==> Install kubectl"
sudo cp downloads-${ARCH}/client/kubectl /usr/local/bin/

echo "==> Verify kubectl"
kubectl version --client

echo "Jumpbox is ready in $(pwd)"
