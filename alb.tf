module "sonarcube-alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "7.0.0"

  name = "sonarcube"

  load_balancer_type = "application"

  vpc_id          = module.sonarcube-vpc.vpc_id
  subnets         = module.sonarcube-vpc.public_subnets
  security_groups = [module.lb_sg.security_group_id]

  enable_deletion_protection = true

  // access_logs = {
  //   bucket = "my-alb-logs"
  // }

  target_groups = [{
    target_type      = "ip"
    backend_protocol = "HTTP"
    backend_port     = 9000
    stickiness = {
      enable = true
      type   = "lb_cookie"
    }
    health_check = {
      enabled             = true
      interval            = 30
      path                = "/"
      port                = "9000"
      healthy_threshold   = 2
      unhealthy_threshold = 3
      timeout             = 10
      protocol            = "HTTP"
      matcher             = "200,301,302"
    }
  }]

  http_tcp_listeners = [
    # Forward action is default, either when defined or undefined
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
  ]

  https_listeners = [
    {
      port     = 443
      protocol = "HTTPS"
      #certificate_arn             = data.aws_acm_certificate.cert.arn
      certificate_arn    = aws_acm_certificate.sonarcube-acm.arn
      ssl_policy         = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
      target_group_index = 0
    }
  ]
}

resource "aws_wafv2_web_acl_association" "waf" {
  resource_arn = module.sonarcube-alb.lb_arn
  web_acl_arn  = aws_wafv2_web_acl.sonarcube-waf.arn
}

