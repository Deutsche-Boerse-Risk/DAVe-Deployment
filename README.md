# DAVe-Deployment

This repository contains the tooling for deploying DAVe application into running Kubernetes cluster. The DAVe
is deployed using [Helm](https://github.com/kubernetes/helm) package manager. Ansible playbook is used for generating
the certificates and initial Helm configuration (values file).

## Prerequisites

The tooling for generating the certificates and Helm config is written in Ansible. It runs only locally - it doesn't
connect to any remote machines. You need to have following tools installed:
* [Ansible 2.2](http://docs.ansible.com/ansible/latest/intro_installation.html#installation)
* [Helm](https://github.com/kubernetes/helm)
* Kubectl with proper configuration to connect to running Kubernetes cluster
* boto library which will be used for communication with Amazon AWS APIs
* OpenSSL for generating new SSL keys (only the Let's Encrypt playbook)
* CFSSL for generating the internal SSL keys / managing the internal CA

Before installation, the SSL certificated for external communication (CA signed certificates) have to be available. You can create them manually or use the prepared playbook:
* [letsencrypt.yaml](#signed-certificates-with-lets-encrypt)

**Before running the playbook, you have to set the AWS credentials for communication with the AWS services as environment variables.**

## Generating certificates and Helm config
```
cp playbook/group_vars/vars.yaml.example <userID>.yaml
[ EDIT <userID>.yaml ]
ansible-playbook playbook/install.yaml --extra-vars "@<userID>.yaml"
```
### Configuration

The configuration is in `playbook/group_vars/all/vars.yaml`.

| Variable | Explanation | Example |
|--------|-------------|---------|
| `helm_config` | Path to the Helm configuration (will be generated) | `../helm-values.yaml` |
| `api_key_path` | Path to the API private key | `../certs_external/api.key` |
| `api_cert_path` | Path to the API public key | `../certs_external/api.cert` |
| `ui_key_path` | Path to the UI private key | `../certs_external/ui.key` |
| `ui_cert_path` | Path to the UI public key | `../certs_external/ui.cert` |
| `certs_internal` | Path to the directory where internal SSL certs will be generated | `../certs_internal/` |

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
| `global.ui_dns` | Hostname of the UI | `ui.risk.dev.dbgcloud.io` |
| `global.api_dns` | Hostname of the API service | `api.risk.dev.dbgcloud.io` |
| `global.use_internal_load_balancer` | True if internal load balancer is used, false if not | `true` |
| `global.internal_load_balancer_ip` | Internal load balancer ip specification | `0.0.0.0/0` |
| `global.auth_dns` | Hostname of the Auth service | `auth.dave.dbg-devops.com` |
| `global.auth_well_known_endpoint` | URL of `.well-known/openid-configuration` endpoint of the OpenID backend | `/auth/realms/DAVe/.well-known/openid-configuration` |
| `global.auth_client_id` | OAuth / OpenID Connect client ID | `dave-ui` |
| `global.ca_cert_b64enc` | Internal CA base64 encoded |  |
| `*.release` | Which Docker image tag should be used in the deployment of the package | `1.0.0` |
| `*.min_replicas` | Min number of replicas for the package  | `1` |
| `*.max_replicas` | Max number of replicas for the package | `10` |
| `dave-ui.auth_flow` | OpenID authorization flow type; one of `openid-connect/direct`, `openid-connect/authorization-code`, `openid-connect/hybrid ` or`openid-connect/implicit` | `openid-connect/authorization-code` |
| `dave-ui.auth_scopes` | Additional authorization scopes. The `openid` scope is added automatically. | `['profile']` |
| `dave-store-manager.database_connection_url` | MongoDB database connection URL. If not defined, it will be generated to link to MongoDB deployed by this tooling. If defined, the MongoDB deployment will be skipped. | |
| `dave-store-manager.database_name` | Name of the MongoDB database | `DAVe` |
| `dave-margin-loader.cil_hostname` | Hostname where the CIL AMQP broker is running | `my-amqp-broker` |
| `dave-margin-loader.cil_port` | Port where the CIL AMQP broker is listening | `5672` |
| `dave-margin-loader.cil_username` | Username for connecting to the CIL AMQP broker | `DAVE` |
| `dave-margin-loader.cil_password` | Password for connecting to the CIL AMQP broker | |

## Signed certificates with Let's Encrypt

Playbook `letsencrypt.yaml` can be used to obtain signed keys from Let's Encrypt CA. Export the variables with AWS access tokens and run:
```
ansible-playbook playbook/letsencrypt.yaml
```

### Letsencrypt configuration
| Variable | Explanation | Example |
|--------|-------------|---------|
| `letsencrypt_account_key_path` | Path where the Let's Encrypt account key is / should be created | `./account.key` |
| `acme_directory` | Let's Encrypt ACME directory where we the certificates should be signed (production or staging) | `https://acme-staging.api.letsencrypt.org/directory` |

* If the account key is missing, it will generate new account key
* If the UI key is missing, it will generate the UI key with the UI hostname in CN
* It will generate UI CSR
* If the API key is missing, it will generate the API key with the API hostname in CN
* It will generate API CSR
* It will try to get the certificates signed. DNS verification will be used - Route53 will be automatically used to handle it.
* The keys will be signed only if the old keys expire in 10 or less days

*The `acme_directory` variable can be used to define whether the production Let's Encrypt service should be used or the staging service (for testing).*
