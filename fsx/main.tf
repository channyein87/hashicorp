locals {
  application-name = "${var.app-name}"
  name-prefix      = "${var.project}-${var.account}-${local.application-name}-${var.environment}" # uon-research-tastefgw-prod

  asg_tags = ["${concat(
  list(
    map("key", "Name", "value", "${var.project}-${var.account}-${local.application-name}-${var.environment}", "propagate_at_launch", true),
    map("key", "App", "value", "${lookup(var.tags, "App")}", "propagate_at_launch", true),
    map("key", "Environment","value", "${lookup(var.tags, "Environment")}", "propagate_at_launch", true),
    map("key", "Terraform", "value", "true", "propagate_at_launch", true),
    map("key", "MaintenanceWindow", "value", "ProdWindows1", "propagate_at_launch", true)
  ))}"]

  common_tags = {
    Name              = "${lookup(var.tags, "Name")}"
    App               = "${lookup(var.tags, "App")}"
    Environment       = "${lookup(var.tags, "Environment")}"
    Terraform         = "true"
    MaintenanceWindow = ""
  }
}


resource "aws_fsx_windows_file_system" "file_system" {
  kms_key_id          = "${aws_kms_key.fsx_key.arn}"
  storage_capacity    = "${var.storage}"
  subnet_ids          = ["${var.subnet-ids}"]
  throughput_capacity = "${var.throughput}"

  self_managed_active_directory {
    dns_ips     = ["${var.active-directory-dns-ips}"]
    domain_name = "${var.active-directory-domain-name}"
    username    = "${var.active-directory-username}"
    password    = "${var.active-directory-password}"
    file_system_administrators_group = "${var.active-directory-admin-group}"
    organizational_unit_distinguished_name = "${var.active-directory-ou}"
  }

  skip_final_backup = true

  tags = "${local.asg_tags}"
}

# --------------
# KMS key Stanza
# --------------

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid    = "Enable IAM Administration"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cross_account_administrator_access",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DDevOpsCrossAccountAdmin",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OktaCrossAccountAdmin",
      ]
    }

    actions = [
      "kms:*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_kms_key" "fsx_key" {
  description             = "${local.name-prefix}"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  is_enabled              = true
  policy                  = "${data.aws_iam_policy_document.kms_key_policy.json}"
}

resource "aws_kms_alias" "fsx_key_alias" {
  name          = "alias/${local.name-prefix}"
  target_key_id = "${aws_kms_key.fsx_key.key_id}"
}


#
#
#

variable "app-name" {}
variable "subnet-ids" { type = "list" }
variable "storage" {} # 32 to 65536 GB
variable "throughput" {} # 8 to 2048
variable "active-directory-dns-ips" { type = "list" }
variable "active-directory-domain-name" {}
variable "active-directory-username" {}
variable "active-directory-password" {}
variable "active-directory-admin-group" {}
variable "active-directory-ou" {}

variable "region" {}
variable "project" {}
variable "environment" {}
variable "account" {}
variable "tags" {
  type        = "map"
  default     = {}
}
data "aws_caller_identity" "current" {}

/*
output "dns-name" {
  value = "${aws_fsx_windows_file_system.file_system.dns_name}"
}
*/