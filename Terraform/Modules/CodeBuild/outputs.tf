/*
  Output Values
*/

output "code_build_name" {
  value       = aws_codebuild_project.codebuild_project.name
  description = "CodeBuild - Project Name"
}