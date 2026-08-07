# SES Module

Creates and manages AWS SES email templates, configuration sets, and event destinations.

## Features

- Create email templates (HTML and text)
- Create SES configuration sets
- CloudWatch event destinations for email metrics
- SNS event destinations for notifications
- Flexible - use templates only or full configuration

## Usage

### Templates Only

```
module "ses_templates" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//ses?ref=v1.0.0"

  email_templates = {
    welcome = {
      name    = "welcome-email"
      subject = "Welcome to Our Service!"
      html    = file("${path.root}/../email-templates/welcome.html")
      text    = "Welcome to our service!"
    }
    password_reset = {
      name    = "password-reset"
      subject = "Reset Your Password"
      html    = file("${path.root}/../email-templates/reset.html")
    }
  }
}
```

### Templates from JSON Files

```
locals {
  email_templates_raw = {
    for file in fileset("${path.root}/../email-templates", "*.json") :
    trimsuffix(file, ".json") => jsondecode(file("${path.root}/../email-templates/${file}"))
  }

  email_templates = {
    for key, template in local.email_templates_raw :
    key => {
      name    = template.Template.TemplateName
      subject = template.Template.SubjectPart
      html    = template.Template.HtmlPart
      text    = template.Template.TextPart
    }
  }
}

module "ses_templates" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//ses?ref=v1.0.0"

  email_templates = local.email_templates
}
```

### Configuration Set with CloudWatch Metrics

```
module "ses_with_metrics" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//ses?ref=v1.0.0"

  email_templates = {
    welcome = {
      name    = "welcome-email"
      subject = "Welcome!"
      html    = file("${path.root}/../email-templates/welcome.html")
    }
  }

  configuration_sets = {
    main = {
      name                       = "my-app-config"
      reputation_metrics_enabled = true
      sending_enabled            = true
    }
  }

  cloudwatch_destinations = {
    send_metrics = {
      name                  = "SESSendMetrics"
      configuration_set_key = "main"  # References configuration_sets["main"]
      enabled               = true
      matching_types        = ["send", "bounce", "delivery", "renderingFailure"]
      cloudwatch = {
        default_value  = "none"
        dimension_name = "template"
        value_source   = "messageTag"
      }
    }
  }
}
```

### Multiple Configuration Sets

```
module "ses_multi" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//ses?ref=v1.0.0"

  configuration_sets = {
    transactional = {
      name = "transactional-emails"
    }
    marketing = {
      name = "marketing-emails"
    }
  }

  cloudwatch_destinations = {
    transactional_metrics = {
      name                  = "TransactionalMetrics"
      configuration_set_key = "transactional"
      matching_types        = ["send", "bounce", "delivery"]
      cloudwatch = {
        default_value  = "transactional"
        dimension_name = "email_type"
        value_source   = "messageTag"
      }
    }
    marketing_metrics = {
      name                  = "MarketingMetrics"
      configuration_set_key = "marketing"
      matching_types        = ["send", "open", "click"]
      cloudwatch = {
        default_value  = "marketing"
        dimension_name = "campaign"
        value_source   = "messageTag"
      }
    }
  }
}
```

### SNS Notifications for Bounces

```
resource "aws_sns_topic" "ses_bounces" {
  name = "ses-bounce-notifications"
}

module "ses_with_sns" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//ses?ref=v1.0.0"

  configuration_sets = {
    main = {
      name = "my-app-config"
    }
  }

  sns_destinations = {
    bounce_notifications = {
      name                  = "BounceNotifications"
      configuration_set_key = "main"
      matching_types        = ["bounce", "complaint"]
      topic_arn             = aws_sns_topic.ses_bounces.arn
    }
  }
}
```

### Complete Example (Everything)

```
resource "aws_sns_topic" "ses_bounces" {
  name = "ses-bounce-notifications"
}

module "ses_complete" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//ses?ref=v1.0.0"

  # Email templates
  email_templates = {
    welcome = {
      name    = "welcome-email"
      subject = "Welcome to {{company}}!"
      html    = file("${path.root}/../email-templates/welcome.html")
      text    = "Welcome!"
    }
    order_confirmation = {
      name    = "order-confirmation"
      subject = "Order #{{order_id}} Confirmed"
      html    = file("${path.root}/../email-templates/order.html")
    }
  }

  # Configuration sets
  configuration_sets = {
    transactional = {
      name                       = "transactional-emails"
      reputation_metrics_enabled = true
      sending_enabled            = true
    }
    marketing = {
      name            = "marketing-emails"
      sending_enabled = true
    }
  }

  # CloudWatch metrics
  cloudwatch_destinations = {
    transactional_metrics = {
      name                  = "TransactionalMetrics"
      configuration_set_key = "transactional"
      matching_types        = ["send", "bounce", "delivery", "renderingFailure"]
      cloudwatch = {
        default_value  = "transactional"
        dimension_name = "email_type"
        value_source   = "messageTag"
      }
    }
    marketing_metrics = {
      name                  = "MarketingMetrics"
      configuration_set_key = "marketing"
      matching_types        = ["send", "open", "click", "bounce"]
      cloudwatch = {
        default_value  = "marketing"
        dimension_name = "campaign"
        value_source   = "messageTag"
      }
    }
  }

  # SNS notifications
  sns_destinations = {
    bounce_notifications = {
      name                  = "BounceNotifications"
      configuration_set_key = "transactional"
      matching_types        = ["bounce", "complaint"]
      topic_arn             = aws_sns_topic.ses_bounces.arn
    }
  }
}
```

