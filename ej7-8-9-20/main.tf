module "red" {
  source = "./modules/red"

  vpc_cidr       = var.vpc_cidr
  subnet_a_cidr  = var.subnet_a_cidr
  subnet_b_cidr  = var.subnet_b_cidr
  key_name       = var.key_name
  public_key_path = var.public_key_path
}

module "ec2" {
  source = "./modules/ec2"

  key_name   = var.key_name
  subnet_id  = module.red.subnet_a_id
  sg_id      = module.red.sg_id
  ami_id     = data.aws_ami.amazon_linux_3.id
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Organization = "Mikroways"
    }
  }
}

data "aws_ami" "amazon_linux_3" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}