# Load testing

## Prepare environment

### Install terraform

Options for:
- package: https://www.terraform.io/downloads.html
- [OSX] brew: `brew install terraform`

### Create the cluster in EC2

Variables:
- `TF_VAR_cluster_name`: name that the EC2 resources will be tagged with
(ej. john-doe-cluster-v1.5)
- `TF_VAR_ssh_key`: name of the ssh key that will have access to the EC2
instances (ej. johndoe -> this means that you have the private key file 'johndoe.pem').
*Note*: key is per-region entity, managed in AWS console.

Other Variables can be discovered by reading terraform file.

Example:
```sh
TF_VAR_cluster_name=<cluster-name> TF_VAR_ssh_key=<key name> terraform apply
```

### Launch installer

SSH into one of the provisioned boxes using SSH key provided before. *MAKE SURE THE USER IS `centos`, not `root`*

```sh
ssh -i "johndoe.pem" centos@ec2-54-152-13-16.compute-1.amazonaws.com
```

Then open OpsCenter, select intall for pithos-app and follow installer steps.

When prompted by the installer, select `/dev/xvde` for docker, and leave all other parameters untouched.

### Fill with test content

```sh
sudo gravity planet enter
cd /var/lib/gravity/local/packages/unpacked/gravitational.io/pithos-app
kubectl create -f resources/test-content.yaml
```

Check job logs.

### Configure load node

Upload scripts for `wrk`
```sh
scp -i "johndoe.pem" -r load-test/wrk-scripts centos@centos@ec2-54-152-13-16.compute-1.amazonaws.com:~
```
