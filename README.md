# talos-cluster-gitops

## Creating Talos cluster(single node)
```bash
# clone this repo
cd <repo>
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

## Bootstrapping cluster

We manage Helm package installations in the cluster using ArgoCD. Before deploying applications with ArgoCD, we manually provision ArgoCD and its supporting tools using the Terraform Helm provider.

### Pre-Req

#### Local storage
Making changes to the cluster to configure [local storage](https://www.talos.dev/v1.7/kubernetes-guides/configuration/local-storage/)

add the following to controlplane.yaml

```yaml
...
        extraMounts:
            - destination: /var/openebs/local # Destination is the absolute path where the mount will be placed in the >              type: bind # Type specifies the mount kind.
              source: /var/openebs/local # Source specifies the source path of the mount.
              # Options are fstab style mount options.
              options:
                - bind
                - rshared
                - rw
```
we are deploying openebs local storage as the local storage solution
```bash
talosctl -n <IP address of your control plane> apply-config --file controlplane.yaml
```

#### Removing taint from control plane node

```bash
kubectl taint node <Control plane node name> node-role.kubernetes.io/control-plane:NoSchedule-
```

#### Deploying argo-cd and sealed-secrets-controller

```bash
cd terraform/
terraform init
terraform validate
terraform plan
terraform apply
```

#### Deploying SealedSecret for argocd repository and app of apps argo applications

create a secret for adding your first argocd repository
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitops-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: <REPO>
  password: <TOKEN>
  username: <USERNAME>
```
we are going to convert this secret to a sealed secret

```bash
cat gitops-repo.yaml | kubeseal --format yaml > app2repo.yaml
kubectl apply -f app2repo.yaml
# creating our first argocd application which can bootstrap the rest of the cluster, dont forget to replace templated values
kubectl apply -f helm/templates/bootstrap.yaml
```