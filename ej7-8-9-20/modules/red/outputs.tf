output "vpc_id"       { value = aws_vpc.this.id }
output "subnet_ids"   { value = [aws_subnet.public_a.id, aws_subnet.public_b.id] }
output "subnet_a_id"  { value = aws_subnet.public_a.id }
output "sg_id"        { value = aws_security_group.web_sg.id }