region   = "us-east-1"
project  = "t5"
env      = "test"
vpc_cidr = "10.0.0.0/16"

tags = {
  ManagedBy   = "terraform"
  Environment = "test"
  Project     = "t5"
}

db_username = "postgresadmin"
db_password = "supersecurepassword123"

all_domains = {
  "existingdomain.com" = "Z1234567890"
  "lingua1.com"        = "Z0987654321"
}
