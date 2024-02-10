module "sonar-rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.9.0"

  identifier = "${var.app_name}-rds"


  engine                    = "postgres"
  engine_version            = "12.14"
  instance_class            = "t2.small"
  allocated_storage         = 20
  ca_cert_identifier        = "rds-ca-rsa4096-g1"
  apply_immediately         = true
  create_db_parameter_group = "false"
  username                  = var.sonar_db_username
  password                  = random_password.master_password.result
  db_name                  = var.sonar_db_name


  multi_az = "false"
  port     = "5432"

  iam_database_authentication_enabled = false

  vpc_security_group_ids = [module.database_sg.security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  copy_tags_to_snapshot   = "true"
  backup_retention_period = "30" #days
  backup_window           = "03:00-06:00"


  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = module.sonarqube-vpc.database_subnets

  # DB parameter group
  family = "postgres12"

  # DB option group
  major_engine_version = "12.14"

  # Database Deletion Protection
  deletion_protection = true

}


