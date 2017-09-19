# DAVe-Deployment

This repository contains the tooling for deploying DAVe application into running Kubernetes cluster. The DAVe
is deployed using [Helm](https://github.com/kubernetes/helm) package manager. Ansible playbook is used for generating
the certificates and initial Helm configuration (values file).

## Prerequisites

The tooling for generating the certificates and Helm config is written in Ansible. It runs only locally - it doesn't
connect to any remote machines. You need to have following tools installed:
* [Ansible 2.2](http://docs.ansible.com/ansible/latest/intro_installation.html#installation)
* [Helm](https://github.com/kubernetes/helm)
    - init Helm with:
    ```
    helm init --client-only
    ```
* Kubectl with proper configuration to connect to running Kubernetes cluster
* OpenSSL for generating new SSL keys (only the Let's Encrypt playbook)
* CFSSL for generating the internal SSL keys / managing the internal CA:
    ```
    ansible-playbook playbook/cfssl-install.yaml
    ```

Before installation, the SSL certificated for external communication (CA signed certificates) have to be available.

## Generating certificates and initial Helm config
```
cp playbook/group_vars/all/vars.yaml.example <userID>.yaml
[ EDIT <userID>.yaml ]
ansible-playbook playbook/install.yaml --extra-vars "@<userID>.yaml"
```

| Variable | Explanation | Example |
|--------|-------------|---------|
| `helmConfig` | Path to the Helm configuration (will be generated) | `../helm-values.yaml` |
| `apiKeyPath` | Path to the API private key | `../certs_external/api.key` |
| `apiCertPath` | Path to the API public key | `../certs_external/api.cert` |
| `uiKeyPath` | Path to the UI private key | `../certs_external/ui.key` |
| `uiCertPath` | Path to the UI public key | `../certs_external/ui.cert` |
| `certsInternal` | Path to the directory where internal SSL certs will be generated | `../certs_internal/` |

## Deploying DAVe

* Edit/review the generated Helm configuration:
```
[ EDIT helm-values.yaml ]
```
* Export _KUBECONFIG_ environment variable to the Kubernetes cluster configuration
* Install the package
```
helm install --namespace <NAMESPACE> -f helm-values.yaml chart/dave
```

### Helm configuration

| Variable | Explanation | Example |
|--------|-------------|---------|
| `global.uiDns` | Hostname of the UI | `ui.risk.dev.dbgcloud.io` |
| `global.apiDns` | Hostname of the API service | `api.risk.dev.dbgcloud.io` |
| `global.useInternalLoadBalancer` | True if internal load balancer is used, false if not | `true` |
| `global.
internalLoadBalancerIp` | Internal load balancer ip specification | `0.0.0.0/0` |
| `global.authDns` | Hostname of the Auth service | `auth.dave.dbg-devops.com` |
| `global.authWellKnownEndpoint` | URL of `.well-known/openid-configuration` endpoint of the OpenID backend | `/auth/realms/DAVe/.well-known/openid-configuration` |
| `global.authClientId` | OAuth / OpenID Connect client ID | `dave-ui` |
| `global.caCertB64Enc` | Internal CA base64 encoded |  |
| `*.release` | Which Docker image tag should be used in the deployment of the package | `1.0.0` |
| `*.minReplicas` | Min number of replicas for the package  | `1` |
| `*.maxReplicas` | Max number of replicas for the package | `10` |
| `dave-ui.authFlow` | OpenID authorization flow type; one of `openid-connect/direct`, `openid-connect/authorization-code`, `openid-connect/hybrid ` or`openid-connect/implicit` | `openid-connect/authorization-code` |
| `dave-ui.authScopes` | Additional authorization scopes. The `openid` scope is added automatically. | `['profile']` |
| `dave-store-manager.databaseConnectionUrl` | MongoDB database connection URL. If not defined, it will be generated to link to MongoDB deployed by this tooling. If defined, the MongoDB deployment will be skipped. | |
| `dave-store-manager.databaseName` | Name of the MongoDB database | `DAVe` |
| `dave-margin-loader.cilHostname` | Hostname where the CIL AMQP broker is running | `my-amqp-broker` |
| `dave-margin-loader.cilPort` | Port where the CIL AMQP broker is listening | `5672` |
| `dave-margin-loader.cilUsername` | Username for connecting to the CIL AMQP broker | `DAVE` |
| `dave-margin-loader.cilPassword` | Password for connecting to the CIL AMQP broker | |


## Loading data into DAVe
It is possible to load dumped database into the running DAVe's Mongo DB. A separate Helm package `mongo-provisioning` can be
used:
```
helm install --namespace <NAMESPACE> chart/mongo-provisioning
```

The package can be installed into the same namespace as DAVe, however it is not required. Package should work out of the box
with the default values, if you want to use specific location of the dumped archive or another database name, please
edit `chart/mongo-provisioning/values.yaml`

| Variable | Explanation | Example |
|--------|-------------|---------|
| `databaseName` | Database name into which dump should be restored | `DAVe` |
| `db_unload_url` | Url of the dumped archive |  |
| `db_unload_path` | Directory beneath which (after unzipping) the files reside | `mongo` |
| `databaseConnectionUrl` | Connection url to the running Mongo (replica) DB |  |

Package works as a Kubernetes Job. Once the data are restored into the DB, the package can be safely removed from the cluster:
```
helm delete [mongo-provisioning release (found by running helm ls)]
```

## Uninstalling DAVe
To delete DAVe and all resources there are several steps needed, since persistence volumes (Mongo DB) remains available in AWS.

* uninstall DAVe package/release
```
helm delete [DAVe release (found by running helm ls)]
```

* in Kubernetes dashboard (UI) delete all three persistence volumes requested by Mongo deployment
* go to AWS console and delete all three persistence volumes related to Mongo (otherwise would be marked as available)
* delete the namespace (if not shared by someone else)
```
kubectl delete namespace [NAMESPACE]
```