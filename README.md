# talos-cluster-gitops

## Creating Talos cluster(single node)
```bash
# clone this repo
# Download the talos iso
wget --timestamping https://github.com/siderolabs/talos/releases/download/v1.7.6/metal-amd64.iso -O tmp/metal-amd64.iso

cd vagrant/
# Bring up the vagrant environment
vagrant up --provider=libvirt
# Check the status
vagrant status

# Find out the IP addresses assigned by the libvirt DHCP by running
virsh list | grep talos | awk '{print $2}' | xargs -t -L1 virsh domifaddr

# Generate a machine configuration
talosctl gen config my-cluster https://<IP address of your control plane>:6443 --install-disk /dev/vda --force
# Apply the configuration to the initial control plane node
talosctl -n <IP address of your control plane> apply-config --insecure --file controlplane.yaml
# Set up your shell to use the generated talosconfig and configure its endpoints (use the IPs of the control plane nodes)
export TALOSCONFIG=$(realpath ./talosconfig) && talosctl config endpoint <IP address of your control plane>
# Bootstrap the Kubernetes cluster from the initial control plane node
talosctl -n <IP address of your control plane> bootstrap

# Retrieve the kubeconfig from the cluster
talosctl -n <IP address of your control plane> kubeconfig ./kubeconfig
# List the nodes in the cluster
kubectl --kubeconfig ./kubeconfig get node -owide

```