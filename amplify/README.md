# Example Usage

## Current NextJS Setup

```
locals {
  node_version = jsonencode([
    {
      name    = "Node.js version"
      pkg     = "node"
      type    = "nvm"
      version = "20"
    },
    {
      name    = "Next.js version"
      pkg     = "next-version"
      type    = "internal"
      version = "16"
    }
  ])
}

module "amplify" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//amplify?ref=v1.0.0"

  app_name           = var.project_name
  repository_url     = var.repo_url
  service_role_arn   = var.amplify_service_role_arn
  compute_role_arn   = var.amplify_compute_role_arn
  oauth_token        = var.oauth_token

  default_environment_variables = {
    _LIVE_UPDATES = local.node_version
  }

  custom_rules = [
    {
      source = "/<*>"
      status = "404-200"
      target = "/index.html"
    }
  ]

  branches = {
    master = {
      stage             = "PRODUCTION"
      enable_auto_build = false
    }
    dev = {
      enable_auto_build = true
    }
  }

  domain_name = var.domain_name
  sub_domains = [
    { branch_name = "master", prefix = "" },
    { branch_name = "master", prefix = "www" },
    { branch_name = "dev", prefix = "test" }
  ]
}
```

## With branch-specific env vars

```
module "amplify" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//amplify?ref=v1.0.0"

  app_name         = "my-app"
  repository_url   = "https://bitbucket.org/user/repo"
  service_role_arn = data.terraform_remote_state.global.outputs.amplify_service_role_arn
  oauth_token      = var.oauth_token

  default_environment_variables = {
    API_URL = "https://api.example.com"
  }

  branches = {
    prod = {
      display_name      = "Production"
      stage             = "PRODUCTION"
      enable_auto_build = false
      environment_variables = {
        ENVIRONMENT = "production"
        API_URL     = "https://api.example.com"  # Override default
      }
    }
    stage = {
      stage             = "BETA"
      enable_auto_build = true
      environment_variables = {
        ENVIRONMENT = "staging"
        API_URL     = "https://staging-api.example.com"
      }
    }
    dev = {
      enable_auto_build = true
      environment_variables = {
        ENVIRONMENT = "development"
        API_URL     = "https://dev-api.example.com"
      }
    }
  }

  domain_name = "example.com"
  sub_domains = [
    { branch_name = "prod", prefix = "" },
    { branch_name = "prod", prefix = "www" },
    { branch_name = "stage", prefix = "staging" },
    { branch_name = "dev", prefix = "dev" }
  ]
}
```
