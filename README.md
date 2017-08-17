[1]: https://console.aws.amazon.com/iam/home?region=us-east-2#/security_credential
[2]: https://console.aws.amazon.com/iam/home?region=us-east-2#/users
[3]: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-windows
[4]: https://aws.amazon.com/blogs/aws/new-aws-certificate-manager-deploy-ssltls-based-apps-on-aws/

# Discourse Terraform

A Terraform project to launch Discourse in the cloud.

## Quick Usage
### 1. Create an API Key-Pair and Export It

You should first [go to AWS Console][1] and then click on Access Keys , and create a key-pair... you can also optionally setup an IAM user to limit your surface, this can be done at [through IAM console][2].  After you have done one of these things you should export your key so that we can use it to build your infrastructure.

#### Linux/Unix

```sh
export AWS_ACCESS_KEY_ID="<AccessKey>"
export AWS_SECRET_ACCESS_KEY="<SecretKey>"
export AWS_DEFAULT_REGION="us-west-2"
```

#### Windows

```sh
set AWS_ACCESS_KEY_ID="<AccessKey>"
set AWS_SECRET_ACCESS_KEY="<SecretKey>"
set AWS_DEFAULT_REGION="us-west-2"
```

### 2. Create your deploy key
#### Linux/Unix

```sh
# This generates an RSA Key.
ssh-keygen -t rsa -b 4096 -f keys/deploy.key
mv keys/deploy.key.pub keys/deploy.pub
```

#### Windows

On Windows you should either have bash on Windows, or you will need to visit [Github][3] for a guide on how to create an SSH key with Github, Git Bash (CYGWin), or... if you know another way, then use it.  Launch bash and then refer to the `Linux/Unix` section.

### 3. Add your personal public key to `keys/`
#### Linux/Unix
***The following assumes you use a Yubikey to store your SSH keys on separate hardware, if you do not, switch `cardno:<serial>` with your email and it will extract your key.***

```sh
ssh-add -L cardno:<Serial> > keys/user.pub
```

#### Windows

On Windows you will need to manually copy your public key from wherever you store it, if you use `pa-agent` it might be able to extract the public key on your behalf to a file to copy, if you have GPG2 and store your key on hardware, and it is in your path you should be able to do

```sh
gpg2 --export-ssh-key you@example.com
```

### 4. Init your Terraform

This is an important step, since we need both the AWS plugin, as well as the Template plugin so that we can build out your infrastructure. ***Please do not skip this step***

```sh
terraform init
```

### 5. Adjust your variables

***Inside of `vars.tf` there are a bunch of variables you can customize, some of them, however, are required.  You can set those with `terraform.tfvars`.***

```terraform
discourse_hostname="your.fqdn"
discourse_smtp_username="you@example.com"
discourse_developer_emails="you@example.com"
discourse_smtp_password="myPassword"
db_password = "myPassword"
```

***For a full list of customizable variables please refer to `vars.tf` everything in there except for templates is customizable via `terraform.tfvars`***

### 6. Verify Your Plan

First you should review and make sure everything looks okay, never randomly launch instances without first reviewing.  One of the golden rules of systems.

```
terraform plan
```

### 7. Launch Your Plan

After reviewing you can launch the instances

```
terraform apply
```

This will launch a VPC, several Security Groups, an RDS (PostgreSQL) instance, 2 Subnets (across 2 Zones), an ElastiCache (Redis) instance, and an ELB to route your traffic to the instance.  Each one of these is slugged, and designed so that you can spot them within your admin panel of your AWS control plane. ***By default this Terraform project is designed so that it can be ran on minimal costs, you can adjust `vars.tf` so that you can also run it entirely free***

## Extras
### Enable SSL
#### Using AWS Certificate Manager (Free)

You should first visit [this blog post][4] and learn how to create your own SSL certificate inside of AWS (for free of-course), there are manual and necessary steps to create one.  After doing that you can run the following and repeat the `terraform` steps necessary to deploy.

```bash
cp templates/ssl.tf .
```

#### Using A Private Provider

If you use a private provider, you should first copy your private key, and
your public key to `keys/ssl.key` and `keys/ssl.crt` respectively, and then run the following:

```
cp templates/ssl.private.tf ssl.tf
```

We will upload your certificate to the certificate manager and then attach it to your load balancer on your behalf, without much more interaction or requirement then that.
