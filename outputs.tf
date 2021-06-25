output "instances_public_dns" {
  value = flatten(module.consul_instance[*].public_dns)
}

output "private_ips" {
  value = flatten(module.consul_instance[*].private_ip)
}