# Golden Mare Ventures — Terraform Modules

Reusable AWS Terraform modules. Each top-level directory is one module. Import
a module into any project by Git source and a version tag.

## Usage

```terraform
module "assets" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//s3?ref=v1.0.0"

  bucket_name = "my-application-assets"
  tags        = var.default_tags
}
```

Always pin `?ref=` to a release tag. Do not track `main`.

## Modules

| Module       | Purpose                                                               |
| ------------ | --------------------------------------------------------------------- |
| `amplify`    | Amplify app, branches, and domain association                         |
| `cloudfront` | CloudFront distribution with origin access control                    |
| `cloudwatch` | CloudWatch log group                                                  |
| `dynamodb`   | DynamoDB table                                                        |
| `iam/policy` | Managed IAM policy                                                    |
| `iam/role`   | IAM role with managed and inline policies                             |
| `iam/user`   | IAM user, access key, and policies                                    |
| `lambda`     | Lambda function                                                       |
| `rds-aurora` | Aurora cluster, instances, parameter groups, monitoring role          |
| `route53`    | Route 53 hosted zone and records                                      |
| `s3`         | S3 bucket with encryption, versioning, lifecycle, CORS, notifications |
| `ses`        | SES templates, configuration sets, and event destinations             |
| `ssm`        | SSM parameters                                                        |

Each module directory holds `main.tf`, `variables.tf`, and `outputs.tf`.
Modules with a `README.md` include input tables and examples.

## Development

```bash
npm install          # installs husky hooks
terraform fmt -recursive
```

Git hooks run automatically:

1. `pre-commit` — `terraform fmt -recursive -check`.
2. `commit-msg` — commitlint, conventional commits.
3. `pre-push` — `terraform init -backend=false` and `terraform validate` per module.

## Releases

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org).
`standard-version` builds `CHANGELOG.md` and the version tag.

```bash
npm run release      # prompts for major/minor/patch
git push --follow-tags
```

Use `major` for any change that breaks a module input or output.

## Conventions

- One resource group per module. No cross-module dependencies.
- Providers stay in the calling project. Modules declare no provider block.
- All modules accept a `tags` map.
