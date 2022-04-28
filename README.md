# k8s-configs

This [Ansible](https://www.ansible.com/) playbook offers a highly-optimized [Kubernetes](https://kubernetes.io/) package for the [mdx](https://mdx.jp/) computing platform.

The playbook automatically installs the following components as a usable form within 10 minites:
- [k0s](https://k0sproject.io/) (a light-weight Kubernetes distribution)
- [containerd](https://containerd.io/) and nvidia container runtime (as container runtimes on computing nodes)
- [Topology](https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/), [CPU](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/), and [memory managers](https://kubernetes.io/docs/tasks/administer-cluster/memory-manager/) (for NUMA-aware, static resource partitioning)
- [Docker](https://www.docker.com/) (for building container images on the bastion host)
- [Harbor](https://goharbor.io/) private container repository with private self-certificate 
- [Exascaler File CSI driver](https://github.com/DDNStorage/exa-csi-driver) (as a container persistent volume driver)
- [NVIDIA's GPU](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/overview.html) and [network operators](https://docs.nvidia.com/networking/display/COKAN10/Network+Operator) (for A100 GPUs and ROCEv2 networking)
- [MetalLB](https://metallb.universe.tf/) (as a load balancer)
- [MPI operator](https://github.com/kubeflow/mpi-operator) (for supporting parallel computing jobs)
- [Spark on k8s Operator](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator) with [RAPIDS and UCX shuffle manager](https://rapids.ai/) (for large data processing)
- [Kube Prometheus stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) (for monitoring and alerting)

This playbook was written being inspired from the [machine-configs](https://github.com/mdx-jp/machine-configs), but doesn't currently share the code with it.

## Prerequisites

This playbook assumes the following virtual machines exist in a user tenant. All machines should be installed with Ubuntu 20.04 server.

- a single bastion host 
  - with 1 or a higher number of CPU cores, PortGroup networking
- a single harbor private repository host
  - with 2 or a higher number of CPU cores, 160GB or larger disk capacity, PortGroup networking
- a single kubernetes master node 
  - with 2 or a higher number of CPU cores, PortGroup networking
- 0 or a larger number of kubernetes' computing nodes. 
  - each with 2 or a higher number of CPU cores, 100GB or larger disk capacity, SR-IOV (RDMA) networking
- 0 or a larger number of GPU nodes. 
  - each with 1 or a larger number of GPUs, 100GB or larger disk capacity, SR-IOV (RDMA) networking

We assume that all the above nodes are SSH-accessible from the basion host by using public key authentication without entering passwords (Initial passwords must be set on each node beforehand after OS installation).

For example, use the ``-A`` (ForwardAgent) option to allow recursive SSH access to other nodes using the same public/private key pairs.
```sh
% eval `ssh-agent`
% ssh-add
% ssh -A (bastion's IP address)
```

## Getting Started

1. Install the ansible package on the bastion host.
```sh
$ sudo apt install ansible
```

2. Install the dependent pip3 packages (kubernets and openshift) and Ansible galaxy collection (kubernetes.core).
```sh
$ install_dep_packages.py
```

3. Copy the inventory file from the template and rewrite the file accordingly. 
```sh
$ cp inventory.ini.template inventory.ini
$ mg inventory.ini
```
At least, fill in the IP addresses of each node (by ansible_host and roce_host). Copy the kube-node and kube-gpu entries as needed.
```ansible
[bastion_host]
bastion ansible_host=

[registry]
harbor ansible_host=

[kube_master]
kube-master ansible_host=

[kube_node]
kube-node1 ansible_host= roce_host=
kube-node2 ansible_host= roce_host=

[kube_gpu]
kube-gpu1 ansible_host= roce_host=
kube-gpu2 ansible_host= roce_host=
```

4. Copy the password file from the template and rewrite it. 
```sh
$ cp vault.yaml.template vault.yaml
$ mg vault.yaml
```

Set the harbor's admin and database passwords and grafana password.

```yaml
---
harbor_admin_password:
harbor_db_password:

grafana_password:
```

5. Encrypt the above file by Ansible Vault (set the Vault password).
```sh
$ encrypt_vault.sh
```

6. Run the playbook and wait until the Kubernetes platform is constructed.
```sh
$ play.sh
```

## How to use the cluster

The ``examples`` directory contains some sample manifest files to show how to use the cluster.

### Using kubectl and helm
The kubectl and helm commands are installed on the bastion host.

```sh
bastion:~$ kubectl get node
NAME         STATUS   ROLES    AGE    VERSION
kube-gpu1    Ready    <none>   6d9h   v1.23.3+k0s
kube-gpu2    Ready    <none>   6d9h   v1.23.3+k0s
kube-node1   Ready    <none>   6d9h   v1.23.3+k0s
kube-node2   Ready    <none>   6d9h   v1.23.3+k0s
```

### Accessing Kubernetes cluster from LENS
LENS should be installed on an operator side machine that accesses the bastion host via SSH. 

Copy and paste the ``.kube/config`` file to the LENS configuration and rewrite the kube-master's address to  ``localhost`` or ``127.0.0.1``.

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ...
    server: https://kube-master:6443 # to localhost or 127.0.0.1
  name: k0s-cluster
```

When accessing, use SSH port forwarding to make kube-master accessible from LENS.

```sh
% ssh -L 6443:(kube-master's IP address):6443 -A (bastion's IP address)
```

### Accessing Harbor 
Harbor accepts connections on 443 port of the Harbor host. Use SSH port forwarding to make it accessible from the local web browser.
```ssh
% ssh -L 8443:(harbor's IP address):443 -A (bastion's IP address)
```
Harbor's admin password was set during installation.

### Pushing container images to Harbor

Before pushing a container image to the Harbor, the user must login to the Harbor registory.

```sh
bastion:~$ sudo docker login harbor.internal
bastion:~$ sudo docker build . -t harbor.internal/library/<image name>:<tag>
bastion:~$ sudo docker push harbor.internal/library/<image name>:<tag>
```

### Accessing Grafana
To access Grafana dashboard, use the ``kubectl port-forward`` and SSH port forwarding. The Grafana's password was set in ``vault.yaml`` during installation process.

To make the access more persistent, use the LoadBalancer service instead of default one (Please see ``examples/grafana`` directory).

### Using persistent volumes

Two storage classes are predefined during installation. Write PVC (persistent volume claim) and Pod manifest files to use a persistent volume in a pod.

```sh
bastion:~$ kubectl get sc
NAME                 PROVISIONER       RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
exascaler-sc-fast    exa.csi.ddn.com   Delete          Immediate           false                  5d18h
exascaler-sc-large   exa.csi.ddn.com   Delete          Immediate           false                  5d18h
```
### Utilizing GPUs and RDMA devices

GPUs and RDMA devices are defined as allocatable resourcees on nodes.

```sh
bastion:~$ kubectl describe node kube-gpu1
...
Addresses:
  Hostname:    kube-gpu1
Capacity:
  nvidia.com/gpu:           1
  rdma/rdma_shared_device:  1k
Allocatable:
  nvidia.com/gpu:           1
  rdma/rdma_shared_device:  1k
```  

### MIG (multi-instance GPU) support 
NVIDIA GPU operator supports MIG. This playbook doesn't enable MIG by default, but it can be enabled by [configuring MIG profiles](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/gpu-operator-mig.html).

```sh
bastion:~$ kubectl label nodes kube-gpu1 nvidia.com/mig.config=all-1g.5gb
```

### SR-IOV networking

SR-IOV networking is supported as a secondary network in a pod by using [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) and [Whereabouts](https://github.com/k8snetworkplumbingwg/whereabouts).

To use this feature, write a network attachment definition:
```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: rdma-ipvlan-conf
spec:
  config: '{
      "cniVersion": "0.3.0",
      "name": "rdma-ipvlan-conf",
      "type": "ipvlan",
      "master": "ens192",
      "mode": "l2",
      "ipam": {
        "type": "whereabouts",
        "range": "10.146.16.0/21",
        "range_start": "10.146.18.100",
        "range_end": "10.146.18.120",
        "log_file": "/tmp/whereabouts.log",
        "log_level": "debug"
      }
    }'
```
and add an annotation to the pod definition:
```yaml
    annotations:
      "k8s.v1.cni.cncf.io/networks": "rdma-ipvlan-conf"
```
### Using LoadBalancer

MetalLB automatically assigns public IP addresses (which are opened to the outside of the cluster) to Services from the pooled address range. It can be used by specifiyng the ``LoadBalancer`` type in a Kubernetes service definition.

The pooled addresses can be configured in the ``k8s-configs/roles/k8s_service/vars/main.yaml`` file:
```yaml
metallb_addresses: 10.18.20.200-10.18.20.210
````

To make it globally accessible from the outside of the mdx, please configure the DNAT and ACL entries from the mdx's user portal. This operation isn't needed when accessing services using SSH port forwarding.

### Running parallel jobs
Please refer the [MPI operator's document](https://github.com/kubeflow/mpi-operator).

### Running Spark applications
Please refer [Spark RAPIDS document](https://nvidia.github.io/spark-rapids/docs/get-started/getting-started-kubernetes.html).

## NUMA-aware resource management

The default playbook reserves the following resources for the underlying kubelet and system daemons. More specifically, it reserves a single CPU core and 1.1GB memory, and 2GB ephemeral storage for not using them to Kubernetes pods. If you want to run a Kubernetes cluster in more limited host resources or to change the management policies or the amount of reserved resources, change the ``k8s-configs/roles/k8s_worker/vars/main.yaml`` file accordingly.

```yaml
kubelet_extra_args: >-
  --topology-manager-scope=container
  --topology-manager-policy=single-numa-node 
  --cpu-manager-policy=static 
  --memory-manager-policy=Static 
  --kube-reserved=cpu=500m,memory=500Mi,ephemeral-storage=1Gi 
  --system-reserved=cpu=500m,memory=500Mi,ephemeral-storage=1Gi 
  --reserved-memory=0:memory=1100Mi
```

## Known issues and limitations

- Apache Spark jobs don't work properly due to bugs at this time.
- Virtual machines must be set up manually in the current mdx configuration.

## Future work
- Support for [Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator)
- Support for JupyterHub/BinderHub Operators
- Support for [MySQL Operator](https://github.com/mysql/mysql-operator)
- Support for other k8s distributions (such as [k3s](https://k3s.io/), [MicroK8s](https://microk8s.io/))
- Building a cluster of k8s clusters like [Fleet](https://github.com/rancher/fleet)
- Data tranfer and processing from/to S3-compatible object storage
