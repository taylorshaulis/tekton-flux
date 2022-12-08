#!/bin/bash
# https://developer.hashicorp.com/vault/tutorials/policies/policies
# bootstrap admin policy

POLICYFILENAME="admin-policy.hcl"
REMOTESCRIPTFILENAME="runme.sh"
ADMINTOKENFILENAME="admin-token.json"
VAULTNAMESPACE="vault"
VAULTNAME="vault-vault-0"
EXTERNALSECRETSNAMESPACE="external-secrets"
EXTERNALSECRETSVAULTSECRET="vault-admin-token"
VAULTCLUSTERKEYS="../../cluster-keys.json"

tee $POLICYFILENAME <<EOF
# Read system health check
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Enable and manage the key/value secrets engine at `secret/` path

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}
EOF


#first cp admin policy up to vault pod

kubectl cp $POLICYFILENAME $VAULTNAMESPACE/$VAULTNAME:/tmp/$POLICYFILENAME
ROOT_TOKEN=$(jq -r ".root_token" $VAULTCLUSTERKEYS)

cat << EOF > $REMOTESCRIPTFILENAME
#!/bin/sh
vault login $ROOT_TOKEN
vault policy write admin /tmp/$POLICYFILENAME
vault token create -format=json -policy="admin" > /tmp/$ADMINTOKENFILENAME

EOF

chmod +x $REMOTESCRIPTFILENAME

kubectl cp $REMOTESCRIPTFILENAME $VAULTNAMESPACE/$VAULTNAME:/tmp/$REMOTESCRIPTFILENAME

kubectl -n $VAULTNAMESPACE exec $VAULTNAME -- /tmp/$REMOTESCRIPTFILENAME

kubectl cp $VAULTNAMESPACE/$VAULTNAME:/tmp/$ADMINTOKENFILENAME ./$ADMINTOKENFILENAME

kubectl -n $VAULTNAMESPACE exec $VAULTNAME -- rm /tmp/$REMOTESCRIPTFILENAME /tmp/$ADMINTOKENFILENAME /tmp/$POLICYFILENAME

rm $REMOTESCRIPTFILENAME
rm $POLICYFILENAME

ADMIN_TOKEN=$(jq -r ".auth.client_token" $ADMINTOKENFILENAME)


echo "Admin Token = $ADMIN_TOKEN"

kubectl -n $EXTERNALSECRETSNAMESPACE delete secret/$EXTERNALSECRETSVAULTSECRET

kubectl -n $EXTERNALSECRETSNAMESPACE create secret generic $EXTERNALSECRETSVAULTSECRET --from-literal=token=$ADMIN_TOKEN

rm $ADMINTOKENFILENAME