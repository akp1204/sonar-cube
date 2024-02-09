variable "domain_name" {
  default = "927827734038.realhandsonlabs.net"
}

variable "managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    excluded_rules  = list(string)
  }))
  description = "List of Managed WAF rules."
  default = [
    {
      name            = "AWSManagedRulesAdminProtectionRuleSet",
      priority        = 1
      override_action = "count"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesAmazonIpReputationList",
      priority        = 2
      override_action = "count"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesAnonymousIpList",
      priority        = 3
      override_action = "count"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesCommonRuleSet",
      priority        = 4
      override_action = "count"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet",
      priority        = 5
      override_action = "count"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet",
      priority        = 6
      override_action = "count"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesBotControlRuleSet",
      priority        = 7
      override_action = "count"
      excluded_rules  = []
    }
  ]
}

