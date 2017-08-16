# Discourse Terraform

A Terraform project to launch Discourse in the cloud.

## Usage
#### 1. Create your deploy key

```
ssh-keygen -t rsa -b 4096 -f keys/deploy.key
```

#### 2. Add your personal public key to `keys/`

***The following assumes you use a Yubikey to store your SSH keys on separate hardware, if you do not, switch `cardno:<serial>` with your email and it will extract your key.***

```
ssh-add -L cardno:<Serial> > keys/user.pub
```

#### 3. Adjust your variables

***Inside of `vars.tf` there are a bunch of variables you can customize, some of them, however, are required.  You can set those with `terraform.tfvars`.***

```
discourse_hostname="your.fqdn"
discourse_smtp_username="you@example.com"
discourse_developer_emails="you@example.com"
discourse_smtp_password="myPassword"
db_password = "myPassword"
```

#### 4. Verify Your Plan

First you should review and make sure everything looks okay, never randomly launch instances without first reviewing.  One of the golden rules of systems.

```
terraform plan -var="secret_key=$AWS_SECRET_KEY" \
  -var="access_key=$AWS_ACCESS_KEY"
```

#### 5. Launch Your Plan

After reviewing you can launch the instances

```
terraform apply -var="secret_key=$AWS_SECRET_KEY" \
  -var="access_key=$AWS_ACCESS_KEY"
```

This will launch a dedicated VPC, several security groups, an RDS (PostgreSQL) instance, 2 subnets (across 2 zones), an elasticache (Redis) instance, and an ELB to route your traffic to the instance.  Each one of these is slugged, and designed so that you can spot them within your admin panel of your AWS control plane. ***By default this Terraform project is designed so that it can be ran on minimal costs, you can adjust `vars.tf` so that you can also run it entirely free***


# TODO:

- Add Google, DO, and other services?
- Add EFS and/or EBS Volumes for user data.
- There seems to be something wrong with Discourse Launcher?
  - When it's ran it errors trying to `rm` a file.
- Use Modules in some places.
