# consul-cluster-aws
Terraform code to deploy Consul Cluster in AWS

This code will create a 3 node Consul Cluster using the `retry-join` based on instance metadata to form the cluster.

The code rely on `remote-exec` to pull the Consul binaries, which is not the best scenario but for a lab is ok. You may use `ansible` to do this task.

As this is a lab it also rely on `local-exec` to create the Consul CA and Consul Certificates, however, this is also not the best approach.

## TODO

[ ] Create the Load Balancer.