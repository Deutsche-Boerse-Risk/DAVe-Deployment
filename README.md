# DAVe-Deployment

This repository contains the tooling for deploying DAVe application into running Kubernetes cluster.

## Prerequisites

The tooling is written using Ansible. It runs only locally - it doesn't connect to any remote machines. To deploy the application, you need to have following tools installed:
* Ansible 2.2
* Kubectl with proper configuration to connect to running Kubernetes cluster
* boto library which will be used for communication with Amazon AWS APIs
* OpenSSL for generating new SSL keys (only the Let's Encrypt playbook)
* CFSSL for generating the internal SSL keys / managing the internal CA

Before installation, the SSL certificated for external communication (CA signed certificates) have to be available. You can create them manually or use the prepared playbook:
* [letsencrypt.yaml](#signed-certificates-with-lets-encrypt)

**Before running the playbook, you have to set the AWS credentials for communication with the AWS services as environment variables.**

## Configuration

The configuration is in `group_vars/all/vars.yaml`. It configures different details of the deployment.

| Variable | Explanation | Example |
|--------|-------------|---------|
| `namespace` | Kubernetes namespace where the DAVe application should be deployed | `dave` |
| `api_release` | Which Docker image tag should be used in the deployment of the API | `1.0.0` |
| `ui_release` | Which Docker image tag should be used in the deployment of the UI | `1.0.0` |
| `store_manager_release` | Which Docker image tag should be used in the deployment of the Store Manager | `1.0.0` |
| `margin_loader_release` | Which Docker image tag should be used in the deployment of the Margin Loader | `1.0.0` |
| `use_internal_load_balancer` | True if internal load balancer is used, false if not | `true` |
| `internal_load_balancer_ip` | Internal load balancer ip specification | `0.0.0.0/0` |
| `dns_zone` | Hosted DNS zone which has to exist in Route53 | `dbg-devops.com` |
| `ui_dns` | Hostname of the UI | `snapshot.dave.dbg-devops.com` |
| `api_dns` | Hostname of the API service | `api.snapshot.dave.dbg-devops.com` |
| `auth_dns` | Hostname of the Auth service | `auth.dave.dbg-devops.com` |
| `auth_client_id` | OAuth / OpenID Connect client ID | `dave-ui` |
| `jwt_public_key` | Public key used to verify the JWT tokens | `MIIBI...DAQAB` |
| `jwt_permissions_claim_key` | Where to find the authorization roles in the JWT key | `realm_access/roles` |
| `api_key_path` | Path to the API private key | `./api.key` |
| `api_cert_path` | Path to the API public key | `./api.cert` |
| `ui_key_path` | Path to the UI private key | `./ui.key` |
| `ui_cert_path` | Path to the UI public key | `./ui.cert` |
| `ca_dir` | Path where the internal CA should be created | `./ca/` |
| `database_name` | Name of the MongoDB database the API should be configured to use | `DAVe` |
| `database_url` | MongoDB database connection URL. If not defined, it will be generated to link to MongoDB deployed by this tooling. If defined, the MongoDB deployment will be skipped. | |
| `db_unload_url` | Path to tar.gz file with the database unload which should be loaded. If not set, only empty database will be created | `https://github.com/Deutsche-Boerse-Risk/DAVe/raw/master/mongo/mongo.tar.gz` |
| `db_unload_path` | Path under which the actual unload files are stored in the archive | `mongo/DAVe-TTSave` |
| `cil_hostname` | Hostname where the CIL AMQP broker is running | `my-amqp-broker` |
| `cil_port` | Port where the CIL AMQP broker is listening | `5672` |
| `cil_username` | Username for connecting to the CIL AMQP broker | `DAVE` |
| `cil_password` | Password for connecting to the CIL AMQP broker | |

Following configuration is needed only for signing the certificates with Let's Encrypt:

| Variable | Explanation | Example |
|--------|-------------|---------|
| `letsencrypt_account_key_path` | Path where the Let's Encrypt account key is / should be created | `./account.key` |
| `acme_directory` | Let's Encrypt ACME directory where we the certificates should be signed (production or staging) | `https://acme-staging.api.letsencrypt.org/directory` |
| `full_chain_cert` | URL to chain of public CA certificates which should be used with the end certificates. If not specified, only the end certificate will be used. | `https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt` |

## Installation

To install the application export the variables with AWS access tokens and run:
```
ansible-playbook install.yaml
```

It will create the Kubernetes resources, Route53 records etc. The definition of the Kubernetes objects is in the templates of different roles. Change the templates if you want to change something. **Before running the installation, check the configuration first.**

## Uninstallation

To uninstall the application export the variables with AWS access tokens and run:
```
ansible-playbook uninstall.yaml
```

It will remove all Kubernetes resources from the cluster as well as the Route53 DNS records. **Before running the uninstallation, check the configuration first.**

## Signed certificates with Let's Encrypt

Playbook `letsencrypt.yaml` can be used to obtain signed keys from Let's Encrypt CA. Export the variables with AWS access tokens and run:
```
ansible-playbook letsencrypt.yaml
```

* If the account key is missing, it will generate new account key
* If the UI key is missing, it will generate the UI key with the UI hostname in CN
* It will generate UI CSR
* If the API key is missing, it will generate the API key with the API hostname in CN
* It will generate API CSR
* It will try to get the certificates signed. DNS verification will be used - Route53 will be automatically used to handle it.
* The keys will be signed only if the old keys expire in 10 or less days

*The `acme_directory` variable can be used to define whether the production Let's Encrypt service should be used or the staging service (for testing).*
