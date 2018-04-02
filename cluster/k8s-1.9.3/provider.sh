#!/bin/bash

set -e

image="k8s-1.9.3@sha256:2f1600681800f70de293d2d35fa129bfd2c64e14ea01bab0284e4cafcc330662"

source cluster/ephemeral-provider-common.sh

function up() {
    ${_cli} run $(_add_common_params)
    ${_cli} ssh --prefix $provider_prefix node01 sudo chown vagrant:vagrant /etc/kubernetes/admin.conf

    chmod 0600 ${KUBEVIRT_PATH}cluster/vagrant.key
    OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${KUBEVIRT_PATH}cluster/vagrant.key -P $(_port ssh)"

    # Copy k8s config and kubectl
    scp ${OPTIONS} vagrant@$(_main_ip):/usr/bin/kubectl ${KUBEVIRT_PATH}cluster/$PROVIDER/.kubectl
    chmod u+x ${KUBEVIRT_PATH}cluster/$PROVIDER/.kubectl
    scp ${OPTIONS} vagrant@$(_main_ip):/etc/kubernetes/admin.conf ${KUBEVIRT_PATH}cluster/$PROVIDER/.kubeconfig

    # Set server and disable tls check
    export KUBECONFIG=${KUBEVIRT_PATH}cluster/$PROVIDER/.kubeconfig
    ${KUBEVIRT_PATH}cluster/$PROVIDER/.kubectl config set-cluster kubernetes --server=https://$(_main_ip):$(_port k8s)
    ${KUBEVIRT_PATH}cluster/$PROVIDER/.kubectl config set-cluster kubernetes --insecure-skip-tls-verify=true

    # Make sure that local config is correct
    prepare_config
}