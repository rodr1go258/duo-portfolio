output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.vm.id
}

output "public_ip" {
  description = "IP pública elástica asignada a la VM"
  value       = aws_eip.vm.public_ip
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID de la subred pública"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID de la subred privada"
  value       = aws_subnet.private.id
}

output "ami_id" {
  description = "AMI de Ubuntu 24.04 utilizada"
  value       = data.aws_ami.ubuntu_2404.id
}

output "ssh_command" {
  description = "Comando listo para conectarse por SSH"
  value       = "ssh ubuntu@${aws_eip.vm.public_ip}"
}
