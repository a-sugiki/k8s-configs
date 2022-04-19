# k8s-configs

This Ansible playbook offers a highly-optimized Kubernetes package for the mdx computing platform.

The playbook automatically installs the following components as a usable form within 10 minites:
- k0s (a light-weight Kubernetes distribution)
- Harbor private container repository
- Exascaler File CSI driver (as a container storage driver)
- NVIDIA's GPU and network operators (for A100 GPUs and ROCEv2 RDMA network support)
- MetalLB (as a load balancer)
- MPI operator (for parallel computing jobs)
- Spark on k8s Operator with RAPIDS and UCX shuffle manager (for data processing)
- Prometheus/Grafana stack operator (for monitoring and alerting)

## Prerequisites

This playbook assumes the following machines exist in a user tenant.

- a single bastion host (1 core or higher, with PortGroup networking)
- a single harbor private repository host (2 cores or higher, 160GB or larger storage capacity is recommended, with Port Group networking)
- a single kubernetes master node (2 cores or higher, with Port Group networking)
- 0 or a larger number of kubernetes' computing node(s). (2 cores or higher, with SR-IOV networking)
- 0 or a larger number of GPU node(s). (1 or larger number of GPUs, with SR-IOV networking)

We assume that all the above nodes are SSH-accessible from the basion host by using public key authentication without interacting with passwords.

## Getting Started

1. Install ansible on the bastion host.
```sh
$ install
```

2. Install dependent Ansible packages.
```sh
$ install_dep_packages.py
```

3. Rewrite the inventory.ini file.
```sh
$ cp inventory.ini.template inventory.ini
```

4. Fill in the password file
```sh
$ cp vault.yaml.template vault.yaml
```

5. Encrypt the above file by Ansible Vault.
```sh
$ encrypt_vault.sh
```

6. Run the playbook and wait until the Kubernetes envornment is constructed.
```sh
$ play.sh
```

## Known issues and limitations

