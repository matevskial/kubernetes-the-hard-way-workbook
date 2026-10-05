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

mkdir -p downloads

if [[ -x downloads/client/kubectl \
   && -x downloads/controller/kube-apiserver \
   && -x downloads/worker/kubelet \
   && -x downloads/worker/runc \
   && -d downloads/cni-plugins ]]; then
  echo "==> Binaries already organized under downloads/; skipping download and extract"
else
  echo "==> Download binaries (${ARCH})"
  wget -q --show-progress \
    --https-only \
    --timestamping \
    -P downloads \
    -i kubernetes-the-hard-way/"downloads-${ARCH}.txt"

  echo "==> Extract and organize binaries"
  mkdir -p downloads/{client,cni-plugins,controller,worker}
  tar -xvf "downloads/crictl-v1.32.0-linux-${ARCH}.tar.gz" \
    -C downloads/worker/
  tar -xvf "downloads/containerd-2.1.0-beta.0-linux-${ARCH}.tar.gz" \
    --strip-components 1 \
    -C downloads/worker/
  tar -xvf "downloads/cni-plugins-linux-${ARCH}-v1.6.2.tgz" \
    -C downloads/cni-plugins/
  tar -xvf "downloads/etcd-v3.6.0-rc.3-linux-${ARCH}.tar.gz" \
    -C downloads/ \
    --strip-components 1 \
    "etcd-v3.6.0-rc.3-linux-${ARCH}/etcdctl" \
    "etcd-v3.6.0-rc.3-linux-${ARCH}/etcd"
  mv downloads/{etcdctl,kubectl} downloads/client/
  mv downloads/{etcd,kube-apiserver,kube-controller-manager,kube-scheduler} \
    downloads/controller/
  mv downloads/{kubelet,kube-proxy} downloads/worker/
  mv "downloads/runc.${ARCH}" downloads/worker/runc

 
  shopt -s nullglob   # so that archives evaluates/expands to empty array instead of an array with the element that is the literal `downloads/*gz`
  archives=(downloads/*gz)
  if ((${#archives[@]})); then
    rm -rf "${archives[@]}"
  fi
  shopt -u nullglob

  chmod +x downloads/{client,cni-plugins,controller,worker}/*
fi

echo "==> Install kubectl"
sudo cp downloads/client/kubectl /usr/local/bin/

echo "==> Verify kubectl"
kubectl version --client

echo "Jumpbox is ready in $(pwd)"
