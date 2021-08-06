variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "ExampleAppServerInstance"
}

variable "ami" {
	default = "ami-0c1a7f89451184c8b"
}

variable "instance_type" {
	default = "t2.nano"
}
###