variable "instancetype" {
    description = "instance type options"
    default = "t2.small"
}

variable "my_image" {
    description = "ami codes"
    default = "ami-089cc16f7f08c4457"
}

variable "subnet_cidr" {
    description = "subnet cidr block values"
    default = ["10.90.1.0/24","10.90.2.0/24","10.90.3.0/24"]
}

variable "subnet_az" {
    description = "az options values"
    default = ["eu-west-1a","eu-west-1b","eu-west-1c"]
}

variable "address_space_vpc" {
    description = "vpc address-cidr space values"
    default = ["10.90.0.0/16","10.91.0.0/16","10.92.0.0/16","10.93.0.0/16"]
}

variable "enc" {
	description = "encryption options values"
	default = ["true","false"]
}

variable "vol_type" {
	description = "volume type values"
	default = ["standard","gp2","io1","sc1","st1"]
}

variable "vol_size" {
	description = "volume size values"
	default = [20]
}

#instancetype = "t2.micro"
#my_image = "ami-089cc16f7f08c4457"
#subnet_cidr = ["10.90.1.0/24","10.90.2.0/24","10.90.3.0/24"]
#subnet_az = ["eu-west-1a","eu-west-1b","eu-west-1c"]
#address_space_vpc = ["10.90.0.0/16","10.91.0.0/16","10.92.0.0/16","10.93.0.0/16"]