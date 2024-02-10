resource "aws_route53_record" "sonarqube-record-zone" {
  zone_id = data.aws_route53_zone.sonarqube-zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.sonarqube-alb.lb_dns_name
    zone_id                = module.sonarqube-alb.lb_zone_id
    evaluate_target_health = true
  }
}
