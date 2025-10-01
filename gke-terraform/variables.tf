variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "Region to deploy the cluster"
  type        = string
  default     = "us-east1"
}
