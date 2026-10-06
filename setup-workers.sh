#!/usr/bin/env bash

# prerequisites 
# - should have ssh keys already set up so login works
# - jumpbox should have basic prerequisites setup
# - jumpbox should already have hosts set up

# assumtions
# - fedora server
# - swap is zram

baseConfigsDir="./configs"

ensureBaseConfigsDirExists() {
    mkdir -p $baseConfigsDir
}

setupAndTransferConfigFilesConfiguredForEachNode() {
    host=$3
    subnet=$4

    echo "==> Setting and transfering config files for host $host"
    
    sed "s|SUBNET|$subnet|g" \
        kubernetes-the-hard-way/configs/10-bridge.conf > "$baseConfigsDir/"10-bridge-${host}.conf
    
    sed "s|SUBNET|$subnet|g" \
        kubernetes-the-hard-way/configs/kubelet-config.yaml > "$baseConfigsDir/"kubelet-config-${host}.yaml
    
    scp -P 1703 "$baseConfigsDir/"10-bridge-${host}.conf root@${host}:~/10-bridge.conf
    scp -P 1703 "$baseConfigsDir/"kubelet-config-${host}.yaml root@${host}:~/kubelet-config.yaml
}

transferComponentBinariesAndConfigs() {
    host=$3

    echo "==> Transfering binaries and config files for host $host"

    scp -P 1703 \
        downloads/worker/* \
        downloads/client/kubectl \
        kubernetes-the-hard-way/configs/99-loopback.conf \
        kubernetes-the-hard-way/configs/containerd-config.toml \
        kubernetes-the-hard-way/configs/kube-proxy-config.yaml \
        kubernetes-the-hard-way/units/containerd.service \
        kubernetes-the-hard-way/units/kubelet.service \
        kubernetes-the-hard-way/units/kube-proxy.service \
        root@${host}:~/

    scp -P 1703 \
        downloads/cni-plugins/* \
        root@${host}:~/cni-plugins/
}

installingOsDependencies() {
    host=$3

    echo "==> Installing OS dependencies for host $host"
    ssh root@${host} -p 1703 dnf install -y install socat conntrack ipset kmod
}

configureAndEnableComponents() {
    host=$3

    echo "==> Configuring and enabling components for host $host"

    ssh root@${host} -p 1703 mkdir -p \
        /etc/cni/net.d \
        /opt/cni/bin \
        /var/lib/kubelet \
        /var/lib/kube-proxy \
        /var/lib/kubernetes \
        /var/run/kubernetes
    
    ssh root@${host} -p 1703 mv crictl kube-proxy kubelet runc \
    /usr/local/bin/

    ssh root@${host} -p 1703 restorecon -v /usr/local/bin/{crictl,kube-proxy,kubelet,runc}

    ssh root@${host} -p 1703 mv containerd containerd-shim-runc-v2 containerd-stress /bin/

    ssh root@${host} -p 1703 restorecon -v /bin/{containerd,containerd-shim-runc-v2,containerd-stress}

    ssh root@${host} -p 1703 mv cni-plugins/* /opt/cni/bin/

    ssh root@${host} -p 1703 restorecon -v /opt/cni/bin/*

    ssh root@${host} -p 1703 mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/

    # To ensure network traffic crossing the CNI bridge network is processed by iptables, load and configure the br-netfilter kernel module 
    # systemd-modules-load.service loads every *.conf file from /etc/modules-load.d
    ssh root@${host} -p 1703 modprobe br-netfilter
    ssh root@${host} -p 1703 'echo "br-netfilter" > /etc/modules-load.d/br-netfilter-module.conf'
    ssh root@${host} -p 1703 'echo "net.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.d/kubernetes.conf'
    ssh root@${host} -p 1703 'echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf'
    ssh root@${host} -p 1703 sysctl -p /etc/sysctl.d/kubernetes.conf

    # containerd
    ssh root@${host} -p 1703 mkdir -p /etc/containerd/
    ssh root@${host} -p 1703 mv containerd-config.toml /etc/containerd/config.toml
    ssh root@${host} -p 1703 mv containerd.service /etc/systemd/system/
    ssh root@${host} -p 1703 restorecon -v /etc/systemd/system/containerd.service

    # kubelet
    ssh root@${host} -p 1703 mv kubelet-config.yaml /var/lib/kubelet/
    ssh root@${host} -p 1703 mv kubelet.service /etc/systemd/system/
    ssh root@${host} -p 1703 restorecon -v /etc/systemd/system/kubelet.service

    # kube-proxy
    ssh root@${host} -p 1703 mv kube-proxy-config.yaml /var/lib/kube-proxy/
    ssh root@${host} -p 1703 mv kube-proxy.service /etc/systemd/system/
    ssh root@${host} -p 1703 restorecon -v /etc/systemd/system/kube-proxy.service

    # systemd enable services
    ssh root@${host} -p 1703 systemctl daemon-reload
    ssh root@${host} -p 1703 systemctl enable containerd kubelet kube-proxy

    # we won't start services here since latest step will reboot the host
}

disableZram() {
    host=$3
    echo "==> Disabling zram for host $host"
    ssh root@${host} -p 1703 swapoff -a
    ssh root@${host} -p 1703 systemctl mask dev-zram0.swap
}

reboot() {
    host=$3
    echo "==> Rebooting host $host"
    ssh root@${host} -p 1703 reboot
}

ensureBaseConfigsDirExists

while read IP FQDN HOST SUBNET CLUSTER_ROLE; do
    if [[ "${CLUSTER_ROLE}" == "node" ]]; then
        setupAndTransferConfigFilesConfiguredForEachNode $IP $FQDN $HOST $SUBNET $CLUSTER_ROLE
        transferComponentBinariesAndConfigs $IP $FQDN $HOST $SUBNET $CLUSTER_ROLE
        installingOsDependencies $IP $FQDN $HOST $SUBNET $CLUSTER_ROLE
        configureAndEnableComponents $IP $FQDN $HOST $SUBNET $CLUSTER_ROLE
        disableZram $IP $FQDN $HOST $SUBNET $CLUSTER_ROLE
        reboot $IP $FQDN $HOST $SUBNET $CLUSTER_ROLE
    fi
done < machines.txt
