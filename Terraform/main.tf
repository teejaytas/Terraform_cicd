provider "aws" {
  region = "ap-south-1"
}
#create a vpc
resource "aws_vpc" "my-vpc"{
    cidr_block="10.0.0.0/16"
    tags = {
        Name = "production"
    }
}
#create a gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.my-vpc.id

}
#Define route table

resource "aws_route_table" "p-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

#Define subnet
resource "aws_subnet" "subnet-one" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
      Name = "prod-subnet"
  }
}

#Combine subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-one.id
  route_table_id = aws_route_table.p-route-table.id
}

# Security part
resource "aws_security_group" "security_ec2" {
  name        = "security_ec2"
  description = "security group for ec2"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 # outbound 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security_ec2"
  }
}

#Define N-F

resource "aws_network_interface" "web-N" {
  subnet_id       = aws_subnet.subnet-one.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.security_ec2.id]
}

#Assign EIP
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-N.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

#
resource "aws_instance" "secondserver" {
  ami  = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.keyfour.key_name}"
  
  tags = {
    Name = "ubuntu"
  }
 
 network_interface {
    device_index = 0
      network_interface_id = aws_network_interface.web-N.id
 }


  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                sudo bash -c 'echo your first web server > /var/www/html/index.html'
                EOF
     
}
#Define Key-Pair
resource "aws_key_pair" "keyfour" {
  key_name   = "keyfour"
  public_key = "${file("keyfour.pub")}"
}

