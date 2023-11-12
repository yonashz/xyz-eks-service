locals {
  cluster_name    = "xyz-cluster"
  cluster_version = "1.27"
  region          = "us-east-2"
  user_arn        = "arn:aws:iam::568903012602:user/assumeprovisionerrole"
  host            = "xyz.zyonash.com"
  vpc_cidr        = "10.0.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  app_version     = "0.4.0"
  tags = {
    environment = "sandbox"
    team        = "xyz"
  }
}