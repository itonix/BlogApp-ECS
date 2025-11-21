output "my_ecs_name" {
    value = aws_ecs_cluster.my_ecs.name
    #output clustername
  
}

output "my_ecs_id" {
    value = aws_ecs_cluster.my_ecs.id
    #output id
  
}
