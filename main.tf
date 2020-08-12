
/*
output "eip" {
  value = aws_instance.my1stec2.public_ip
}
*/

/*
I have created variables.tf and terraform.tfvars where I defined instace type and ami
If you need to debug user_data section defined in ec2 creation, use cat /var/log/cloud-init-output.log
Tip 1
terraform state list to list all the resources created by terraform apply
Tip 2
terraform state show aws_internet_gateway.gw-APP to display all the details for the selected resource
1. Create VPC
2. Create internet gateway
3. Create custom routing table
4. Create subnet
5. Subnet association with the routing table which previously created in step 3 and 4
6. Creation of security group and allowing http and https from Internet , ssh from your local ip
7. Create network interface with an ip address -step 4!
8. Assign elastic ip to in the NIC -step 7!
9. Crate an EC2 by using an ami -free tier, ubuntu would do, install and a web server and configure a dummy landing page
10. Elastic Load balancer: ALB provision, Listener provision, Target group provision, Target group association
*/

##1. Create VPC
resource "aws_vpc" "prod-VPC" {
  cidr_block       = var.address_space_vpc[0]
  instance_tenancy = "default"

  tags = {
    Name = "production-Application"
  }
}


##2. Create internet gateway
resource "aws_internet_gateway" "gw-APP" {
  vpc_id = aws_vpc.prod-VPC.id

  tags = {
    Name = "production-Application"
  }
}

##3. Create custom routing table
resource "aws_route_table" "rt-prod-APP" {
  vpc_id = aws_vpc.prod-VPC.id

  route {
    cidr_block = "0.0.0.0/0" #route all traffic to the internet gw
    gateway_id = aws_internet_gateway.gw-APP.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw-APP.id
  }

  tags = {
    Name = "production-Application"
  }
}

##4. Create subnet
resource "aws_subnet" "subnet-APP" {
  vpc_id     = aws_vpc.prod-VPC.id
  cidr_block = var.subnet_cidr[0]
  availability_zone = var.subnet_az[0] #"eu-west-1a" this is not mandatory to creat a subnet resource optional

  tags = {
    Name = "production-Application"
  }
}

##4. Create subnet (b)
resource "aws_subnet" "subnet-APP-AZ-B" {
  vpc_id     = aws_vpc.prod-VPC.id
  cidr_block = var.subnet_cidr[1]
  availability_zone = var.subnet_az[1] #"eu-west-1b" this is not mandatory to creat a subnet resource optional

  tags = {
    Name = "production-Application"
  }
}

##4. Create subnet (c)
resource "aws_subnet" "subnet-APP-AZ-C" {
  vpc_id     = aws_vpc.prod-VPC.id
  cidr_block = var.subnet_cidr[2]
  availability_zone = var.subnet_az[2] #"eu-west-1b" this is not mandatory to creat a subnet resource optional

  tags = {
    Name = "production-Application"
  }
}

##5. Subnet association
resource "aws_route_table_association" "rta-prodd-APP" {
  subnet_id      = aws_subnet.subnet-APP.id
  route_table_id = aws_route_table.rt-prod-APP.id
}

##5. Subnet association (b)
resource "aws_route_table_association" "rta-prodd-APP-B" {
  subnet_id      = aws_subnet.subnet-APP-AZ-B.id
  route_table_id = aws_route_table.rt-prod-APP.id
}

##5. Subnet association (c)
resource "aws_route_table_association" "rta-prodd-APP-C" {
  subnet_id      = aws_subnet.subnet-APP-AZ-C.id
  route_table_id = aws_route_table.rt-prod-APP.id
}

##6. Creation of security group HTTP HTTPS ALB
resource "aws_security_group" "allow_http_https" {
  name        = "allow_http_https"
  description = "Allow HTTP HTTPS inbound traffic"
  vpc_id      = aws_vpc.prod-VPC.id

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "production-Application"
  }
}

##6. Creation of security group HTTP HTTPS ALB to EC2
resource "aws_security_group" "allow_http_https_alb_ec2" {
  name        = "allow_http_https_alb_to_ec2"
  description = "Allow HTTP HTTPS inbound traffic alb to ec2"
  vpc_id      = aws_vpc.prod-VPC.id

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.allow_http_https.id]
  }

    ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.allow_http_https.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "production-Application"
  }
}

