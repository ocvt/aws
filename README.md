# aws

OCVT's deployment configuration, mainly centered around docker.


## Deploying a new version of any image

1. Publish a new release to create a new image tag
1. Update `launch.sh` with the new tag
1. On the server, run `./launch down && ./launch up`


## Testing

1. Run `./launch.sh build && ./launch.sh up` to build and start a local build


## Initial AWS / server configuration

### AWS

1. Create a VPC named "OCVT VPC" with IPv4 (10.0.0.0/24) and IPv6 enabled
1. Delete the default VPC
1. Create a subnet named "OCVT Subnet" with auto-assigned IPs turned on, and create an IPv6 CIDR block
1. Create an Internet Gateway named `ocvt-igw` associated with the VPC from step 1
1. Add rules to the route table so that `0.0.0.0/0` and `::0/0` are both routed to the Internet Gateway from step 4
1. Create a new security group named `ocvt-sg` allowing SSH, HTTP, and HTTPS traffic from `0.0.0.0/0` and `::0/0`
1. Finally, create a new `t3a.small` instance with Amazon Linux 2, ensuring the security group from step 6 is used, public IPs are assigned, and the `ocvt-dev-key` SSH key name is used
1. Create a new Elastic IP named `ocvt-eip` and associate it with the instance created in step 7
1. Create an A & AAAA record for pineswamp.ocvt.club and ocvt.club pointing to that instance, and create CNAME records for www.ocvt.club, api.ocvt.club, and api-dev.ozmo.club pointing to pineswamp.ocvt.club
1. Ensure IPv6 is working: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-migrate-ipv6.html#ipv6-dhcpv6-amazon-linux
1. Create a backup plan in AWS Backup to take montly backups and keep them for 1 year

### DNS

Create the following DNS records:

- @, pineswamp  -> A & AAAA -> IP of AWS instance
- api, www -> CNAME -> pineswamp.ocvt.club.

*Note*: If the EC2 instance is terminated for whatever reason, the IPv6 address will have to be set again because AWS does not support IPv6 elastic IPs.

### Setup the server

Get the `ocvt-dev-key` SSH keypair and add this config to your `~/.ssh/config`
```
Host pineswamp
  User ec2-user
  Hostname pineswamp.ocvt.club
  IdentityFile ~/.ssh/ocvt-dev-key.pem
```

1. Run `ssh pineswamp` to ensure SSH works
1. Run `ansible-playbook ansible/main.yml -i ansible/hosts.cfg` to install required packages on the host
1. Clone this repository to the server
1. Set the environment variables
1. Run `./launch up` to start the services. Launches nginx (proxy and image cache), the html site, and the api. Nginx auto-creates the local `nginx-config` directory for persistent TLS certs.
1. Create a weekly cronjob to run `pushd /home/ec2-user/aws && ./launch.sh down && ./launch.sh up && popd` due to a small memory leak in ocvt-api.

### Github Config to manage images

- New container images for ocvt/ocvt-site and ocvt/dolabra are created on each new release via Github Actions (look at the workflow file) and stored in GitHub packages

### Uptime Robot

Configure uptime robot to do a check against https://ocvt.club and https://api.ocvt.club/healthcheck
