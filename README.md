# TF_modules_S3
this module helps create s3 bucket 
# terraform modules

This directory contains all terraform configs  in the modules directory.


# module_s3

The s3 module handles the creation and tagging of storage buckets.

## Usage

### A replicated bucket with a policy

```terraform
module "s3-<bucket_name>" {
  source         = "https://github.com/sthalluru/TF_modules_S3?ref=<git commit hash>"
  s3_bucket_name = "<bucket_name>"
  s3_bucket_acl  = "<private|log-delivery-write>"

  s3_bucket_versioning = true
  s3_bucket_replicate  = true

  s3_bucket_policy_enabled = true
  s3_bucket_policy         = data.template_file.s3_<bucket_name>_policy.rendered
  s3_bucket_replica_policy = data.template_file.s3_<bucket_name>-replica_policy.rendered

  s3_bucket_logging              = true
  s3_logging_bucket_name         = "<logging bucket in us-east-1>"
  s3_replica_logging_bucket_name = "<logging bucket in us-west-2>"
  s3_logging_prefix              = "<bucket_name>/"

  s3_lifecycle_enabled           = true
  s3_lifecycle_expire            = "<days>"
  s3_lifecycle_noncurrent_expire = "<days>"

  s3_bucket_application = "<Group>: <application>"
  s3_bucket_business    = "<BUSINESS|OIG|etc>"
  s3_bucket_environment = "<prod|val|test|dev|tools|mgmt>"
  s3_bucket_layer       = "<data|apps|tools|mgmt|web|etc>"
  s3_bucket_responsible = "Channel: <slack channel>"
  s3_bucket_stack       = "<data|apps|toosl|mgmt|etc>"
  s3_terraform_source   = "</path/to/bucket.tf>"

  # Requester pays?
  s3_who_pays = "BucketOwner"

  providers = {
    aws         = "aws.primary"
    aws.primary = "aws.primary"
    aws.replica = "aws.replica"
  }
}

data "template_file" "s3_<bucket_name>_policy" {
  template = file("${path.module}/policy/s3_<bucket_name>_policy.json")
}

data "template_file" "s3_<bucket_name>-replica_policy" {
  template = file("${path.module}/policy/s3_<bucket_name>-replica_policy.json")
}
```

And then you put the json of the policy file into the `policy/` directory.

### An unreplicated bucket with no policy

```terraform
module "s3-<bucket_name>" {
  source          = "https://github.com/sthalluru/TF_modules_S3?ref=<git commit hash>"
  s3_bucket_name  = "<bucket_name>"
  s3_bucket_acl   = "<private|log-delivery-write>"

  s3_bucket_versioning = true
  s3_bucket_replicate  = false

  s3_bucket_policy_enabled = false
  s3_bucket_policy         = data.template_file.s3_<bucket_name>_policy.rendered
  s3_bucket_replica_policy = data.template_file.s3_<bucket_name>-replica_policy.rendered

  s3_bucket_logging              = true
  s3_logging_bucket_name         = "<logging bucket in us-east-1>"
  s3_replica_logging_bucket_name = null
  s3_logging_prefix              = "<bucket_name>/"

  s3_bucket_application = "<Group>: <application>"
  s3_bucket_business    = "<Business|OIG|etc>"
  s3_bucket_environment = "<prod|val|test|dev|tools|mgmt>"
  s3_bucket_layer       = "<data|apps|tools|mgmt|web|etc>"
  s3_bucket_responsible = "Channel: <slack channel>"
  s3_bucket_stack       = "<data|apps|toosl|mgmt|etc>"
  s3_terraform_source   = "</path/to/bucket.tf>"

  # Requester pays?
  s3_who_pays = "BucketOwner"

  providers = {
    aws         = "aws.primary"
    aws.primary = "aws.primary"
    aws.replica = "aws.replica"
  }
}
```

### A legacy replica bucket

