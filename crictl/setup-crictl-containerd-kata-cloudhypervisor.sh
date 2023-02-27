#! /bin/bash
# This script is used to setup an enviroment for crictl + containerd + kata + cloudhypervisor

echo "setup begin!"
cd $HOME

# install kata
echo "install kata, cloudhypervisor"
wget https://github.com/kata-containers/kata-containers/releases/download/3.0.1/kata-static-3.0.1-x86_64.tar.xz
tar -xf kata-static-3.0.1-x86_64.tar.xz
sudo cp -r opt/kata /opt
sudo ln -s /opt/kata/bin/containerd-shim-kata-v2 /usr/bin/containerd-shim-kata-v2
sudo ln -s /opt/kata/bin/cloud-hypervisor /usr/bin/cloud-hypervisor
sudo ln -s /opt/kata/bin/kata-runtime /usr/bin/kata-runtime
sudo ln -s /opt/kata/bin/kata-collect-data.sh /usr/bin/kata-collect-data.sh
sudo ln -s /opt/kata/bin/kata-monitor /usr/bin/kata-monitor

# install containerd
echo "install containerd"
wget https://github.com/containerd/containerd/releases/download/v1.6.16/cri-containerd-1.6.16-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local cri-containerd-1.6.16-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
if [ -f "/usr/local/lib/systemd/system/containerd.service" ];then
	sudo mv /usr/local/lib/systemd/system/containerd.service /usr/local/lib/systemd/system/containerd.service.origin
elif [ ! -d "/usr/local/lib/systemd/system" ];then
	sudo mkdir -p /usr/local/lib/systemd/system
fi
# do it if using systemd
sudo cp containerd.service /usr/local/lib/systemd/system/
# sudo tar --no-overwrite-dir -C / -xzf cri-containerd-1.6.16-linux-amd64.tar.gz

# install cni-plugin
echo "install cni-plugin"
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz

# start containerd service
echo "start containerd service"
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# config cni plugin https://github.com/containernetworking/cni
echo "config cni plugin"
if [ -f "/etc/cni/net.d/10-mynet.conf" ];then
	sudo mv /etc/cni/net.d/10-mynet.conf /etc/cni/net.d/10-mynet.conf.origin
elif [ ! -d "/etc/cni" ];then
	sudo mkdir -p /etc/cni/net.d
elif [ ! -d "/etc/cni/net.d" ];then
	sudo mkdir /etc/cni/net.d
fi
sudo touch /etc/cni/net.d/10-mynet.conf
sudo cat>/etc/cni/net.d/10-mynet.conf<<EOF
{
	"cniVersion": "0.2.0",
	"name": "mynet",
	"type": "bridge",
	"bridge": "cni0",
	"isGateway": true,
	"ipMasq": true,
	"ipam": {
		"type": "host-local",
		"subnet": "172.19.0.0/24",
		"routes": [
			{ "dst": "0.0.0.0/0" }
		]
	}
}
EOF

# config containerd
echo "config containerd and restart service"
if [ ! -d "/etc/containerd"]; then
	sudo mkdir /etc/containerd
fi
sudo sh -c "containerd config dump > /etc/containerd/config.toml" 
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.orgin 
wget https://raw.githubusercontent.com/chzhyang/coldstartup/main/crictl/containerd-config.toml
sudo cp containerd-config.toml /etc/containerd/config.toml
sudo systemctl restart containerd

# config kata runtime plugin
echo "config kata runtime plugin"
sudo rm configuration.toml
sudo ln -s configuration-clh.toml configuration.toml

# pull base image
echo "pull base image for pod sandbox"
sudo crictl pull registry.k8s.io/pause:3.6

echo "setup complete!"