provider "aws" {

  region = "ap-south-1"
}

resource "aws_vpc" "vpc_1" {
  cidr_block = "10.10.0.0/16"
  tags = {
    name = "Prod"
  }
}

resource "aws_vpc" "vpc_2" {
  cidr_block = "172.16.0.0/16"
  tags = {
    name = "Dev"
  }
}

resource "aws_vpc" "vpc_3" {
  cidr_block = "192.168.0.0/16"
  tags = {
    name = "UAT"
  }
}

##########Subnets######################################

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.10.0.0/16"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "tf-example"
  }
}


resource "aws_subnet" "private_subnet1" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "172.16.0.0/16"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = "false"

  tags = {
    name = "test"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.vpc_3.id
  cidr_block              = "192.168.0.0/16"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = "false"

  tags = {
    name = "test"
  }
}
#####RT for igw####################################
resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc_1.id
  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_igw.id
  }

  route {
    cidr_block                = "172.16.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.foo.id
  }

  route {
    cidr_block                = "192.168.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hoo.id
  }

  tags = {
    Name = "igw-route"
  }
}

resource "aws_route_table_association" "public-rta" {
  route_table_id = aws_route_table.public_route.id
  subnet_id      = aws_subnet.public_subnet.id

}
###################RT for private subnet######################
resource "aws_route_table" "private_route1" {
  vpc_id = aws_vpc.vpc_2.id
  route {
    cidr_block                = "10.10.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.foo.id
  }

  route {
    cidr_block                = "192.168.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.goo.id
  }

  tags = {
    Name = "private-route1"
  }
}

resource "aws_route_table_association" "private-rta1" {
  route_table_id = aws_route_table.private_route1.id
  subnet_id      = aws_subnet.private_subnet1.id

}


resource "aws_route_table" "private_route2" {
  vpc_id = aws_vpc.vpc_3.id
  route {
    cidr_block                = "10.10.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hoo.id
  }

  route {
    cidr_block                = "172.16.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.goo.id
  }

  tags = {
    Name = "private-route2"
  }
}

resource "aws_route_table_association" "private-rta2" {
  route_table_id = aws_route_table.private_route2.id
  subnet_id      = aws_subnet.private_subnet2.id

}
########SG for Both#############################################

resource "aws_security_group" "public_sg" {
  name   = "Prod"
  vpc_id = aws_vpc.vpc_1.id
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }


}


resource "aws_security_group" "private_sg1" {
  name   = "dev"
  vpc_id = aws_vpc.vpc_2.id
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_security_group" "private_sg2" {
  name   = "UAT"
  vpc_id = aws_vpc.vpc_3.id
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }


}
########################instances#########################################
resource "aws_instance" "public_ec2" {
  ami                    = "ami-076e3a557efe1aa9c"
  subnet_id              = aws_subnet.public_subnet.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.public_sg.id]




  tags = {
    name = "prod"
  }
}

resource "aws_instance" "private_ec21" {
  ami                    = "ami-076e3a557efe1aa9c"
  subnet_id              = aws_subnet.private_subnet1.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.private_sg1.id]




  tags = {
    name = "dev"
  }
}

resource "aws_instance" "private_ec22" {
  ami                    = "ami-076e3a557efe1aa9c"
  subnet_id              = aws_subnet.private_subnet2.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.private_sg2.id]




  tags = {
    name = "UAT"
  }
}

########################vpc peering #####################################

resource "aws_vpc_peering_connection" "foo" {
  peer_vpc_id = aws_vpc.vpc_1.id
  vpc_id      = aws_vpc.vpc_2.id
  auto_accept = true
  tags = {
    Name = "VPC Peering between Public and Private1"
  }
}


resource "aws_vpc_peering_connection" "goo" {
  peer_vpc_id = aws_vpc.vpc_2.id
  vpc_id      = aws_vpc.vpc_3.id
  auto_accept = true
  tags = {
    Name = "VPC Peering between private1 and Private2"
  }
}


resource "aws_vpc_peering_connection" "hoo" {
  peer_vpc_id = aws_vpc.vpc_3.id
  vpc_id      = aws_vpc.vpc_1.id
  auto_accept = true
  tags = {
    Name = "VPC Peering between private2 and Public"
  }
}
