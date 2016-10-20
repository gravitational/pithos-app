## Install terraform
Options for:
- package: https://www.terraform.io/downloads.html
- [OSX] brew: `brew install terraform`

## Create the cluster in EC2
Variables:
- `TF_VAR_cluster_name`: name that the EC2 resources will be tagged with (ej. john-doe-cluster-v1.5)
- `TF_VAR_ssh_key`: name of the ssh key that will have access to the EC2 instances (ej. johndoe -> this means that you have the private key file 'johndoe.pem')
- `TF_VAR_nodes`: number of nodes to create (use either: 1, 3 or 5)

```
TF_VAR_cluster_name=<cluster-name> TF_VAR_ssh_key=<key name> TF_VAR_nodes=<1, 3 or 5> terraform apply
```

## Launch installer
SSH into one of the provisioned boxes using SSH key provided before.
*MAKE SURE THE USER IS `centos`, not `root`*
```
ssh -i "johndoe.pem" centos@ec2-54-152-13-16.compute-1.amazonaws.com
```

Download and launch installer:
*[or use tools/signInstallerUrls.py to get a signed url and the curl command to run inside the server]*
Update in the script:
- AWS key and secret
- anypoint-1.5.0-installer.tar.gz
```
sudo easy_install pip
sudo pip install awscli --ignore-installed six
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret access key>
aws s3 cp s3://onprem-standalone-installers/<anypoint-1.5.0-installer.tar.gz> installer.tar.gz
tar -xzf installer.tar.gz
./install
```

When prompted by the installer, select `/dev/xvde` for docker, and leave all other parameters untouched.
