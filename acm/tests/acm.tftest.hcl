# acm/tests/acm.tftest.hcl

mock_provider "aws" {}

variables {
  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com"]
  zone_id                   = "Z0000000000000EXAMPLE"
}

# Not asserted at plan time: create_before_destroy is a lifecycle meta-argument, and the validation
# resource waiting for ISSUED, certificate_arn, and record fqdn values are known only after apply.

run "GMV_149_AC_2_readme_example_apex_plus_wildcard" {
  command = plan

  override_resource {
    target          = aws_acm_certificate.certificate
    override_during = plan
    values = {
      domain_validation_options = [
        {
          domain_name           = "example.com"
          resource_record_name  = "_abc123.example.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
        {
          domain_name           = "*.example.com"
          resource_record_name  = "_abc123.example.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
      ]
    }
  }

  assert {
    condition     = aws_acm_certificate.certificate.domain_name == "example.com"
    error_message = "The certificate must be issued for the apex domain example.com."
  }

  assert {
    condition     = aws_acm_certificate.certificate.subject_alternative_names == toset(["*.example.com"])
    error_message = "The certificate must carry *.example.com as its only subject alternative name."
  }

  assert {
    condition     = aws_acm_certificate.certificate.validation_method == "DNS"
    error_message = "The certificate must use DNS validation."
  }

  assert {
    condition     = aws_acm_certificate.certificate.options[0].certificate_transparency_logging_preference == "ENABLED"
    error_message = "Certificate transparency logging must be explicitly enabled."
  }

  assert {
    condition     = length(aws_route53_record.validation) == 2
    error_message = "The apex and the wildcard must each get a validation record instance."
  }

  assert {
    condition     = toset(keys(aws_route53_record.validation)) == toset(["example.com", "*.example.com"])
    error_message = "Validation records must be keyed by the domain name they validate."
  }

  assert {
    condition     = output.domain_name == "example.com"
    error_message = "The domain_name output must echo the input."
  }
}

run "validation_records_target_caller_zone" {
  command = plan

  override_resource {
    target          = aws_acm_certificate.certificate
    override_during = plan
    values = {
      domain_validation_options = [
        {
          domain_name           = "example.com"
          resource_record_name  = "_abc123.example.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
        {
          domain_name           = "*.example.com"
          resource_record_name  = "_abc123.example.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
      ]
    }
  }

  assert {
    condition     = alltrue([for r in aws_route53_record.validation : r.zone_id == "Z0000000000000EXAMPLE"])
    error_message = "Every validation record must be written to the caller's hosted zone."
  }

  assert {
    condition     = alltrue([for r in aws_route53_record.validation : r.allow_overwrite == true])
    error_message = "Validation records must allow overwrite because the apex and wildcard share one CNAME."
  }

  assert {
    condition     = alltrue([for r in aws_route53_record.validation : r.ttl == 60])
    error_message = "Validation records must have a TTL of 60 seconds."
  }

  assert {
    condition     = alltrue([for r in aws_route53_record.validation : r.type == "CNAME"])
    error_message = "Validation records must be CNAME records."
  }

  assert {
    condition     = alltrue([for r in aws_route53_record.validation : r.name == "_abc123.example.com."])
    error_message = "Validation records must use the record name ACM supplies."
  }

  assert {
    condition     = alltrue([for r in aws_route53_record.validation : r.records == toset(["_def456.acm-validations.aws."])])
    error_message = "Validation records must use the record value ACM supplies."
  }
}

run "tags_reach_certificate" {
  command = plan

  variables {
    tags = {
      Project = "test"
    }
  }

  override_resource {
    target          = aws_acm_certificate.certificate
    override_during = plan
    values = {
      domain_validation_options = [
        {
          domain_name           = "example.com"
          resource_record_name  = "_abc123.example.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
        {
          domain_name           = "*.example.com"
          resource_record_name  = "_abc123.example.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
      ]
    }
  }

  assert {
    condition     = aws_acm_certificate.certificate.tags["Project"] == "test"
    error_message = "The tags input must be applied to the certificate."
  }
}

run "no_sans_yields_one_record" {
  command = plan

  variables {
    subject_alternative_names = []
  }

  override_resource {
    target          = aws_acm_certificate.certificate
    override_during = plan
    values = {
      domain_validation_options = [
        {
          domain_name           = "example.com"
          resource_record_name  = "_abc123.example.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
      ]
    }
  }

  assert {
    condition     = length(aws_acm_certificate.certificate.subject_alternative_names) == 0
    error_message = "A certificate with no SANs input must carry no subject alternative names."
  }

  assert {
    condition     = length(aws_route53_record.validation) == 1
    error_message = "A certificate with a single name must produce exactly one validation record."
  }
}

run "wildcard_only_certificate" {
  command = plan

  variables {
    domain_name               = "*.example.com"
    subject_alternative_names = []
  }

  override_resource {
    target          = aws_acm_certificate.certificate
    override_during = plan
    values = {
      domain_validation_options = [
        {
          domain_name           = "*.example.com"
          resource_record_name  = "_abc123.example.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
      ]
    }
  }

  assert {
    condition     = aws_acm_certificate.certificate.domain_name == "*.example.com"
    error_message = "A wildcard-only certificate must keep the wildcard as its domain name."
  }

  assert {
    condition     = length(aws_route53_record.validation) == 1
    error_message = "A wildcard-only certificate must produce exactly one validation record."
  }
}
