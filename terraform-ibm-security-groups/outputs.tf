output "this_security_group_id" {
  description = "The ID of the security group"
  value       = var.security_group_computed ? var.security_group : element(concat(ibm_is_security_group.this.*.id, [""]), 0)
}

/*--------------------------------------------------------------------------------
//output "this_security_group_owner_id" {
//  description = "The owner ID"
//  value       = "${element(concat(coalescelist(ibm_is_security_group.this.*.owner_id, ibm_is_security_group.this_name_prefix.*.owner_id), list("")), 0)}"
//}

output "this_security_group_name" {
  description = "The name of the security group"
  value       = "${element(concat(coalescelist(ibm_is_security_group.this.*.name, ibm_is_security_group.this_name_prefix.*.name), list("")), 0)}"
}

//output "this_security_group_description" {
//  description = "The description of the security group"
//  value       = "${element(concat(coalescelist(ibm_is_security_group.this.*.description, ibm_is_security_group.this_name_prefix.*.description), list("")), 0)}"
//}

//output "this_security_group_ingress" {
//  description = "The ingress rules"
//  value       = "${element(concat(ibm_is_security_group.this.*.ingress, list("")), 0)}"
//}


//output "this_security_group_egress" {
//  description = "The egress rules"
//    value       = "${element(concat(ibm_is_security_group.this.*.egress, list("")), 0)"
//}

-------------------------------------------------------------------------------- */
