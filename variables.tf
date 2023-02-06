variable "aws_profile" {
  description = "String: The profile to operate under. e.g. aws-hhs-cms-tms"
  default     = null
}

## AWS S3 Variables
variable "s3_bucket_name" {
  description = "String: The name of the bucket to be managed."
}

variable "s3_bucket_acl" {
  description = "String: What is stored in this bucket."
  default     = "private"
}

variable "s3_bucket_environment" {
  description = "String: Prod/Test/Dev/Tools/Mgmt etc."
}

variable "s3_bucket_responsible" {
  description = "The Contact/group that should be responsible for this bucket."
}

variable "s3_bucket_versioning" {
  description = "Bool: should this bucket be versioned?"
  default     = true
}

variable "s3_legacy_replica" {
  description = "Bool: whether this is one of the legacy replica buckets we're retaining for archival purposes, but which is no longer a replica."
  default     = false
}

variable "s3_bucket_legacy_replica_policy" {
  description = "String: name of the .json file in the policy sub-directory containing the policy for this bucket's replica."
  default     = null
}
variable "s3_bucket_replicate" {
  description = "Bool: should this bucket be replicated?"
  default     = false
}

variable "s3_move_replica_to_standard_ia_after" {
  description = "String: number of days before transitioning a file to Standard_IA storage on the S3 replica bucket."
  default     = "30"
}

variable "s3_lifecycle_enabled" {
  description = "Bool: whether to enable file lifecycle management."
  default     = false
}

variable "s3_lifecycle_expire" {
  description = "String: number of days before expiring/deleting files."
  default     = "3650"
}

variable "s3_lifecycle_noncurrent_expire" {
  description = "String: number of days before deleting noncurrent versions of files."
  default     = "365"
}

variable "s3_bucket_policy_enabled" {
  description = "Bool: should this bucket apply s3_bucket_policy?"
  default     = false
}

variable "s3_bucket_policy" {
  description = "String: name of the .json file in the policy sub-directory containing the policy for this bucket."
  default     = null
}

variable "s3_bucket_replica_policy" {
  description = "String: name of the .json file in the policy sub-directory containing the policy for this bucket's replica."
  default     = null
}

variable "s3_bucket_logging" {
  description = "Bool: Whether to log data changes and accesses on this bucket."
  default     = true
}

variable "s3_logging_bucket_name" {
  description = "The name of the s3 bucket to which to log data changes and accesses on this bucket. (Set to null if you're not logging.)"
}

variable "s3_replica_logging_bucket_name" {
  description = "The name of the s3 bucket to which to log data changes and accesses on this bucket. (Set to null if you're not logging.)"
}

variable "s3_logging_prefix" {
  description = "The prefix to prepend to logs from this bucket."
  default     = null
}

variable "s3_bucket_application" {
  description = "String: Application that uses this bucket."
}

variable "s3_bucket_business" {
  description = "String: Business using this bucket (TMSIS, AREMAC, OIG, etc)"
}

variable "s3_bucket_stack" {
  description = "String: Prod/UAT/Val/Test/Dev/Mgmt/Tools etc... (equivalent to environment"
}

variable "s3_bucket_layer" {
  description = "String: data later for this bucket. (data, mgmt, tools, logs, etc)"
}

variable "s3_terraform" {
  description = "String: Is this bucket terraformed?"
  default     = true
}

variable "s3_terraform_source" {
  description = "String: the source tree in git hub where this bucket is configured for terraform."
}

variable "s3_who_pays" {
  description = "Whether the requester pays for accesses/requests to this bucket. Defaults to BucketOwner, change to Requester to override."
  default     = "BucketOwner"
}

variable "s3_replication_rules" {
  description = "A list of replication rules"
  type        = any
  default     = []
}

variable "primary_lifecycle_addition" {
  description = "Additional primary bucket lifecycle override"
  type        = any
  default     = []
}

variable "replica_lifecycle_addition" {
  description = "Additional replica bucket lifecycle override"
  type        = any
  default     = []
}
