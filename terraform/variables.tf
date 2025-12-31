variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "eventpipeline"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "raw_data_bucket_name" {
  description = "Raw data bucket name"
  type        = string
  default     = "sanved-eventpipeline-dev-raw-data"
}

variable "reports_bucket_name" {
  description = "Reports bucket name"
  type        = string
  default     = "sanved-eventpipeline-dev-reports"
}
