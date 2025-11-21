variable "desired_count" {
  default = 2
}
variable "clustername" {

}
variable "task_definition_arn" {

}
variable "deployment_minimum_healthy_percent" {

}
variable "health_check_grace_period_seconds" {

}
variable "capacity_provider_name" {

}
variable "target_group_arn" {

}
variable "container_name" {

}
variable "container_port" {
  type = number

}




variable "scheduling_strategy" {

}

variable "name" {
  type = string
}

variable "ordered_placement_strategy" {
  description = "Placement strategies"
  type = list(object({
    type  = string
    field = string
  }))
  default = []
}
