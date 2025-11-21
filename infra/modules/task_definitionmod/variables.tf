variable "blog_image_uri" {
  description = "image repo uri"
  type        = string

}



variable "network_mode" {
  description = "network mode to use"
  type        = string
  default     = "bridge"

}

variable "task_role_arn" {
  description = "task role to use for task execution"
  type        = string


}


variable "execution_role_arn" {
  description = "task execution role"
  type        = string


}

variable "cpu" {
  description = "cpu limit instance level"
  type        = string


}

variable "memory" {
  description = "memry limit instance level"
  type        = string


}

variable "secrets" {
  description = "secrets to pass"
  type = list(object({
    name      = string
    valueFrom = string
  }))
}



