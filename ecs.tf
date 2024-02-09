resource "aws_cloudwatch_log_group" "sonarcube-ecs" {
  name              = "/aws/ecs/sonarcuibe-ecs"
  retention_in_days = 60
}


##### Data Template For WebAPP #####

data "template_file" "sonarcube-temp" {
  template = file("${path.module}/template/sonarcube.json.tpl")
  vars = {
    sonar_db_username = var.sonar_db_username
    sonar_db_password = var.sonar_db_password
    sonar_db_name     = var.sonar_db_name
  }
}

##### ECS WebApp Cluster #####
resource "aws_ecs_cluster" "sonarcube-cluster" {
  name = "sonarcube-ecs"
  setting {
    name  = "containerInsights"
    value = true
  }
}

##### ECS WebApp Task #####
resource "aws_ecs_task_definition" "sonarcube-ecs-task-definition" {
  family                   = "sonarcube-ecs-task"
  execution_role_arn       = module.ecs_execution_role.iam_role_arn
  task_role_arn            = module.ecs_execution_role.iam_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = data.template_file.sonarcube-temp.rendered
}

#### ECS WebApp Service #####
resource "aws_ecs_service" "sonarcube-app-ecs-service" {
  name                               = "sonarcube-ecs-svc"
  cluster                            = aws_ecs_cluster.sonarcube-cluster.id
  task_definition                    = aws_ecs_task_definition.sonarcube-ecs-task-definition.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100
  health_check_grace_period_seconds  = 50

  network_configuration {
    security_groups  = [aws_security_group.sonarcube-ecs-tasks-sg.id]
    subnets          = var.private_subnet_id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "sonarcube-container"
    container_port   = 9000
  }
}


resource "aws_appautoscaling_target" "ecs-target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.sonarcube-cluster.name}/${aws_ecs_service.sonarcube-app-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs-policy" {
  name               = "sonarcube-${var.env}-autoscaling-policy-01"
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

