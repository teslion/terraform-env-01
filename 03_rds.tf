# Create a data source for the availability zones.
data "aws_availability_zones" "available" {}

# Create subnets in each availability zone for RDS, each with address blocks within the VPC.
resource "aws_subnet" "rds" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.${length(data.aws_availability_zones.available.names) + count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags {
    Name = "rds-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# Create a subnet group with all of our RDS subnets. The group will be applied to the database instance.
resource "aws_db_subnet_group" "default" {
  name        = "${var.rds_instance_identifier}-subnet-group"
  description = "Generated by Terraform -  RDS subnet group"
  subnet_ids  = ["${aws_subnet.rds.*.id}"]
}

# Create a RDS security group in the VPC which our database will belong to.
resource "aws_security_group" "rds" {
  name        = "terraform_rds_security_group"
  description = "Generated by Terraform -  RDS MariaDB database"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"

  # Keep the instance private by only allowing traffic from the web server.
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.terraform-sg-webserver.id}"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "terraform-test-rds-database-security-group"
  }
}

# Create a RDS MariaDB database instance in the VPC with our RDS subnet group and security group.
resource "aws_db_instance" "default" {
  identifier                = "${var.rds_instance_identifier}"
  allocated_storage         = 5
  engine                    = "mariadb"
  engine_version            = "10.3.8"
  instance_class            = "db.t2.micro"
  name                      = "${var.database_name}"
  username                  = "${var.database_user}"
  password                  = "${var.database_password}"
  db_subnet_group_name      = "${aws_db_subnet_group.default.id}"
  vpc_security_group_ids    = ["${aws_security_group.rds.id}"]
  skip_final_snapshot       = true
  final_snapshot_identifier = "Ignore"
}

# Manage the MariaDB configuration by creating a parameter group.
resource "aws_db_parameter_group" "default" {
  name        = "${var.rds_instance_identifier}-param-group"
  description = "Generated by Terraform - parameter group for MariaDB 10.3.8"
  family      = "mariadb10.3"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}
