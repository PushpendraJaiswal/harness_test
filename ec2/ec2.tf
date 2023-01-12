# ------------------------------------------------------------------------------
# IAM ROLE AND POLICY - // ROLE NEEDED BY EC2 TO PUSH DOCKER IMAGE TO ECR
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ec2master_role" {
  name = "ec2-eks-access"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

// POLICY ALLOWS EKS-CLIENT-NODE WITH ADMIN ACCESS TO EKS CLUSTER
resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2master_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "eksadministrator",
      "Effect":"Allow",
      "Action": ["eks:*"],
      "Resource": "*"
    }
  ]
}
EOF
}

// ATTACH POLICY ImageBuilderECRContainerBuilds TO ABOVE ROLE
resource "aws_iam_role_policy_attachment" "CopyImageToECR" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.ec2master_role.name
}

// ATTACH POLICY AmazonEC2FullAccess TO ABOVE ROLE
resource "aws_iam_role_policy_attachment" "EC2Admin" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.ec2master_role.name
}

// CREATE PROFILE AND ATTACH ABOVE ROLE
resource "aws_iam_instance_profile" "ec2profile" {
  name      = "ec2-instance-profile"
  role      = aws_iam_role.ec2master_role.name
  //role      = "EKSAdmin"
}

# ------------------------------------------------------------------------------
# CREATE EC2 NODE which WILL SERVE AS EKS CLIENT NODE
# ------------------------------------------------------------------------------
resource "aws_instance" "masterNode" {
    //count                   = 2
    //ami                     = var.ami_win
    ami                     = var.ami_linux
    instance_type           = var.instance_type
    iam_instance_profile    = aws_iam_instance_profile.ec2profile.name
    vpc_security_group_ids  = [aws_security_group.main.id]
    //user_data               = "${file("install_iamauthenticator_kubectl_eksctl.sh")}"
    tags = {
      Name = "EKS-CLIENT"
    }
    
    // ENSURE THAT SCRIPT WAITS UNTIL EC2 INSTANCE STATUS-CHECK IS PASSED
    provisioner "local-exec" {
      command = <<-EOF
        aws ec2 wait instance-status-ok --instance-id ${aws_instance.masterNode.id} --region ${var.region}
      EOF
    } 
}

// Add SECURITY GROUP ON EC2 (ENABLE IN/E-GRESS RULES)
resource "aws_security_group" "main" {
 ingress {
    cidr_blocks       = ["0.0.0.0/0"]
    description       = "For TCP traffic"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp" 
  }
  ingress {
    cidr_blocks       = ["0.0.0.0/0"]
    description       = "For SSH"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
  } 
  egress {
    cidr_blocks       = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
  }
}
