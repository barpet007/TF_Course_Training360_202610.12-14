variable "string_length" {
  description = "The length of the random string to be generated."
  type        = number
  default     = 15
}

variable "prefix" {
  description = "The prefix to be prepended to the string."
  type        = string
  default     = "demo"
}