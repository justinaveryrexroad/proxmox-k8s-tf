#! /usr/bin/env bash
set +x

# seup kernel modules
cat <<EOF |  tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# setup required sysctl params, ipv4 port forwarding
cat <<EOF |  tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# setup networking
sysctl --system
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Download dependencies containerd
wget https://github.com/containerd/containerd/releases/download/v1.7.0/containerd-1.7.0-linux-amd64.tar.gz
wget https://github.com/opencontainers/runc/releases/download/v1.1.7/runc.amd64
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

# Install runc
install -m 755 runc.amd64 /usr/local/sbin/runc

# Install containerd
tar Cxzvf /usr/local/ containerd-1.7.0-linux-amd64.tar.gz
chown root:root containerd.service
mkdir -p /usr/local/lib/systemd/system
mv containerd.service /usr/local/lib/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd

# Install CNI
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin/ cni-plugins-linux-amd64-v1.2.0.tgz

mkdir /etc/containerd
sh -c "containerd config default > /etc/containerd/config.toml"

mkdir -p /etc/apt/keyrings
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" |  tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "Activate SystemdCgroup"
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
