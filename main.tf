// CREATE EC2  NODE 
module "create_eksclientnode" {
  source        = "./ec2"
  instance_type = var.instance_type
  region        = var.region
}