##6. Creation of security group SSH only
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_my_ip"
  description = "Allow SSH my ip inbound traffic"
  vpc_id      = aws_vpc.prod-VPC.id

  ingress {
    description = "SSH from MY IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["80.49.47.221/32"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "production-Application"
  }
}

##7. Create network interface
resource "aws_network_interface" "application-server-nic" {
  subnet_id       = aws_subnet.subnet-APP.id
  ###private_ips     = ["10.90.1.90"]
  security_groups = [aws_security_group.allow_http_https_alb_ec2.id,aws_security_group.allow_ssh.id]

}

##7. Create network interface (b)
resource "aws_network_interface" "application-server-nic-B" {
  subnet_id       = aws_subnet.subnet-APP-AZ-B.id
  ###private_ips     = ["10.90.2.90"]
  security_groups = [aws_security_group.allow_http_https_alb_ec2.id,aws_security_group.allow_ssh.id]

}

##7. Create network interface (c)
resource "aws_network_interface" "application-server-nic-C" {
  subnet_id       = aws_subnet.subnet-APP-AZ-C.id
  ###private_ips     = ["10.90.3.90"]
  security_groups = [aws_security_group.allow_http_https_alb_ec2.id,aws_security_group.allow_ssh.id]

}

output "private_ip_export" {
  value = aws_network_interface.application-server-nic.private_ips
}


##8. Assign elastic ip to in the NIC
resource "aws_eip" "application-server-pubip" {
  vpc                       = true
  network_interface         = aws_network_interface.application-server-nic.id
  ###associate_with_private_ip = "10.90.1.90"
  depends_on = [aws_internet_gateway.gw-APP] #the eip depends on internet gateway to be exist, we can pass other resources like vpc hence it is a list
}

##8. Assign elastic ip to in the NIC (b)
resource "aws_eip" "application-server-pubip-B" {
  vpc                       = true
  network_interface         = aws_network_interface.application-server-nic-B.id
  ###associate_with_private_ip = "10.90.2.90"
  depends_on = [aws_internet_gateway.gw-APP] #the eip depends on internet gateway to be exist, we can pass other resources like vpc hence it is a list
}

##8. Assign elastic ip to in the NIC (c)
resource "aws_eip" "application-server-pubip-C" {
  vpc                       = true
  network_interface         = aws_network_interface.application-server-nic-C.id
  ###associate_with_private_ip = "10.90.3.90"
  depends_on = [aws_internet_gateway.gw-APP] #the eip depends on internet gateway to be exist, we can pass other resources like vpc hence it is a list
}

##9. Create an EC2
resource "aws_instance" "web-server-node-1" {
  ami = var.my_image
  instance_type = var.instancetype
  availability_zone = var.subnet_az[0]
  key_name = "prod-APP-server-kp-1"
  iam_instance_profile = aws_iam_instance_profile.sm_prod_iam_instance_profile.name
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.application-server-nic.id
  }
  #below lines to install web server with a dummy landing html page
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  sudo bash -c 'echo This web server node 01 > /var/www/html/index.html'
  EOF  

  tags = {
    Name = "production-Web-Server"
  }

}

output "eip" {
  value = aws_instance.web-server-node-1.public_ip
}


##9. Create an EC2 || Create EBS
resource "aws_ebs_volume" "ebs_web_server_prod_az_1" {
  availability_zone = var.subnet_az[0]
  size = var.vol_size[0]
  encrypted = var.enc[1]
  type = var.vol_type[2]
  iops = var.vol_size[0] * 50
  tags = {
    Name = "production-Application-storage"
  }
}
##9. Create an EC2 || Attach EBS to EC2
resource "aws_volume_attachment" "ebs_web_server_prod_vlm_att_az_1" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs_web_server_prod_az_1.id
  instance_id = aws_instance.web-server-node-1.id
}

output "volume_id_az_idx0" {
  value = aws_ebs_volume.ebs_web_server_prod_az_1.id
}


##9. Create an EC2 (b)
resource "aws_instance" "web-server-node-2" {
  ami = var.my_image
  instance_type = var.instancetype
  availability_zone = var.subnet_az[1]
  key_name = "prod-APP-server-kp-1"
  iam_instance_profile = aws_iam_instance_profile.sm_prod_iam_instance_profile.name
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.application-server-nic-B.id
  }
  #below lines to install web server with a dummy landing html page
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  sudo bash -c 'echo This web server node 02 > /var/www/html/index.html'
  EOF  

  tags = {
    Name = "production-Web-Server"
  }

}

