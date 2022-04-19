# k8s-configs

This [Ansible](https://www.ansible.com/) playbook offers a highly-optimized [Kubernetes](https://kubernetes.io/) package for the [mdx](https://mdx.jp/) computing platform.

The playbook automatically installs the following components as a usable form within 10 minites:
- [k0s](https://k0sproject.io/) (a light-weight Kubernetes distribution)
- [Harbor](https://goharbor.io/) private container repository with private self-certificate 
- [Exascaler File CSI driver](https://github.com/DDNStorage/exa-csi-driver) (as a container persistent storage driver)
- [NVIDIA's GPU](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/overview.html) and [network operators](https://docs.nvidia.com/networking/display/COKAN10/Network+Operator) (for A100 GPUs and ROCEv2 networking)
- [MetalLB](https://metallb.universe.tf/) (as a load balancer)
- [MPI operator](https://github.com/kubeflow/mpi-operator) (for supporting parallel computing jobs)
- [Spark on k8s Operator](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator) with [RAPIDS and UCX shuffle manager](https://rapids.ai/) (for large data processing)
- [Kube Prometheus stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) (for monitoring and alerting)

This playbook was written being inspired from the [machine-configs](https://github.com/mdx-jp/machine-configs), but doesn't currently share the code with it.

## Prerequisites

This playbook assumes the following Ubuntu 20.04 based virtual machines exist in a user tenant.

- a single bastion host 
  - with 1 or a higher number of CPU cores, PortGroup networking
- a single harbor private repository host
  - with 2 or a higher number of CPU cores, 160GB or larger disk capacity, PortGroup networking
- a single kubernetes master node 
  - 2 or a higher number of CPU cores, PortGroup networking
- 0 or a larger number of kubernetes' computing nodes. 
  - with 2 or a higher number of CPU cores, 100GB or larger disk capacity, SR-IOV (RDMA) networking
- 0 or a larger number of GPU nodes. 
  - with 1 or a larger number of GPUs, 100GB or larger disk capacity, SR-IOV (RDMA) networking

We assume that all the above nodes are SSH-accessible from the basion host by using public key authentication without interaction like entering passwords (initial passwords must be set on each node beforehand after installation).

## Getting Started

1. Install the ansible package on the bastion host.
```sh
$ sudo apt install ansible
```

2. Install the dependent pip3 packages (kubernets and openshift) and Ansible galaxy collection (kubernetes.core).
```sh
$ install_dep_packages.py
```

3. Copy the inventory file from the template and rewrite the file accordingly. At least, fill in the IP addresses of each node (by ansible_host and roce_host). Copy the kube-node and kube-gpu entries as needed.
```sh
$ cp inventory.ini.template inventory.ini
$ mg inventory.ini
```

4. Copy the password file from the template and rewrite it. Set the harbor's admin and database passwords and grafana password.
```sh
$ cp vault.yaml.template vault.yaml
$ mg vault.yaml
```

5. Encrypt the above file by Ansible Vault (set the Vault password).
```sh
$ encrypt_vault.sh
```

6. Run the playbook and wait until the Kubernetes platform is constructed.
```sh
$ play.sh
```

The examples directory stores some example manifest files.

## Known issues and limitations

- Apache Spark jobs don't work properly at this time.
