# oidc

An IAM OIDC identity provider, plus the trust policy that goes with it.

The module creates the provider only. Roles come from `iam/role`, as everywhere
else. What the module adds beyond one raw resource is the
`assume_role_policy` output: the condition keys are prefixed with the issuer
host rather than the URL, and a wildcard subject silently never matches under
`StringEquals`. Both are easy to get wrong and produce a policy that parses
cleanly and never grants anything.

## GitHub Actions deploying to AWS with no access key

```terraform
module "github_oidc" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//oidc?ref=v1.3.0"

  url = "https://token.actions.githubusercontent.com"

  # Only these refs of this repository may assume a role. A run from a fork or
  # from any other branch receives no credentials.
  subjects = [
    "repo:myorg/myrepo:ref:refs/heads/dev",
    "repo:myorg/myrepo:ref:refs/heads/main",
  ]

  tags = var.default_tags
}

module "ci_deploy_role" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//iam/role?ref=v1.3.0"

  role_name          = "myapp-ci-deploy-role"
  description        = "Assumed by GitHub Actions over OIDC"
  assume_role_policy = module.github_oidc.assume_role_policy

  inline_policies = {
    "ecr-push" = jsonencode({ ... })
  }
}
```

In the workflow, request the token and exchange it:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ vars.AWS_DEPLOY_ROLE_ARN }}
      aws-region: us-east-1
```

## Every pull request in one repository

A wildcard switches the subject condition to `StringLike` automatically.

```terraform
module "github_oidc" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//oidc?ref=v1.3.0"

  url      = "https://token.actions.githubusercontent.com"
  subjects = ["repo:myorg/myrepo:pull_request", "repo:myorg/myrepo:ref:refs/tags/v*"]
}
```

## Building the trust policy by hand

Use `provider_host` and `arn` when the policy needs conditions the module does
not build, such as `job_workflow_ref`.

```terraform
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Effect    = "Allow"
    Action    = "sts:AssumeRoleWithWebIdentity"
    Principal = { Federated = module.github_oidc.arn }
    Condition = {
      StringEquals = {
        "${module.github_oidc.provider_host}:aud" = "sts.amazonaws.com"
      }
      StringLike = {
        "${module.github_oidc.provider_host}:job_workflow_ref" = "myorg/myrepo/.github/workflows/deploy.yml@*"
      }
    }
  }]
})
```

## Inputs

| Name              | Type           | Default                  | Purpose                                                                    |
| ----------------- | -------------- | ------------------------ | -------------------------------------------------------------------------- |
| `url`             | `string`       | required                 | Issuer URL, including `https://`                                            |
| `client_id_list`  | `list(string)` | `["sts.amazonaws.com"]`  | Audiences the provider may issue tokens for                                 |
| `thumbprint_list` | `list(string)` | `[]`                     | Issuer certificate thumbprints. Leave empty for GitHub                      |
| `subjects`        | `list(string)` | `[]`                     | Subject claims allowed to assume a role. Empty means no subject condition   |
| `tags`            | `map(string)`  | `{}`                     | Tags                                                                        |

## Outputs

| Name                         | Purpose                                                     |
| ---------------------------- | ----------------------------------------------------------- |
| `arn`                        | Provider ARN, for the `Federated` principal                  |
| `url`                        | Issuer URL                                                   |
| `provider_host`              | Issuer URL without the scheme, the condition-key prefix      |
| `assume_role_policy`         | Ready-made trust policy JSON for `iam/role`                  |
| `subject_condition_operator` | `StringLike` or `StringEquals`, whichever the subjects imply |

## One provider per issuer per account

`aws_iam_openid_connect_provider` is account-global and unique by URL. A second
project in the same AWS account that also calls this module for GitHub will
fail its apply with `EntityAlreadyExists`. Create the provider in one root and
have the others read it:

```terraform
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
```

## Leaving `subjects` empty

The subject condition is then omitted entirely, and any subject the issuer will
ever mint can assume the role. For GitHub that means every repository on
github.com. Set `subjects` unless a narrower condition is supplied by hand.