output "eip2" {
  value = aws_instance.web-server-node-2.public_ip
}

##9. Crate an EC2 (c)
resource "aws_instance" "web-server-node-3" {
  ami = var.my_image
  instance_type = var.instancetype
  availability_zone = var.subnet_az[2]
  key_name = "prod-APP-server-kp-1"
  iam_instance_profile = aws_iam_instance_profile.sm_prod_iam_instance_profile.name
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.application-server-nic-C.id
  }
  #below lines to install web server with a dummy landing html page
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  sudo bash -c 'echo This web server node 03 > /var/www/html/index.html'
  EOF  

  tags = {
    Name = "production-Web-Server"
  }

}

output "eip3" {
  value = aws_instance.web-server-node-3.public_ip
}

##10. Elastic Load balancer -1 LB provisioning
resource "aws_lb" "web-APP-ELB-Prod-01" {

  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http_https.id]
  subnets            = [aws_subnet.subnet-APP.id,aws_subnet.subnet-APP-AZ-B.id,aws_subnet.subnet-APP-AZ-C.id]

tags = {
    Name = "production-ALB"
  }
}


##10. Elastic Load balancer -2 Instance Target Group provisioning
resource "aws_lb_target_group" "web-APP-ELB-Prod-01-TG" {
  name     = "tf-prod-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod-VPC.id
}

##10. Elastic Load balancer -3 Listener provisioning
resource "aws_lb_listener" "web-APP-ELB-Prod-01-LS" {
  load_balancer_arn = aws_lb.web-APP-ELB-Prod-01.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-APP-ELB-Prod-01-TG.arn
  }
}

##10. Elastic Load balancer -4.1 EC2 attaching
resource "aws_lb_target_group_attachment" "web-tg-attach-1" {
  target_group_arn = aws_lb_target_group.web-APP-ELB-Prod-01-TG.arn
  target_id        = aws_instance.web-server-node-1.id
  port             = 80
}
##10. Elastic Load balancer -4.2 EC2 attaching
resource "aws_lb_target_group_attachment" "web-tg-attach-2" {
  target_group_arn = aws_lb_target_group.web-APP-ELB-Prod-01-TG.arn
  target_id        = aws_instance.web-server-node-2.id
  port             = 80
}
##10. Elastic Load balancer -4.3 EC2 attaching
resource "aws_lb_target_group_attachment" "web-tg-attach-3" {
  target_group_arn = aws_lb_target_group.web-APP-ELB-Prod-01-TG.arn
  target_id        = aws_instance.web-server-node-3.id
  port             = 80
}

output "elb-dns-name" {
  value = aws_lb.web-APP-ELB-Prod-01.dns_name
}

###AWS System Manager iam role
resource "aws_iam_role" "sm_iam_role_prod" {
  name = "sm_iam_role_prod"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com","Service": "ssm.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  }
EOF
}



###AWS System Manager iam role policy attachment
resource "aws_iam_role_policy_attachment" "sm_iam_role_prod_attach" {
  role       = aws_iam_role.sm_iam_role_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

###AWS System Manager iam instance profile
resource "aws_iam_instance_profile" "sm_prod_iam_instance_profile" {
  name = "sm_prod_iam_instance_profile"
  role = aws_iam_role.sm_iam_role_prod.name
}

###AWS System Manager activation
resource "aws_ssm_activation" "aws_ssm_activate_prod" {
  name               = "prod_ssm_activation"
  description        = "production application"
  iam_role           = aws_iam_role.sm_iam_role_prod.id
  registration_limit = "5"
  depends_on         = [aws_iam_role_policy_attachment.sm_iam_role_prod_attach]
}

###AWS System Manager document for association
resource "aws_ssm_document" "aws_ssm_doc_prod" {
  name          = "aws_ssm_doc_prod"
  document_type = "Command"

  content = <<DOC
  {
    "schemaVersion": "1.2",
    "description": "Check ip configuration of a Linux instance.",
    "parameters": {

    },
    "runtimeConfig": {
      "aws:runShellScript": {
        "properties": [
          {
            "id": "0.aws:runShellScript",
            "runCommand": ["ifconfig"]
          }
        ]
      }
    }
  }
DOC
}

###AWS System Manager associate with ec2
resource "aws_ssm_association" "aws_ssm_associate_ec2" {
  name = aws_ssm_document.aws_ssm_doc_prod.name

  targets {
    key    = "tag:Name"
    values = ["production-Web-Server"]
  }
}