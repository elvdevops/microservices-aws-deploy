resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "tasks" {
  for_each = { for s in var.service_definitions : s.name => s }

  family                   = each.key
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = each.key
      image = each.value.image_url
      portMappings = [{ containerPort = each.value.container_port }]
    }
  ])
}

resource "aws_ecs_service" "services" {
  for_each = aws_ecs_task_definition.tasks

  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = each.value.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg[each.key].arn
    container_name   = each.key
    container_port   = var.service_definitions[*][0].container_port
  }
}

resource "aws_lb_target_group" "tg" {
  for_each = aws_ecs_task_definition.tasks

  name     = "tg-${each.key}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener_rule" "rules" {
  for_each = aws_lb_target_group.tg

  listener_arn = var.alb_listener_arn
  priority     = 100 + index(keys(aws_lb_target_group.tg), each.key)

  action {
    type             = "forward"
    target_group_arn = each.value.arn
  }

  condition {
    path_pattern {
      values = ["/${each.key}*"]
    }
  }
}
