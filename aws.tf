provider "aws" {}

provider "aws" {
  alias   = "primary"
}

provider "aws" {
  alias   = "replica"
}
