resource "aws_ecr_repository" "registry" {
  name = local.prefix
  tags = local.default_tags
}
