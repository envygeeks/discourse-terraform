# Discourse Terraform

A Terraform project to launch Discourse in the cloud.

## Usage
#### 1. Create an API Key Pair and Export It

https://console.aws.amazon.com/iam/home?region=us-east-2#/security_credential and then click on Access Keys and create a keypair... optionally you can also setup an IAM user to limit the surface, this can be done at https://console.aws.amazon.com/iam/home?region=us-east-2#/users

```
export $AWS_SECRET_KEY=<SecretKey>
export $AWS_ACCESS_KEY=<AccessKey>
```

#### 2. Create your deploy key

```
script/keygen
```

#### 3. Add your personal public key to `keys/`

***The following assumes you use a Yubikey to store your SSH keys on separate hardware, if you do not, switch `cardno:<serial>` with your email and it will extract your key.***

```
ssh-add -L cardno:<Serial> > keys/user.pub
```

#### 4. Init your Terraform

This is an important step since we need both the AWS plugin, as well as the Template plugin so that we can build out your infrastructure.

```
terraform init
```

#### 5. Adjust your variables

***Inside of `vars.tf` there are a bunch of variables you can customize, some of them, however, are required.  You can set those with `terraform.tfvars`.***

```
discourse_hostname="your.fqdn"
discourse_smtp_username="you@example.com"
discourse_developer_emails="you@example.com"
discourse_smtp_password="myPassword"
db_password = "myPassword"
```

#### 6. Verify Your Plan

First you should review and make sure everything looks okay, never randomly launch instances without first reviewing.  One of the golden rules of systems.

```
script/plan
```

#### 7. Launch Your Plan

After reviewing you can launch the instances

```
script/apply
```

This will launch a dedicated VPC, several security groups, an RDS (PostgreSQL) instance, 2 subnets (across 2 zones), an elasticache (Redis) instance, and an ELB to route your traffic to the instance.  Each one of these is slugged, and designed so that you can spot them within your admin panel of your AWS control plane. ***By default this Terraform project is designed so that it can be ran on minimal costs, you can adjust `vars.tf` so that you can also run it entirely free***


# TODO:

- Add Google, DO, and other services?
- Add EFS and/or EBS Volumes for user data.
- There seems to be something wrong with Discourse Launcher?
  - When it's ran it errors trying to `rm` a file.
- Use Modules in some places.
