# ecs/service/tests/service_connect.tftest.hcl

mock_provider "aws" {
  # The IAM roles validate this string as JSON, so an un-overridden mock fails the plan.
  override_data {
    target = data.aws_iam_policy_document.assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"}}]}"
    }
  }
}

variables {
  name        = "gmv-test"
  cluster_arn = "arn:aws:ecs:us-east-1:000000000000:cluster/gmv-test"
  vpc_id      = "vpc-00000000"
  subnet_ids  = ["subnet-0000000a", "subnet-0000000b"]
  containers = {
    api = {
      image         = "example.dkr.ecr.us-east-1.amazonaws.com/portal:test"
      port_mappings = [{ container_port = 8000, name = "http", app_protocol = "http" }]
    }
  }
}

run "GMV_148_AC_2_default_off_plain_service" {
  command = plan

  assert {
    condition     = length(aws_ecs_service.service[0].service_connect_configuration) == 0
    error_message = "With service_connect unset, the plain service must render no service_connect_configuration block."
  }
}

run "GMV_148_AC_2_default_off_pinned_service" {
  command = plan

  variables {
    ignore_task_definition_changes = true
  }

  assert {
    condition     = length(aws_ecs_service.service_pinned[0].service_connect_configuration) == 0
    error_message = "With service_connect unset, the pinned service must render no service_connect_configuration block."
  }
}

run "server_renders_service_with_client_alias" {
  command = plan

  variables {
    service_connect = {
      services = [{
        port_name      = "http"
        discovery_name = "portal-api"
        client_alias   = { port = 8000, dns_name = "portal-api" }
      }]
    }
  }

  assert {
    condition     = aws_ecs_service.service[0].service_connect_configuration[0].enabled == true
    error_message = "service_connect.enabled must default to true."
  }

  assert {
    condition     = aws_ecs_service.service[0].service_connect_configuration[0].service[0].port_name == "http"
    error_message = "The service port_name must be passed through."
  }

  assert {
    condition     = aws_ecs_service.service[0].service_connect_configuration[0].service[0].discovery_name == "portal-api"
    error_message = "The service discovery_name must be passed through."
  }

  assert {
    condition     = aws_ecs_service.service[0].service_connect_configuration[0].service[0].client_alias[0].port == 8000
    error_message = "The client_alias port must be passed through."
  }

  assert {
    condition     = aws_ecs_service.service[0].service_connect_configuration[0].service[0].client_alias[0].dns_name == "portal-api"
    error_message = "The client_alias dns_name must be passed through."
  }
}

run "client_only_renders_enabled_with_no_services" {
  command = plan

  variables {
    service_connect = { enabled = true }
  }

  assert {
    condition     = length(aws_ecs_service.service[0].service_connect_configuration) == 1
    error_message = "A client-only service must render exactly one service_connect_configuration block."
  }

  assert {
    condition     = aws_ecs_service.service[0].service_connect_configuration[0].enabled == true
    error_message = "A client-only service must set enabled = true."
  }

  assert {
    condition     = length(aws_ecs_service.service[0].service_connect_configuration[0].service) == 0
    error_message = "A client-only service must render no service entries."
  }
}

run "namespace_passes_through_when_set" {
  command = plan

  variables {
    service_connect = { namespace = "gmv-stage" }
  }

  assert {
    condition     = aws_ecs_service.service[0].service_connect_configuration[0].namespace == "gmv-stage"
    error_message = "A namespace set by the caller must reach the service."
  }
}

run "server_renders_on_pinned_service" {
  command = plan

  variables {
    ignore_task_definition_changes = true
    service_connect = {
      services = [{
        port_name      = "http"
        discovery_name = "portal-api"
        client_alias   = { port = 8000, dns_name = "portal-api" }
      }]
    }
  }

  assert {
    condition     = aws_ecs_service.service_pinned[0].service_connect_configuration[0].enabled == true
    error_message = "service_connect.enabled must default to true on the pinned service."
  }

  assert {
    condition     = aws_ecs_service.service_pinned[0].service_connect_configuration[0].service[0].port_name == "http"
    error_message = "The pinned service port_name must be passed through."
  }

  assert {
    condition     = aws_ecs_service.service_pinned[0].service_connect_configuration[0].service[0].discovery_name == "portal-api"
    error_message = "The pinned service discovery_name must be passed through."
  }

  assert {
    condition     = aws_ecs_service.service_pinned[0].service_connect_configuration[0].service[0].client_alias[0].port == 8000
    error_message = "The pinned service client_alias port must be passed through."
  }

  assert {
    condition     = aws_ecs_service.service_pinned[0].service_connect_configuration[0].service[0].client_alias[0].dns_name == "portal-api"
    error_message = "The pinned service client_alias dns_name must be passed through."
  }
}

run "unknown_port_name_fails_precondition" {
  command = plan

  variables {
    service_connect = {
      services = [{ port_name = "nope" }]
    }
  }

  expect_failures = [aws_ecs_service.service]
}

run "unknown_port_name_fails_precondition_on_pinned_service" {
  command = plan

  variables {
    ignore_task_definition_changes = true
    service_connect = {
      services = [{ port_name = "nope" }]
    }
  }

  expect_failures = [aws_ecs_service.service_pinned]
}
