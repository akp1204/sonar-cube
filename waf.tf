
resource "aws_wafv2_web_acl" "sonarcube-waf" {
  name        = "sonarcube-waf"
  description = "Waf for sonarcube"
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


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "sonarcube-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "sonarcube-waf" {
  name              = "aws-waf-logs-sonarcube-waf"
  retention_in_days = 60
}


resource "aws_wafv2_web_acl_logging_configuration" "sonarcube-waf" {
  log_destination_configs = [aws_cloudwatch_log_group.sonarcube-waf.arn]
  resource_arn            = aws_wafv2_web_acl.sonarcube-waf.arn
}

