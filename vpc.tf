provider "aws" {
    region = "us-east-1"
}

#VPC
resource "aws_vpc" "sample-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "Sample VPC"
    }
}

#public subnet
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.sample-vpc.id
    cidr_block = "10.0.0.0/17"

    tags = {
      "Name" = "Public Subnet"
    }
}

#private subnet
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.sample-vpc.id
  cidr_block = "10.0.128.0/17"

  tags = {
    "Name" = "Private Subnet"
  }
}

#security group for web
resource "aws_security_group" "web-sg" {
    name = "web-sg"
    vpc_id = aws_vpc.sample-vpc.id

    ingress = {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_block = [aws_vpc.sample-vpc.cidr_block]
    }
}

#security group for db (mysql)
resource "aws_security_group" "db-sg" {
    name = "db-sg"
    vpc_id = aws_vpc.sample-vpc.id

    ingress = {
        from_port = 1433
        to_port = 1433
        protocol = "tcp"
        cidr_block = [aws_vpc.sample-vpc.cidr_block]
    }
}

resource "aws_security_group" "ingress-sg" {
    name = "ingress-sg"
    vpc_id = aws_vpc.sample-vpc.id

    ingress = [ {
        from_port = 0
        to_port = 0
        protocol = "any"
        cidr_block = [aws_vpc.sample-vpc.cidr_block]
    } ]
}

#public nat gateway
resource "aws_nat_gateway" "public-nat" {
    subnet_id = aws_subnet.public.id
}

#private nat gateway
resource "aws_nat_gateway" "private-nat" {
    subnet_id = aws_subnet.private.id
}

#Routing rules (public)
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.sample-vpc.id

    route =  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.public-nat.id
    }
}

#Route table association
resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

#Public network access control list
resource "aws_network_acl" "pub-acl" {
    vpc_id = aws_vpc.sample-vpc.id
    subnet_ids = [ aws_subnet.public.id ]

    egress {
        protocol   = "tcp"
        rule_no    = 200
        action     = "allow"
        cidr_block = "10.0.0.0/17"
        from_port  = 443
        to_port    = 443
  }

    ingress {
        protocol   = "tcp"
        rule_no    = 100
        action     = "allow"
        cidr_block = "10.0.0.0/17"
        from_port  = 443
        to_port    = 443
  }

}

#Private network access control list
resource "aws_network_acl" "prv-acl" {
    vpc_id = aws_vpc.sample-vpc.id
    subnet_ids = [ aws_subnet.private.id ]

    egress {
        protocol   = "tcp"
        rule_no    = 200
        action     = "allow"
        cidr_block = "10.0.128.0/17"
        from_port  = 443
        to_port    = 443
  }

    ingress {
        protocol   = "tcp"
        rule_no    = 100
        action     = "allow"
        cidr_block = "10.0.128.0/17"
        from_port  = 443
        to_port    = 443
  }

}