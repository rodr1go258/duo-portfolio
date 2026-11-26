output "instance_id" {
  description = "OCID de la instancia OCI"
  value       = oci_core_instance.vm.id
}

output "public_ip" {
  description = "IP pública asignada a la VM"
  value       = oci_core_instance.vm.public_ip
}

output "vcn_id" {
  description = "OCID de la VCN creada"
  value       = oci_core_vcn.main.id
}

output "public_subnet_id" {
  description = "OCID de la subred pública"
  value       = oci_core_subnet.public.id
}

output "private_subnet_id" {
  description = "OCID de la subred privada"
  value       = oci_core_subnet.private.id
}

output "image_id" {
  description = "OCID de la imagen Ubuntu 24.04 utilizada"
  value       = data.oci_core_images.ubuntu_2404.images[0].id
}

output "ssh_command" {
  description = "Comando listo para conectarse por SSH"
  value       = "ssh ubuntu@${oci_core_instance.vm.public_ip}"
}
