output "bastion_sg_id" {
  value = "${aws_security_group.bastion_sg.id}"
}

output "web_dmz_sg_id" {
  value = "${aws_security_group.web_dmz_sg.id}"
}

output "private_sg_id" {
  value = "${aws_security_group.private_sg.id}"
}
