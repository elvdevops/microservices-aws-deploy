resource "aws_lb" "main" {
  name               = "micro-alb-${var.environment}"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [var.alb_security_group]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}
