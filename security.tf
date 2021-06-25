# Security Group
module "instance_sg" {
  source      = "github.com/flamarion/terraform-aws-sg?ref=v0.0.5"
  name        = "${var.owner}-consul-sg"
  description = "Consul instances Security Group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  sg_tags = {
    Name = "${var.owner}-consul-instance-sg",
  }

  sg_rules_cidr = {
    temp_rule = {
      description       = "SSH"
      type              = "ingress"
      cidr_blocks       = ["0.0.0.0/0"]
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      security_group_id = module.instance_sg.sg_id
    },
    # consul_peers = {
    #   description       = "All between networks"
    #   type              = "ingress"
    #   cidr_blocks       = data.terraform_remote_state.vpc.outputs.public_subnets
    #   from_port         = 0
    #   to_port           = 0
    #   protocol          = "-1"
    #   security_group_id = module.instance_sg.sg_id
    # },
    outbound = {
      description       = "Allow all outbound"
      type              = "egress"
      cidr_blocks       = ["0.0.0.0/0"]
      to_port           = 0
      protocol          = "-1"
      from_port         = 0
      security_group_id = module.instance_sg.sg_id
    }
  }
}