variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami_linux" {
  description = "The id of the AMAZON Linux 2 machine image (AMI) to use for the server."
  default     = "ami-05fa00d4c63e32376"
}

variable "ami_win" {
  description = "The id of the Windows machine image (AMI) to use for the server."
  default     = "ami-0fb5befc1450ca205"
}
