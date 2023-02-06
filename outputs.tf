## Solo bucket outputs
output "aws_s3_bucket_solo_arn" {
  value = length(aws_s3_bucket.solo) > 0 ? aws_s3_bucket.solo[0].arn : ""
}

output "aws_s3_bucket_solo_id" {
  value = length(aws_s3_bucket.solo) > 0 ? aws_s3_bucket.solo[0].id : ""
}

## Primary bucket outputs
output "aws_s3_bucket_primary_arn" {
  value = length(aws_s3_bucket.primary) > 0 ? aws_s3_bucket.primary[0].arn : ""
}

output "aws_s3_bucket_primary_id" {
  value = length(aws_s3_bucket.primary) > 0 ? aws_s3_bucket.primary[0].id : ""
}

## Replica bucket ouptuts
output "aws_s3_bucket_replica_arn" {
  value = length(aws_s3_bucket.replica) > 0 ? aws_s3_bucket.replica[0].arn : ""
}

output "aws_s3_bucket_replica_id" {
  value = length(aws_s3_bucket.replica) > 0 ? aws_s3_bucket.replica[0].id : ""
}

## Legacy replica bucket outputs
output "aws_s3_bucket_legacy_replica_arn" {
  value = length(aws_s3_bucket.legacy_replica) > 0 ? aws_s3_bucket.legacy_replica[0].arn : ""
}

output "aws_s3_bucket_legacy_replica_id" {
  value = length(aws_s3_bucket.legacy_replica) > 0 ? aws_s3_bucket.legacy_replica[0].id : ""
}
