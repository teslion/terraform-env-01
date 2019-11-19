# Create subnets in each availability zone to launch our instances into, each with address blocks within the VPC.
resource "aws_subnet" "webserver-subnets" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags {
    Name = "public-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# Create a key pair that will be assigned to our instances.
# This key is actually public key of TerraformTestUser.
resource "aws_key_pair" "deployer" {
  key_name   = "terraform_deployer"
  public_key = "${var.public_key_value}"
}

# Create a new EC2 launch configuration to be used with the autoscaling group.
resource "aws_launch_configuration" "launch_config" {
  name_prefix                 = "terraform-test-web-instance"
  image_id                    = "${var.ami_os}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.deployer.id}"
  security_groups             = ["${aws_security_group.terraform-sg-webserver.id}"]
  associate_public_ip_address = true
  user_data                   = "${file("provision-webservers.sh")}"

  lifecycle {
    create_before_destroy = true
  }
}

# Create the autoscaling group.
resource "aws_autoscaling_group" "autoscaling_group" {
  launch_configuration = "${aws_launch_configuration.launch_config.id}"
  min_size             = "${var.autoscaling_group_min_size}"
  max_size             = "${var.autoscaling_group_max_size}"
  target_group_arns    = ["${aws_alb_target_group.group.arn}"]
  vpc_zone_identifier  = ["${aws_subnet.webserver-subnets.*.id}"]

  tag {
    key                 = "Name"
    value               = "terraform-test-autoscaling-group"
    propagate_at_launch = true
  }
}
