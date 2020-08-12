# Terraform Cloud | AWS environment provisioning | sample use case

The sample use case , in a nutshell, is to provision a web application which runs on 3 EC2s in 3 different AZs in eu-west region. The EC2s are placed behind an application load balancer.  The EC2 management would be handled by System Manager.


# The code below provisions:
## 3 EC2 instances

Each and every EC2 would be in a different AZ in eu-west region. In user data section of EC2 resources you can see a very generic code to install and configure a basic static index.html web server.
There are network interface resources, security group resources, internet gateway resources, routing table resources just before the EC2 resource. Feel free to review them.

## 20 gb of EBS volume

Type fo the volume would be io1 and the iops value is 1000 iops.  Please be aware that there are two different resources for volume creation and attachment to EC2.

## Application load balancer
ALB has several resources: Listener, target group, LB itself, target group attachment

## System Manager

System manager has several resources: IAM role policy, assume role policy, IAM instance profile, SSM activation, document and document association
If you have reviewed the network interface resources, you should have realized that I commented elastic public IP association for network interfaces. The idea behind it was because of System Manager would be used to manage instances.

