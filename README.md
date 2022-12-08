# tekton-flux
## K8s management and CI/CD using Flux and Tekton

This repo is a proof of concept for building and maintaining a kubernetes cluster using TektonCD and Flux.

### [Flux]
- Flux provides GitOps for both apps and infrastructure
- You need the flux cli installed locally to be able to bootstrap your minikube cluster. 
-- https://fluxcd.io/flux/installation/#install-the-flux-cli
- We utilize flux to install cluster components like Tekton and Prometeus.
- Flux can also be utilized to deploy any helm/kustomize application. This repo has several example applications that also get deployed.

### [Tekton]
- Tekton is a powerful and flexible open-source framework for creating CI/CD systems
- Tekton is heavily utilized to perform jobs and tasks. For example building and pushing docker images

### [Minikube]
- Currently this project is only built to run within minikube. Other k8s deployments are possible but not covered at this time.
- You need minikube running locally to be able to continue.
-- https://minikube.sigs.k8s.io/docs/start/
- The build-push-image example job depends on a docker registry running within minikube. To simplify the install this registry is insecure. When you run minikube make sure to run with the arguement ```--insecure-registry "10.0.0.0/8"```

## Getting Started
#### Fork this repo
Flux wants to store information is the repository used for bootstrapping.  You most likely do not have write access to this repo so it is recommended you fork this repo.  You should also have your computer configured with a github ssh key.

#### Start minikube
```minikube start --insecure-registry "10.0.0.0/8"```
As described above we are using a local docker registry. Allowing the insecure registry makes for an easy location to push/pull docker images.

#### Bootstrap Flux
https://fluxcd.io/flux/cmd/flux_bootstrap/
Bootstrap your minikube cluster to be managed by flux.  The following command works for this repo and you will need to adjust the URL to match your fork. You might also need to adjust the private key reference depending on your github.com setup.
```
flux bootstrap git \
  --url=ssh://git@github.com/taylorshaulis/tekton-flux \
  --branch=main \
  --path=clusters/minikube \
  --private-key-file=./.ssh/id_ed25519
```

## That is it
Your minikube has been boot strapped with the minimal setup.

### Monitoring
You have several options for monitoring the state of your tekton-flux.
- Prometheus has been installed along with the flux monitoring config.
-- https://fluxcd.io/flux/guides/monitoring/#flux-dashboards
-- ```kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80```
- FluxCli has several options to view the status of deployed resources
-- https://fluxcd.io/flux/cmd/
-- ```flux get all -A```
-- ```flux get all -A --status-selector ready=false```

### Secret Management
No CI/CD platform would be complete without some sort of secret management.
This POC uses Hashicorp Vault and the External Secrets Operator. However they do not work by default because Vault needs to be initialized.
To help with this two scripts have been provided.

First initialize and unseal the vault.
```
scripts/vault_init_unseal.sh
```
This will create a cluster-keys.json file one level above that contains the vault root token.

Second create an admin policy and token that is used by external secrets operator
```
scripts/vault_admin_policy.sh
```

[Tekton]: <https://tekton.dev/>
[Flux]: <https://fluxcd.io/>
[Minikube]: <https://minikube.sigs.k8s.io/docs/>