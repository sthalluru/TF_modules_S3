/* This file is only evaluated if s3_bucket_replicate is set to true.
*/

resource "aws_s3_bucket" "replica" {
  /* If s3_bucket_replicate is set to true, this stanza will be evaluated.
     If s3_bucket_replicate is set to false, this stanza will be ignored and no
     bucket will be created.

     For further explanation, see:
     https://www.terraform.io/docs/configuration/interpolation.html */

  count = var.s3_bucket_replicate ? 1 : 0

  provider = aws.replica
  bucket   = "${var.s3_bucket_name}-replica"
  acl      = var.s3_bucket_acl

  tags = {
    Name              = "${var.s3_bucket_name}-replica"
    TF_Environment    = var.s3_bucket_environment
    TF_Responsible    = var.s3_bucket_responsible
    TF_Replicate      = "replica"
    TF_VersionControl = "true"
    application       = var.s3_bucket_application
    business          = var.s3_bucket_business
    layer             = var.s3_bucket_layer
    stack             = var.s3_bucket_stack
    Terraform         = var.s3_terraform
    Terraform_Source  = var.s3_terraform_source
  }

  logging {
    target_bucket = var.s3_replica_logging_bucket_name
    target_prefix = var.s3_logging_prefix
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    ## https://confluence.cms.gov/pages/viewpage.action?spaceKey=AWSWMMG&title=Application+data+retention+period+policy
    prefix  = ""
    enabled = var.s3_lifecycle_enabled

    expiration {
      days = var.s3_lifecycle_expire
    }

    noncurrent_version_expiration {
      days = var.s3_lifecycle_noncurrent_expire
    }

    # This moves the data in the replica to different storage classes.
    # https://www.terraform.io/docs/providers/aws/r/s3_bucket.html#transition
    transition {
      days          = var.s3_move_replica_to_standard_ia_after
      storage_class = "STANDARD_IA"
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.replica_lifecycle_addition

    content {
      id                                     = lookup(lifecycle_rule.value, "id", null)
      prefix                                 = lookup(lifecycle_rule.value, "prefix", null)
      tags                                   = lookup(lifecycle_rule.value, "tags", null)
      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)
      enabled                                = lifecycle_rule.value.enabled

      # Max 1 block - expiration
      dynamic "expiration" {
        for_each = length(keys(lookup(lifecycle_rule.value, "expiration", {}))) == 0 ? [] : [lookup(lifecycle_rule.value, "expiration", {})]

        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      # Several blocks - transition
      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition", [])

        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      # Max 1 block - noncurrent_version_expiration
      dynamic "noncurrent_version_expiration" {
        for_each = length(keys(lookup(lifecycle_rule.value, "noncurrent_version_expiration", {}))) == 0 ? [] : [lookup(lifecycle_rule.value, "noncurrent_version_expiration", {})]

        content {
          days = lookup(noncurrent_version_expiration.value, "days", null)
        }
      }

      # Several blocks - noncurrent_version_transition
      dynamic "noncurrent_version_transition" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_transition", [])

        content {
          days          = lookup(noncurrent_version_transition.value, "days", null)
          storage_class = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }

  # Who pays for access to this bucket?
  request_payer = var.s3_who_pays
}

resource "aws_s3_bucket_policy" "replica_policy" {
  /* If s3_bucket_replicate is set to true, AND s3_bucket_policy_enabled is set
     to true, we will set the policy on this bucket, because we are creating a
     primary bucket. (It's replicated.)  If either variable is set to false,
     we are not creating a replicated bucket with a policy on it.
  */
  count    = var.s3_bucket_replicate && var.s3_bucket_policy_enabled ? 1 : 0
  bucket   = aws_s3_bucket.replica[0].id
  provider = aws.replica
  policy   = var.s3_bucket_replica_policy
}

resource "aws_s3_bucket_public_access_block" "replica_block" {
  count    = var.s3_bucket_replicate ? 1 : 0
  bucket   = aws_s3_bucket.replica[0].id
  provider = aws.replica

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