```terraform
module "s3-bwq-data-val-us-west-2" {
  source         = "https://github.com/sthalluru/TF_modules_S3?ref=<git commit hash>"
  s3_bucket_name = "<bucket_name>"
  s3_bucket_acl  = "private"

  s3_bucket_versioning = true
  s3_bucket_replicate  = false
  s3_legacy_replica    = true

  # Bucket Policy
  s3_bucket_policy_enabled        = true
  s3_bucket_legacy_replica_policy = data.template_file.s3_<bucket_name>_policy.rendered

  # Logging
  s3_bucket_logging              = true
  s3_logging_bucket_name         = "Business-dw-logs"
  s3_replica_logging_bucket_name = "business-dw-logs-us-west-2"
  s3_logging_prefix              = "s3-server-access-logs/<bucket_name>/"

  # Tags
  s3_bucket_application = "<application>"
  s3_bucket_business    = "<BusinessName>"
  s3_bucket_environment = "<env>"
  s3_bucket_layer       = "<layer>"
  s3_bucket_responsible = "Channel: <channel>"
  s3_bucket_stack       = "<env>"
  s3_terraform_source   = "/configs/terraform/vpc_<env>/s3_<bucket_name>.tf"

  # This is a legacy data bucket; we keep data a long time.
  s3_lifecycle_enabled           = true
  s3_lifecycle_expire            = "3650"
  s3_lifecycle_noncurrent_expire = "30"

  providers = {
    aws         = aws.replica
    aws.primary = aws.replica
    aws.replica = aws.replica
  }
}

# Bucket Policy data
data "template_file" "s3_<bucket_name>_policy" {
  template = file("${path.module}/policy/s3_<bucket_name>_policy.json")
  vars = {
    bucket_name = "<bucket_name>"
  }
}
```

## Variables

### Required

* s3_bucket_name - STRING; name of the bucket, all lowercase, -, or _
* s3_bucket_acl - STRING; defaults to private
* s3_bucket_business - STRING; the primary business using the bucket.
* s3_bucket_environment - STRING; no default. Intended environment for use
  like devops-dev, qssi-test, prod, etc.
* s3_bucket_layer - STRING; the data layer of the bucket.
* s3_bucket_responsible - STRING; no default. Something like gov-infra-sec, qa,
  od-eng, etc.
* s3_bucket_stack - STRING; 'Stack' in which a bucket lives; functionally
  equivalent to s3_bucket_environment, and may become obsolete.
* s3_bucket_logging_bucket_name - STRING; where to log your bucket changes to.
* s3_replica_logging_bucket_name - STRING; where to log your replica changes
  to, or set to 'null' if you have no replica.
* s3_logging_prefix - STRING; what to set the prefix of the bucket logs to on
  the logging bucket. Suggested value is the bucket name.
* s3_terraform_source - STRING; where the config for this bucket is stored in
  github's terraform tree.

NOTE: The providers block will set the region for the bucket - whatever provider is set for the bucket is the region in which that bucket will be created.

### Optional

* s3_bucket_versioning - BOOL; defaults to true and you have to explain to
  Louis why a bucket shouldn't be versioned to set it to false.
* s3_bucket_replicate - BOOL; defaults to false. Whether or not to replicate to
  the replica region.
* s3_legacy_replica - BOOL; defaults to false; only turn on to import a legacy
  replica bucket that needs to be kept for data retention.
* s3_bucket_policy_enabled - BOOL; defaults to false. Whether or not to put a
  policy on the bucket. If you set this one to true, you must supply two JSON
  formatted policies in the policy directory, set the templates, and include
  the two policy stanzas at the bottom of the file.
* s3_bucket_logging - BOOL; defaults to true and you have to explain to Louis
  why a bucket shouldn't be logged if you want to change this.
* s3_lifecycle_enabled - BOOL; defaults to false, turn this on to set data
  retention.
* s3_lifecycle_expire - INT; number of days to keep a file around before
  deleting. Defaults to 3650 (10 years)
* s3_lifecycle_noncurrent_expire - INT; number of days to keep old versions of
  files around; defaults to 3650 (10 years)
* s3_who_pays - String; defaults to "BucketOwner", swap this to "Requester" to
  turn this on if you want requesters to pay for access to this bucket. (This
  is unusual for us, but not unheard of.)
* s3_replication_rules - List; defaults to [] (empty list). Allows us to specify a 
  list of replication rules to be propagated from our primary bucket to its replicas.
  
    Example map attributes:
    ```hcl-terraform
    s3_replication_rules = [
      {
        id       = "foo"
        status   = "Enabled"
        priority = 10
    
        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
    
        filter = {
          prefix = "one"
          tags = {
            ReplicateMe = "Yes"
          }
        }
      }]
    ```

* primary_lifecycle_addition - List; defaults to [] (empty list). Allows us to specify a
  list of lifecycle rules to the primary bucket.
  
  Example map attributes:
  ```hcl-terraform
  primary_lifecycle_addition = [
    {
      id      = "log"
      enabled = true
      prefix  = "log/"

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 30
          storage_class = "ONEZONE_IA"
          }, {
          days          = 60
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 90
      }

      noncurrent_version_expiration = {
        days = 30
      }
    }
  ]
  ```
* replica_lifecycle_addition - List; defaults to [] (empty list). Allows us to specify a
  list of lifecycle rules to the replica bucket.

  See primary_lifecycle_addition for example.
