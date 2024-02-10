resource "aws_wafv2_ip_set" "sonarqube_ip" {
  name               = "${var.app_name}-IP-Set"
  description        = "Allowed IP range"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["0.0.0.0/1", "128.0.0.0/1"]
}


resource "aws_wafv2_web_acl" "sonarqube-waf" {
  name        = "${var.app_name}-waf"
  description = "Waf for sonarqube"
  scope       = "REGIONAL"

  default_action {
    block {}
  }
  dynamic "rule" {
    for_each = var.managed_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"

          dynamic "rule_action_override" {
            for_each = rule.value.excluded_rules
            content {
              name = rule_action_override.value
              action_to_use {
                count {}
              }

            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }
 
   rule {
    name     = "${var.app_name}-Allow-List"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.sonarqube_ip.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.app_name}-allow-list"
      sampled_requests_enabled   = false
    }
  }



  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "sonarqube-waf" {
  name              = "aws-waf-logs-${var.app_name}-waf"
  retention_in_days = 60
}


resource "aws_wafv2_web_acl_logging_configuration" "sonarqube-waf" {
  log_destination_configs = [aws_cloudwatch_log_group.sonarqube-waf.arn]
  resource_arn            = aws_wafv2_web_acl.sonarqube-waf.arn
}

