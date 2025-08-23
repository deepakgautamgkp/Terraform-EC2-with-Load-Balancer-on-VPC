data "aws_availability_zones" "available" {
  state = "available"
}



/*
--------------   VPC --------------------------
*/

resource "aws_vpc" "main-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    name = "${var.project_name}-vpc"
  }
}


/*
------------------ VPC Subnet's -----------------------
*/
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.main-vpc.id
  cidr_block = var.public_subnet_cidr
  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.main-vpc.id
  cidr_block = var.private_subnet_cidr
  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet"
  }
}

/*
---------------   Internet Gateway + Route Table --------------
*/

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project_name}-public-route"
  }
}

resource "aws_route_table_association" "public-asso" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route.id
}

/*
--------------------  Security Group's -------------------------------------
*/

resource "aws_security_group" "web-sg" {
  vpc_id      = aws_vpc.main-vpc.id
  description = "Allow TLS inbound traffic and all outbound traffic"
  dynamic "ingress" {
    for_each = [80,22]
    iterator = port
    content {
      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-SG"
  }
}


/*
---------------------------------- EC2 --------------------------------------------
*/
resource "aws_instance" "web" {
  ami           = var.ami # Amazon Linux 2 AMI (update for your region)
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  availability_zone = data.aws_availability_zones.available.names[0]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from Terraform EC2 $(hostname)</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}


/*
--------------- Load Balancer -------------------------------
*/

resource "aws_lb" "app_lb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.public-subnet.id]
  enable_deletion_protection = true

  tags = {
    Environment = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-vpc.id
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

output "region" {
  value = data.aws_availability_zones.available.names[0]
}
