locals {
    cluster_name = "xyz-cluster"
    cluster_version = "1.27"
    region = "us-east-2"
    vpc_cidr = "10.0.0.0/16"
    azs = slice(data.aws_availability_zones.available.names, 0, 3)
    tags = {
      environment = "sandbox"
      team = "xyz"
    }
}