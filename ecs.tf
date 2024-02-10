resource "aws_cloudwatch_log_group" "sonarqube-ecs" {
  name              = "/aws/ecs/${var.app_name}-ecs"
  retention_in_days = 60
}


resource "aws_cloudwatch_log_group" "sonarqube-ecs-task" {
  name              = "/aws/ecs/${var.app_name}-ecs-task"
  retention_in_days = 60
}


resource "random_password" "master_password" {
  length  = 10
  special = false
}


##### Data Template For WebAPP #####

data "template_file" "sonarqube-temp" {
  template = file("${path.module}/template/sonarqube.json.tpl")
  vars = {
    sonar_db_username = var.sonar_db_username
    sonar_db_password = random_password.master_password.result
    sonar_db_name     = var.sonar_db_name
    sonar_endpoint    = module.sonarqube-rds.db_instance_endpoint
    app_name          = var.app_name
  }
}

##### ECS WebApp Cluster #####
resource "aws_ecs_cluster" "sonarqube-cluster" {
  name = "${var.app_name}-ecs"
}

##### ECS WebApp Task #####
resource "aws_ecs_task_definition" "sonarqube-ecs-task-definition" {
  #depends_on = [module.sonar-rds]
  family                   = "${var.app_name}-ecs-task"
  execution_role_arn       = module.ecs_execution_role.iam_role_arn
  task_role_arn            = module.ecs_execution_role.iam_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = data.template_file.sonarqube-temp.rendered
}

#### ECS WebApp Service #####
resource "aws_ecs_service" "sonarqube-app-ecs-service" {
  name                               = "${var.app_name}-ecs-svc"
  cluster                            = aws_ecs_cluster.sonarqube-cluster.id
  task_definition                    = aws_ecs_task_definition.sonarqube-ecs-task-definition.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100
  health_check_grace_period_seconds  = 50

  network_configuration {
    security_groups  = [module.app_sg.security_group_id]
    subnets          = module.sonarqube-vpc.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.sonarqube-alb.target_group_arns[0]
    container_name   = "${var.app_name}-container"
    container_port   = 9000
  }
}


resource "aws_appautoscaling_target" "ecs-target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.sonarqube-cluster.name}/${aws_ecs_service.sonarqube-app-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs-policy" {
  name               = "${var.app_name}-autoscaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs-target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs-target.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 50
    scale_out_cooldown = 100
  }
}

