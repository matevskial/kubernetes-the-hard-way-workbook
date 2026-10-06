# Workbook and Notes written while going through labs of kubernetes-the-hard-way

- Also contains scripts I wrote while following the labs.

## Prerequizites

cd into this directory

git clone https://github.com/kelseyhightower/kubernetes-the-hard-way.git


```
sudo dnf install wget curl vim openssl git
```


## Labs

Since my setup is this

```
# IP         #FQDN                   #HOST
192.168.0.27 server.kubernetes.local matevskilabs
192.168.1.27 node-0.kubernetes.local matevskilabs-peroslaptop 10.200.0.0/24
```

matevskilabs - a VM running on host matevskilabs-workstation
matevskilabs-peroslaptop - an old laptop

I already had root ssh set up

Additionally, I set up etc/hosts like this:

- for matevskilabs-workstation: 
    - appended hosts-to-append.txt
- for matevskilabs and matevskilabs-peroslaptop:
    - executed setup-hosts-for-servers.sh
    
Note: we don't have 127.0.1.1 entries in /etc/hosts - we will see if this makes problems

For the step where I set up etcd systemd service, I needed to do some `restorecon`(selinux related) commands

```bash
root@host:~# restorecon -v /etc/systemd/system/etcd.service 
Relabeled /etc/systemd/system/etcd.service from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:systemd_unit_file_t:s0
```

```bash
root@host:~# restorecon -v /usr/local/bin/etcd
Relabeled /usr/local/bin/etcd from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:bin_t:s0
```

For the step where I set up kubernetes controller services, I needed to do some `restorecon`(selinu related) command

```bash
root@host:~# restorecon -v /usr/local/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl}
Relabeled /usr/local/bin/kube-apiserver from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:bin_t:s0
Relabeled /usr/local/bin/kube-controller-manager from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:bin_t:s0
Relabeled /usr/local/bin/kube-scheduler from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:bin_t:s0
Relabeled /usr/local/bin/kubectl from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:bin_t:s0
```

These directories are used: `/etc/etcd`, `/var/lib/etcd`, `/etc/kubernetes`, `/var/lib/kubernetes`

For systemd services

```bash
root@host:~# restorecon -v /etc/systemd/system/kube-apiserver.service 
Relabeled /etc/systemd/system/kube-apiserver.service from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:systemd_unit_file_t:s0

root@host:~# restorecon -v /etc/systemd/system/kube-controller-manager.service 
Relabeled /etc/systemd/system/kube-controller-manager.service from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:systemd_unit_file_t:s0

root@host:~# restorecon -v /etc/systemd/system/kube-scheduler.service 
Relabeled /etc/systemd/system/kube-scheduler.service from unconfined_u:object_r:admin_home_t:s0 to unconfined_u:object_r:systemd_unit_file_t:s0
```

# General knowledge notes

L2 is network connectivity(eth, wifi)

L3 is ip connectivity

Introduction to CNI, the Container Network Interface Project - Bryan Boreham & Dan Williams
nice video for a introduction
https://www.youtube.com/watch?v=YjjrQiJOyME

Networking with Kubernetes
nice overview video
notes that pod-to-pod comunication can be done with a flat routed topology(i.e nodes advertize their ip ddresses so router can build a routing table) or using an overlay(for flexibility)
with kubernetes nodeport, regardless of which node I hit, I will access the exposed pod. Imagine a pod is deployed on node1 and I try to access it using the ip of node2, I will access it successfully.
https://www.youtube.com/watch?v=WwQ62OyCNz4

Container Networking From Scratch - Kristen Jacobs, Oracle
useful to watch before watching the next video
in the context of linux, network namespace is one instance of networkign stack: separate list of interfaces, separate iptables, separate routing table
https://www.youtube.com/watch?v=6v_BDHIgOY8

Understanding Kubernetes Networking in 30 Minutes - Ricardo Katz & James Strong
https://www.youtube.com/watch?v=Mj04QOqAaJ8
