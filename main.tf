provider "aws" {
  version = "~> 4.0"
  region = var.region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "tf-netvrk-vpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-netvrk"
  }
}

resource "aws_network_interface" "tf-netvrkdb" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "tf-netvrk" {
  ami           = "ami-05fa00d4c63e32376" # us-east-1
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.tf-netvrkdb.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  

  name                 = "tf-netvrkdb"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["172.16.10.0/24", "172.16.20.0/24", "172.16.30.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "tf-netvrkdb" {
  name       = "tf-netvrkdb"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "tf-netvrkdb"
  }
}

resource "aws_security_group" "rds" {
  name   = "tf-netvrkdb"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-netvrkdb"
  }
}

resource "aws_db_instance" "tf-netvrkdb" {
  allocated_storage    = 0
  engine               = "aurora-postgresql"
  engine_version       = "13.7"
  instance_class       = "db.t3.medium"
  db_name              = "terraform"
  username             = "tfadmin"
  password             = var.db_password
  parameter_group_name = aws_db_parameter_group.tf-netvrkdb.name
  availability_zone = "us-east-1a"
  skip_final_snapshot  = true
}
resource "aws_db_parameter_group" "tf-netvrkdb" {
  name   = "tf-netvrkdb"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_rds_cluster" "default" {
  cluster_identifier     = "tf-netvrkdb"
  #allocated_storage      = 5
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "12.7"
  availability_zones     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  master_username        = "tfadmin"
  master_password        = var.db_password
  backup_retention_period = 5
  db_subnet_group_name   = aws_db_subnet_group.tf-netvrkdb.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  #parameter_group_name   = aws_db_parameter_group.tf-netvrkdb.name
  #publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  identifier         = "tf-netvrkdb"
  count              = 1
  cluster_identifier = aws_rds_cluster.default.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
  availability_zone = "us-east-1a" 
  publicly_accessible = false
}

data "aws_db_snapshot" "latest_prod_snapshot" {
  db_instance_identifier = aws_db_instance.tf-netvrkdb.id
  most_recent            = true 
} 

# Use the latest production snapshot to create a dev instance.
 resource "aws_db_instance" "dev" {
  instance_class      = "db.t3.medium"
  db_name                = "mydbdev"
  snapshot_identifier = data.aws_db_snapshot.latest_prod_snapshot.id

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
} 