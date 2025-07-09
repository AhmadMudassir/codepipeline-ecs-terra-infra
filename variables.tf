variable "region" {
  default = "us-east-2"
}

variable "owner" {
  default = "ahmad"
}

variable "vpc-cidr" {
  default = "10.0.0.0/16"
}

variable "subnet1-cidr" {
  default = "10.0.1.0/24"
}

variable "subnet2-cidr" {
  default = "10.0.2.0/24"
}

variable "subnet3-cidr" {
  default = "10.0.3.0/24"
}

variable "subnet4-cidr" {
  default = "10.0.4.0/24"
}

variable "all-traffic-cidr" {
  default = "0.0.0.0/0"
}