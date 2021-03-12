data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_security_group" "worker_group_mgmt" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
  tags = local.default_tags
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
  tags = local.default_tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "14.0.0"

  cluster_name = local.prefix
  subnets      = module.vpc.private_subnets

  # Move to true once this is fixed https://github.com/terraform-aws-modules/terraform-aws-eks/issues/911
  # Meanwhile I had to do it manually https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
  manage_aws_auth = false

  cluster_version = 1.19
  tags            = local.default_tags

  vpc_id               = module.vpc.vpc_id
  wait_for_cluster_cmd = "until curl -k -s $ENDPOINT/healthz >/dev/null; do sleep 4; done"
  enable_irsa     = true

  worker_groups = [
    {
      name                          = "worker-group"
      instance_type                 = "t2.medium"
      root_volume_type              = "gp2"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
      tags = [
        {
          key = "k8s.io/cluster-autoscaler/enabled"
          propagate_at_launch = "false"
          value = "true"
        },
        {
          key = "k8s.io/cluster-autoscaler/${local.prefix}"
          propagate_at_launch = "false"
          value = "true"
        }
      ]
    }
  ]

  map_users = [
    {
      userarn  = "arn:aws:iam::${var.aws_account_id}:user/system/githubactions"
      username = "githubactions"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${var.aws_account_id}:user/smarconi"
      username = "smarconi"
      groups   = ["system:masters"]
    }
  ]
}

module "alb_ingress_controller" {
  source  = "iplabs/alb-ingress-controller/kubernetes"
  version = "3.4.0"

  providers = {
    kubernetes = kubernetes.eks
  }

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name  = var.region
  k8s_cluster_name = data.aws_eks_cluster.cluster.name
  aws_tags         = local.default_tags
}

