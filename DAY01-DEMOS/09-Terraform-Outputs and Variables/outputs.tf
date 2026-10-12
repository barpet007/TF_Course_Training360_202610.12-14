output "random_string_result" {
  description = "The result of the random_string.main resource."
  value       = random_string.main.result
}

output "formatted_string" {
  description = "The formatted string provided with a prefix."
  value       = local.formatted_string
}