# Refactoring S2 : les ressources du starter passent dans le module ec2-server
moved {
  from = aws_instance.web
  to   = module.web.aws_instance.this
}

moved {
  from = aws_security_group.web
  to   = module.web.aws_security_group.this
}
