module "lb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "sonarcube-lb-sg"
  description = "Security group with HTTPS access for healthystart load balancer"

  vpc_id              = module.sonarcube-vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Internal network"
      cidr_blocks = module.sonarcube-vpc.vpc_cidr_block
    },
  ]
}

module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "sonarcube-app-sg"
  description = "Security group for access to the healthystart app"
  vpc_id      = module.sonarcube-vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 9000
      to_port                  = 9000
      protocol                 = "tcp"
      description              = "Allow LB into healthystart app"
      source_security_group_id = module.lb_sg.security_group_id
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Internal network"
      cidr_blocks = module.sonarcube-vpc.vpc_cidr_block
    },
  ]
}



module "database_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "sonarcube-db-sg"
  description = "Security group Postgres access"
  vpc_id      = module.sonarcube-vpc.vpc_id

  ingress_rules = ["postgresql-tcp"]


  ingress_with_source_security_group_id = [
    {
      description              = "Postgres from app SG"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_sg.security_group_id
    },
  ]
}



