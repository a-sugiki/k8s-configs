#!/bin/bash

# note: https://github.com/kubernetes-client/python/issues/1333
pip3 install -Iv kubernetes==11.0.0
pip3 install openshift
ansible-galaxy collection install kubernetes.core

