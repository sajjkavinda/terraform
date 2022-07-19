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

    ingress = [ {
      cidr_blocks = [ aws_vpc.sample-vpc.cidr_block ]
      description = "security group for web"
      from_port = 443
      ipv6_cidr_blocks = [  ]
      prefix_list_ids = [ ]
      protocol = "tcp"
      security_groups = [ "" ]
      self = false
      to_port = 443
    } ]
}

#security group for db (mysql)
resource "aws_security_group" "db-sg" {
    name = "db-sg"
    vpc_id = aws_vpc.sample-vpc.id

    ingress = [ {
      cidr_blocks = [ aws_vpc.sample-vpc.cidr_block ]
      description = "securoty group for db"
      from_port = 1433
      ipv6_cidr_blocks = [  ]
      prefix_list_ids = [  ]
      protocol = "tcp"
      security_groups = [ "" ]
      self = false
      to_port = 1433
    } ]
}

resource "aws_security_group" "ingress-sg" {
    name = "ingress-sg"
    vpc_id = aws_vpc.sample-vpc.id

    ingress = [ {
      cidr_blocks = [ aws_vpc.sample-vpc.cidr_block ]
      description = "ingress security group"
      from_port = 0
      ipv6_cidr_blocks = [  ]
      prefix_list_ids = [  ]
      protocol = "any"
      security_groups = [ "" ]
      self = false
      to_port = 0
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

    route = [ {
      carrier_gateway_id = ""
      cidr_block = "0.0.0.0/0"
      core_network_arn = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id = ""
      gateway_id = ""
      instance_id = ""
      ipv6_cidr_block = ""
      local_gateway_id = ""
      nat_gateway_id = aws_nat_gateway.public-nat.id
      network_interface_id = ""
      transit_gateway_id = ""
      vpc_endpoint_id = ""
      vpc_peering_connection_id = ""
    } ]
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