## Email Template Variables

Templates support variable substitution using `{{variable}}` syntax:

```html
<!-- welcome.html -->
<html>
  <body>
    <h1>Welcome {{firstName}}!</h1>
    <p>Thanks for joining {{companyName}}.</p>
  </body>
</html>
```

When sending:

```javascript
const params = {
  Template: "welcome-email",
  TemplateData: JSON.stringify({
    firstName: "John",
    companyName: "Acme Corp",
  }),
};
```

## Event Types

Common matching event types for destinations:

| Event Type         | Description                                    |
| ------------------ | ---------------------------------------------- |
| `send`             | Email was sent successfully                    |
| `reject`           | SES rejected the email                         |
| `bounce`           | Email bounced                                  |
| `complaint`        | Recipient marked as spam                       |
| `delivery`         | Email was delivered                            |
| `open`             | Recipient opened the email (requires tracking) |
| `click`            | Recipient clicked a link (requires tracking)   |
| `renderingFailure` | Template rendering failed                      |

## CloudWatch Value Sources

| Value Source  | Description                        |
| ------------- | ---------------------------------- |
| `messageTag`  | Custom tag from email headers      |
| `emailHeader` | Value from email header            |
| `linkTag`     | Custom link tag for click tracking |

## Inputs

| Name                    | Description                          | Type        | Default | Required |
| ----------------------- | ------------------------------------ | ----------- | ------- | -------- |
| email_templates         | Map of email templates               | map(object) | `{}`    | no       |
| configuration_sets      | Map of SES configuration sets        | map(object) | `{}`    | no       |
| cloudwatch_destinations | Map of CloudWatch event destinations | map(object) | `{}`    | no       |
| sns_destinations        | Map of SNS event destinations        | map(object) | `{}`    | no       |

### email_templates object

```
{
  name    = string           # Template name
  subject = string           # Email subject (can include {{variables}})
  html    = string           # HTML body (can include {{variables}})
  text    = optional(string) # Plain text fallback
}
```

### configuration_sets object

```
{
  name                       = string          # Configuration set name
  reputation_metrics_enabled = optional(bool)  # Default: true
  sending_enabled            = optional(bool)  # Default: true
}
```

### cloudwatch_destinations object

```
{
  name                  = string       # Destination name
  configuration_set_key = string       # Key from configuration_sets
  enabled               = optional(bool) # Default: true
  matching_types        = list(string) # Event types to track
  cloudwatch = {
    default_value  = string  # Default dimension value
    dimension_name = string  # CloudWatch dimension name
    value_source   = string  # messageTag, emailHeader, or linkTag
  }
}
```

### sns_destinations object

```
{
  name                  = string       # Destination name
  configuration_set_key = string       # Key from configuration_sets
  enabled               = optional(bool) # Default: true
  matching_types        = list(string) # Event types to notify
  topic_arn             = string       # SNS topic ARN
}
```

## Outputs

| Name                    | Description                            |
| ----------------------- | -------------------------------------- |
| template_names          | List of created template names         |
| template_arns           | Map of template keys to ARNs           |
| configuration_set_names | Map of configuration set keys to names |
| configuration_set_arns  | Map of configuration set keys to ARNs  |

## Sending Emails with Templates

### AWS CLI

```bash
aws ses send-templated-email \
  --source "sender@example.com" \
  --destination "ToAddresses=recipient@example.com" \
  --template "welcome-email" \
  --template-data '{"firstName":"John","companyName":"Acme"}' \
  --configuration-set-name "transactional-emails"
```

### Node.js SDK

```javascript
const AWS = require("aws-sdk");
const ses = new AWS.SES();

await ses
  .sendTemplatedEmail({
    Source: "sender@example.com",
    Destination: { ToAddresses: ["recipient@example.com"] },
    Template: "welcome-email",
    TemplateData: JSON.stringify({
      firstName: "John",
      companyName: "Acme Corp",
    }),
    ConfigurationSetName: "transactional-emails",
  })
  .promise();
```

## Notes

- Templates are global to the AWS account/region
- Configuration sets are required for event tracking
- CloudWatch metrics appear under AWS/SES namespace
- SNS topics must have permissions for SES to publish
- Maximum 10,000 templates per account
- Template variables use `{{variable}}` syntax (Handlebars-like)

## Viewing Metrics

```bash
# List CloudWatch metrics
aws cloudwatch list-metrics --namespace AWS/SES

# Get metric data
aws cloudwatch get-metric-statistics \
  --namespace AWS/SES \
  --metric-name Send \
  --dimensions Name=template,Value=welcome-email \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-31T23:59:59Z \
  --period 86400 \
  --statistics Sum
```

## Importing Existing Resources

```bash
# Import template
terraform import 'module.ses.aws_ses_template.templates["welcome"]' welcome-email

# Import configuration set
terraform import 'module.ses.aws_sesv2_configuration_set.config_sets["main"]' my-config-set

# Import event destination
terraform import 'module.ses.aws_ses_event_destination.cloudwatch_destinations["metrics"]' my-config-set/MetricsDestination
```
