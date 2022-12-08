#!/bin/bash
# https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-raft
# init vault and unseal

VAULTNAMESPACE="vault"
VAULTNAME="vault-vault-0"
VAULTCLUSTERKEYS="../../cluster-keys.json"

#first init vault

kubectl -n $VAULTNAMESPACE exec $VAULTNAME -- vault operator init -key-shares=1 -key-threshold=1 -format=json > $VAULTCLUSTERKEYS

VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" $VAULTCLUSTERKEYS)

kubectl -n $VAULTNAMESPACE exec $VAULTNAME -- vault operator unseal $VAULT_UNSEAL_KEY