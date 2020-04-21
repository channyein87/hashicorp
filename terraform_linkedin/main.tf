resource "aws_vpc" "tf-linkedin" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags {
        Name = "tf-linkedin"
    }
}

resource "aws_subnet" "tf-subnet1" {
    cidr_block = "${cidrsubnet(aws_vpc.tf-linkedin.cidr_block, 4, 1)}"
    vpc_id = "${aws_vpc.tf-linkedin.id}"
    availability_zone = "ap-southeast-2a"
    tags {
        Name = "tf-subnet1"
        Tier = "public"
    }
}

resource "aws_subnet" "tf-subnet2" {
    cidr_block = "${cidrsubnet(aws_vpc.tf-linkedin.cidr_block, 4, 2)}"
    vpc_id = "${aws_vpc.tf-linkedin.id}"
    availability_zone = "ap-southeast-2b"
    tags {
        Name = "tf-subnet2"
        Tier = "public"
    }
}

resource "aws_internet_gateway" "tf-igw" {
  vpc_id = "${aws_vpc.tf-linkedin.id}"

  tags = {
    Name = "tf-igw"
  }
}

resource "aws_route_table" "tf-public-route" {
    vpc_id = "${aws_vpc.tf-linkedin.id}"

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.tf-igw.id}"
    }

    tags {
      Name = "tf-public"
    }
}

resource "aws_route_table_association" "tf-public-route-subnet1" {
  subnet_id      = "${aws_subnet.tf-subnet1.id}"
  route_table_id = "${aws_route_table.tf-public-route.id}"
}

resource "aws_route_table_association" "tf-public-route-subnet2" {
  subnet_id      = "${aws_subnet.tf-subnet2.id}"
  route_table_id = "${aws_route_table.tf-public-route.id}"
}

resource "aws_security_group" "tf-subnet-sg" {
    vpc_id = "${aws_vpc.tf-linkedin.id}"

    ingress {
        cidr_blocks = [
            "${aws_vpc.tf-linkedin.cidr_block}"
        ]

        from_port = 80
        to_port = 80
        protocol = "tcp"
    }
}
