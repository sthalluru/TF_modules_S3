/*Primary bucket module*/
resource "aws_s3_bucket" "primary" {
  count = var.s3_bucket_replicate ? 1 : 0

  provider = aws.primary
  bucket   = var.s3_bucket_name
  acl      = var.s3_bucket_acl

  /* If a bucket is not empty, we will not allow terraform to destroy it.
     Period. */
  force_destroy = false

  tags = {
    Name              = var.s3_bucket_name
    TF_Environment    = var.s3_bucket_environment
    TF_Responsible    = var.s3_bucket_responsible
    TF_Replicate      = var.s3_bucket_replicate
    TF_VersionControl = var.s3_bucket_versioning
    application       = var.s3_bucket_application
    business          = var.s3_bucket_business
    layer             = var.s3_bucket_layer
    stack             = var.s3_bucket_stack
    Terraform         = var.s3_terraform
    Terraform_Source  = var.s3_terraform_source
  }

  logging {
    target_bucket = var.s3_logging_bucket_name
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
    enabled = var.s3_bucket_versioning
  }

  replication_configuration {
    role = aws_iam_role.replication[0].arn

    # If no specific/special replication rules provided, use standard full-bucket rule
    dynamic "rules" {
      for_each = var.s3_replication_rules == [] ? ["dummy"] : []
      content {
        id     = "${var.s3_bucket_name}_replication_rule"
        prefix = ""
        status = "Enabled"

        destination {
          bucket        = aws_s3_bucket.replica[0].arn
          storage_class = "STANDARD"
        }
      }
    }

    dynamic "rules" {
      for_each = var.s3_replication_rules

      content {
        id       = "${var.s3_bucket_name}_${lookup(rules.value, "id", "")}_replication_rule"
        priority = lookup(rules.value, "priority", null)
        prefix   = lookup(rules.value, "prefix", null)
        status   = "Enabled"

        destination {
          bucket        = aws_s3_bucket.replica[0].arn
          storage_class = "STANDARD"
        }

        dynamic "source_selection_criteria" {
          for_each = length(keys(lookup(rules.value, "source_selection_criteria", {}))) == 0 ? [] : [lookup(rules.value, "source_selection_criteria", {})]

          content {

            dynamic "sse_kms_encrypted_objects" {
              for_each = length(keys(lookup(source_selection_criteria.value, "sse_kms_encrypted_objects", {}))) == 0 ? [] : [lookup(source_selection_criteria.value, "sse_kms_encrypted_objects", {})]

              content {

                enabled = sse_kms_encrypted_objects.value.enabled
              }
            }
          }
        }

        dynamic "filter" {
          for_each = length(keys(lookup(rules.value, "filter", {}))) == 0 ? [] : [lookup(rules.value, "filter", {})]

          content {
            prefix = lookup(filter.value, "prefix", null)
            tags   = lookup(filter.value, "tags", null)
          }
        }

      }
    }
  }

  # TODO(IN-45) - Enable this by default.
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

    # GLACIER disabled because we can't delete old versions if we have it on.
    # This requires some more thought.
    #    noncurrent_version_transition {
    #      days          = var.s3_lifecycle_glacier_days
    #      storage_class = "GLACIER"
    #    }
  }
  # End TODO(IN-45)

  dynamic "lifecycle_rule" {
    for_each = var.primary_lifecycle_addition

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

resource "aws_s3_bucket_policy" "primary_policy" {
  count    = var.s3_bucket_replicate && var.s3_bucket_policy_enabled ? 1 : 0
  bucket   = aws_s3_bucket.primary[0].id
  provider = aws.primary
  policy   = var.s3_bucket_policy
}

resource "aws_s3_bucket_public_access_block" "primary_block" {
  count    = var.s3_bucket_replicate ? 1 : 0
  bucket   = aws_s3_bucket.primary[0].id
  provider = aws.primary

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
