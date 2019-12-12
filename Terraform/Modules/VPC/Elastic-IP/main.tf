/*
    Resources
*/

resource "aws_eip" "eip" {
    vpc             = true
    tags            = var.tags
}
