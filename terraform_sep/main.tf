terraform {
  backend "s3" {
    bucket  = "keiko23"
    key     = "terraform_sep.tfstate"
    encrypt = "true"
    profile = "default"
    region  = "ap-southeast-2"
  }
}

data "aws_vpc" "vpc" {
  tags {
    Name = "tf-linkedin"
  }
}

data "aws_subnet_ids" "app_subnet_ids" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags {
    Tier = "public"
  }
}

data "aws_subnet" "app_subnets" {
  count = "${length(data.aws_subnet_ids.app_subnet_ids.ids)}"
  id    = "${data.aws_subnet_ids.app_subnet_ids.ids[count.index]}"
}

resource "aws_instance" "tf-ubuntu-2" {
  ami           = "ami-07e6faad15db3b345"
  instance_type = "t3.small"
  subnet_id     = "${element(data.aws_subnet_ids.app_subnet_ids.ids, count.index)}"
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = "${aws_instance.tf-ubuntu-2.id}"
}
