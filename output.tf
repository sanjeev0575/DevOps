output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_cluster.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}
