locals {
  # either the security_group is provided, like the default sg for a vpc can be provided, or it is created
  this_sg_id = var.security_group_computed ? var.security_group : element(concat(ibm_is_security_group.this.*.id, [""]), 0)
}

##########################
# Security group with name
##########################
resource "ibm_is_security_group" "this" {
  count = var.create ? var.security_group_computed ? 0 : 1 : 0
  name  = var.name
  vpc   = var.vpc_id
}

###################################
# Ingress - list if cidr blocks and list if rules.  The result is the cross product
###################################
# Security group rules with "cidr_block" and it uses list of rules names
resource "ibm_is_security_group_rule" "ingress_tcp_rules" {
  count     = var.create ? length(var.ingress_tcp_rules) * length(var.ingress_cidr_blocks) : 0
  group     = local.this_sg_id
  direction = "inbound"
  remote = element(
    var.ingress_cidr_blocks,
    count.index % length(var.ingress_cidr_blocks),
  )

  tcp {
    port_min = element(
      var.rules[var.ingress_tcp_rules[count.index / length(var.ingress_cidr_blocks)]],
      0,
    )
    port_max = element(
      var.rules[var.ingress_tcp_rules[count.index / length(var.ingress_cidr_blocks)]],
      1,
    )
  }
}

resource "ibm_is_security_group_rule" "ingress_udp_rules" {
  count     = var.create ? length(var.ingress_udp_rules) * length(var.ingress_cidr_blocks) : 0
  group     = local.this_sg_id
  direction = "inbound"
  remote = element(
    var.ingress_cidr_blocks,
    count.index % length(var.ingress_cidr_blocks),
  )

  udp {
    port_min = element(
      var.rules[var.ingress_udp_rules[count.index / length(var.ingress_cidr_blocks)]],
      0,
    )
    port_max = element(
      var.rules[var.ingress_udp_rules[count.index / length(var.ingress_cidr_blocks)]],
      1,
    )
  }
}

resource "ibm_is_security_group_rule" "ingress_icmp_rules" {
  count     = var.create ? length(var.ingress_icmp_rules) * length(var.ingress_cidr_blocks) : 0
  group     = local.this_sg_id
  direction = "inbound"
  remote = element(
    var.ingress_cidr_blocks,
    count.index % length(var.ingress_cidr_blocks),
  )

  icmp {
    type = element(
      var.rules[var.ingress_icmp_rules[count.index / length(var.ingress_cidr_blocks)]],
      0,
    )
    code = element(
      var.rules[var.ingress_icmp_rules[count.index / length(var.ingress_cidr_blocks)]],
      1,
    )
  }
}

resource "ibm_is_security_group_rule" "ingress_all_rules" {
  count     = var.create ? var.ingress_all_rule ? 1 : 0 * length(var.ingress_cidr_blocks) : 0
  group     = local.this_sg_id
  direction = "inbound"
  remote = element(
    var.ingress_cidr_blocks,
    count.index % length(var.ingress_cidr_blocks),
  )
}

##########################
# Ingress - list of specific cidr block and specific rule or from/to values.
#  Use either the from or to values (or type and code for icmp) or
# instead of from/to use a rule to look up the from/to value in the rule map
##########################
resource "ibm_is_security_group_rule" "ingress_tcp_with_cidr_block" {
  count     = var.create ? length(var.ingress_tcp_with_cidr_block) : 0
  group     = local.this_sg_id
  direction = "inbound"
  remote    = var.ingress_tcp_with_cidr_block[count.index]["cidr_block"]
  tcp {
    port_min = lookup(
      var.ingress_tcp_with_cidr_block[count.index],
      "type",
      element(
        var.rules[lookup(var.ingress_tcp_with_cidr_block[count.index], "rule", "_")],
        0,
      ),
    )
    port_max = lookup(
      var.ingress_tcp_with_cidr_block[count.index],
      "code",
      element(
        var.rules[lookup(var.ingress_tcp_with_cidr_block[count.index], "rule", "_")],
        1,
      ),
    )
  }
}

resource "ibm_is_security_group_rule" "ingress_udp_with_cidr_block" {
  count     = var.create ? length(var.ingress_udp_with_cidr_block) : 0
  group     = local.this_sg_id
  direction = "inbound"
  remote    = var.ingress_udp_with_cidr_block[count.index]["cidr_block"]
  udp {
    port_min = lookup(
      var.ingress_udp_with_cidr_block[count.index],
      "type",
      element(
        var.rules[lookup(var.ingress_udp_with_cidr_block[count.index], "rule", "_")],
        0,
      ),
    )
    port_max = lookup(
      var.ingress_udp_with_cidr_block[count.index],
      "code",
      element(
        var.rules[lookup(var.ingress_udp_with_cidr_block[count.index], "rule", "_")],
        1,
      ),
    )
  }
}

resource "ibm_is_security_group_rule" "ingress_icmp_with_cidr_block" {
  count     = var.create ? length(var.ingress_icmp_with_cidr_block) : 0
  group     = local.this_sg_id
  direction = "inbound"
  remote    = var.ingress_icmp_with_cidr_block[count.index]["cidr_block"]
  icmp {
    type = lookup(
      var.ingress_icmp_with_cidr_block[count.index],
      "type",
      element(
        var.rules[lookup(var.ingress_icmp_with_cidr_block[count.index], "rule", "_")],
        0,
      ),
    )
    code = lookup(
      var.ingress_icmp_with_cidr_block[count.index],
      "code",
      element(
        var.rules[lookup(var.ingress_icmp_with_cidr_block[count.index], "rule", "_")],
        1,
      ),
    )
  }
}

###################################
# Egress - list if cidr blocks and list if rules.  The result is the cross product
###################################
# Security group rules with "cidr_block" and it uses list of rules names
resource "ibm_is_security_group_rule" "egress_tcp_rules" {
  count     = var.create ? length(var.egress_tcp_rules) * length(var.egress_cidr_blocks) : 0
  group     = local.this_sg_id
  direction = "outbound"
  remote = element(
    var.egress_cidr_blocks,
    count.index % length(var.egress_cidr_blocks),
  )

  tcp {
    port_min = element(
      var.rules[var.egress_tcp_rules[count.index / length(var.egress_cidr_blocks)]],
      0,
    )
    port_max = element(
      var.rules[var.egress_tcp_rules[count.index / length(var.egress_cidr_blocks)]],
      1,
    )
  }
}

resource "ibm_is_security_group_rule" "egress_udp_rules" {
  count     = var.create ? length(var.egress_udp_rules) * length(var.egress_cidr_blocks) : 0
  group     = local.this_sg_id
  direction = "outbound"
  remote = element(
    var.egress_cidr_blocks,
    count.index % length(var.egress_cidr_blocks),
  )

  udp {
    port_min = element(
      var.rules[var.egress_udp_rules[count.index / length(var.egress_cidr_blocks)]],
      0,
    )
    port_max = element(
      var.rules[var.egress_udp_rules[count.index / length(var.egress_cidr_blocks)]],
      1,
    )
  }
}

resource "ibm_is_security_group_rule" "egress_icmp_rules" {
  count     = var.create ? length(var.egress_icmp_rules) * length(var.egress_cidr_blocks) : 0
  group     = local.this_sg_id
  direction = "outbound"
  remote = element(
    var.egress_cidr_blocks,
    count.index % length(var.egress_cidr_blocks),
  )

  icmp {
    type = element(
      var.rules[var.egress_icmp_rules[count.index / length(var.egress_cidr_blocks)]],
      0,
    )
    code = element(
      var.rules[var.egress_icmp_rules[count.index / length(var.egress_cidr_blocks)]],
      1,
    )
  }
}

resource "ibm_is_security_group_rule" "egress_all_rules" {
  count     = var.create ? var.egress_all_rule ? 1 : 0 * length(var.egress_cidr_blocks) : 0
  group     = local.this_sg_id
  direction = "outbound"
  remote = element(
    var.egress_cidr_blocks,
    count.index % length(var.egress_cidr_blocks),
  )
}

##########################
# Egress - list of specific cidr block and specific rule or from/to values.
#  Use either the from or to values (or type and code for icmp) or
# instead of from/to use a rule to look up the from/to value in the rule map
##########################
resource "ibm_is_security_group_rule" "egress_tcp_with_cidr_block" {
  count     = var.create ? length(var.egress_tcp_with_cidr_block) : 0
  group     = local.this_sg_id
  direction = "outbound"
  remote    = var.egress_tcp_with_cidr_block[count.index]["cidr_block"]
  tcp {
    port_min = lookup(
      var.egress_tcp_with_cidr_block[count.index],
      "type",
      element(
        var.rules[lookup(var.egress_tcp_with_cidr_block[count.index], "rule", "_")],
        0,
      ),
    )
    port_max = lookup(
      var.egress_tcp_with_cidr_block[count.index],
      "code",
      element(
        var.rules[lookup(var.egress_tcp_with_cidr_block[count.index], "rule", "_")],
        1,
      ),
    )
  }
}

resource "ibm_is_security_group_rule" "egress_udp_with_cidr_block" {
  count     = var.create ? length(var.egress_udp_with_cidr_block) : 0
  group     = local.this_sg_id
  direction = "outbound"
  remote    = var.egress_udp_with_cidr_block[count.index]["cidr_block"]
  udp {
    port_min = lookup(
      var.egress_udp_with_cidr_block[count.index],
      "type",
      element(
        var.rules[lookup(var.egress_udp_with_cidr_block[count.index], "rule", "_")],
        0,
      ),
    )
    port_max = lookup(
      var.egress_udp_with_cidr_block[count.index],
      "code",
      element(
        var.rules[lookup(var.egress_udp_with_cidr_block[count.index], "rule", "_")],
        1,
      ),
    )
  }
}

resource "ibm_is_security_group_rule" "egress_icmp_with_cidr_block" {
  count     = var.create ? length(var.egress_icmp_with_cidr_block) : 0
  group     = local.this_sg_id
  direction = "outbound"
  remote    = var.egress_icmp_with_cidr_block[count.index]["cidr_block"]
  icmp {
    type = lookup(
      var.egress_icmp_with_cidr_block[count.index],
      "type",
      element(
        var.rules[lookup(var.egress_icmp_with_cidr_block[count.index], "rule", "_")],
        0,
      ),
    )
    code = lookup(
      var.egress_icmp_with_cidr_block[count.index],
      "code",
      element(
        var.rules[lookup(var.egress_icmp_with_cidr_block[count.index], "rule", "_")],
        1,
      ),
    )
  }
}

/***********************************************************************************

resource "ibm_is_security_group_rule" "computed_ingress_rules" {
  count = "${var.create ? var.number_of_computed_ingress_rules : 0}"

  group = "${local.this_sg_id}"
  direction              = "ingress"

  remote      = "${var.ingress_cidr_blocks}"
#  ipv6_cidr_blocks = ["${var.ingress_ipv6_cidr_blocks}"]
#  prefix_list_ids  = ["${var.ingress_prefix_list_ids}"]
# description      = "${element(var.rules[var.computed_ingress_rules[count.index]], 3)}"

  port_min = "${element(var.rules[var.computed_ingress_rules[count.index]], 0)}"
  port_max   = "${element(var.rules[var.computed_ingress_rules[count.index]], 1)}"
#  protocol  = "${element(var.rules[var.computed_ingress_rules[count.index]], 2)}"
}

##########################
# Ingress - Maps of rules
##########################
# Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "ibm_is_security_group_rule" "ingress_with_source_security_group_id" {
  count = "${var.create ? length(var.ingress_with_source_security_group_id) : 0}"

  group = "${local.this_sg_id}"
  direction              = "ingress"

  source_security_group_id = "${lookup(var.ingress_with_source_security_group_id[count.index], "source_security_group_id")}"
#  ipv6_cidr_blocks         = ["${var.ingress_ipv6_cidr_blocks}"]
#  prefix_list_ids          = ["${var.ingress_prefix_list_ids}"]
# description              = "${lookup(var.ingress_with_source_security_group_id[count.index], "description", "Ingress Rule")}"

  port_min = "${lookup(var.ingress_with_source_security_group_id[count.index], "from_port", element(var.rules[lookup(var.ingress_with_source_security_group_id[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.ingress_with_source_security_group_id[count.index], "to_port", element(var.rules[lookup(var.ingress_with_source_security_group_id[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.ingress_with_source_security_group_id[count.index], "protocol", element(var.rules[lookup(var.ingress_with_source_security_group_id[count.index], "rule", "_")], 2))}"
}

# Computed - Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "ibm_is_security_group_rule" "computed_ingress_with_source_security_group_id" {
  count = "${var.create ? var.number_of_computed_ingress_with_source_security_group_id : 0}"

  group = "${local.this_sg_id}"
  direction              = "ingress"

  source_security_group_id = "${lookup(var.computed_ingress_with_source_security_group_id[count.index], "source_security_group_id")}"
#  ipv6_cidr_blocks         = ["${var.ingress_ipv6_cidr_blocks}"]
#  prefix_list_ids          = ["${var.ingress_prefix_list_ids}"]
# description              = "${lookup(var.computed_ingress_with_source_security_group_id[count.index], "description", "Ingress Rule")}"

  port_min = "${lookup(var.computed_ingress_with_source_security_group_id[count.index], "from_port", element(var.rules[lookup(var.computed_ingress_with_source_security_group_id[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.computed_ingress_with_source_security_group_id[count.index], "to_port", element(var.rules[lookup(var.computed_ingress_with_source_security_group_id[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.computed_ingress_with_source_security_group_id[count.index], "protocol", element(var.rules[lookup(var.computed_ingress_with_source_security_group_id[count.index], "rule", "_")], 2))}"
}

# Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"

# Computed - Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"
resource "ibm_is_security_group_rule" "computed_ingress_with_cidr_blocks" {
  count = "${var.create ? var.number_of_computed_ingress_with_cidr_blocks : 0}"

  group = "${local.this_sg_id}"
  direction              = "ingress"

  remote     = ["${split(",", lookup(var.computed_ingress_with_cidr_blockscount.index], "cidr_blocks", join(",", var.ingress_cidr_blocks)))}"
#  prefix_list_ids = ["${var.ingress_prefix_list_ids}"]
# description     = "${lookup(var.computed_ingress_with_cidr_blocks[count.index], "description", "Ingress Rule")}"

  port_min = "${lookup(var.computed_ingress_with_cidr_blocks[count.index], "from_port", element(var.rules[lookup(var.computed_ingress_with_cidr_blocks[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.computed_ingress_with_cidr_blocks[count.index], "to_port", element(var.rules[lookup(var.computed_ingress_with_cidr_blocks[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.computed_ingress_with_cidr_blocks[count.index], "protocol", element(var.rules[lookup(var.computed_ingress_with_cidr_blocks[count.index], "rule", "_")], 2))}"
}

# Security group rules with "ipv6_cidr_blocks", but without "cidr_blocks", "source_security_group_id" and "self"
resource "ibm_is_security_group_rule" "ingress_with_ipv6_cidr_blocks" {
  count = "${var.create ? length(var.ingress_with_ipv6_cidr_blocks) : 0}"

  group = "${local.this_sg_id}"
  direction              = "ingress"

#  ipv6_cidr_blocks = ["${split(",", lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "ipv6_cidr_blocks", join(",", var.ingress_ipv6_cidr_blocks)))}"]
#  prefix_list_ids  = ["${var.ingress_prefix_list_ids}"]
# description      = "${lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "description", "Ingress Rule")}"

  port_min = "${lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "from_port", element(var.rules[lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "to_port", element(var.rules[lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "protocol", element(var.rules[lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 2))}"
}

# Computed - Security group rules with "ipv6_cidr_blocks", but without "cidr_blocks", "source_security_group_id" and "self"
resource "ibm_is_security_group_rule" "computed_ingress_with_ipv6_cidr_blocks" {
  count = "${var.create ? var.number_of_computed_ingress_with_ipv6_cidr_blocks : 0}"

  group = "${local.this_sg_id}"
  direction              = "ingress"

#  ipv6_cidr_blocks = ["${split(",", lookup(var.computed_ingress_with_ipv6_cidr_blocks[count.index], "ipv6_cidr_blocks", join(",", var.ingress_ipv6_cidr_blocks)))}"]
#  prefix_list_ids  = ["${var.ingress_prefix_list_ids}"]
# description      = "${lookup(var.computed_ingress_with_ipv6_cidr_blocks[count.index], "description", "Ingress Rule")}"

  port_min = "${lookup(var.computed_ingress_with_ipv6_cidr_blocks[count.index], "from_port", element(var.rules[lookup(var.computed_ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.computed_ingress_with_ipv6_cidr_blocks[count.index], "to_port", element(var.rules[lookup(var.computed_ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.computed_ingress_with_ipv6_cidr_blocks[count.index], "protocol", element(var.rules[lookup(var.computed_ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 2))}"
}

# Security group rules with "self", but without "cidr_blocks" and "source_security_group_id"
resource "ibm_is_security_group_rule" "ingress_with_self" {
  count = "${var.create ? length(var.ingress_with_self) : 0}"

  group = "${local.this_sg_id}"
  direction              = "ingress"

  self             = "${lookup(var.ingress_with_self[count.index], "self", true)}"
#  ipv6_cidr_blocks = ["${var.ingress_ipv6_cidr_blocks}"]
#  prefix_list_ids  = ["${var.ingress_prefix_list_ids}"]
# description      = "${lookup(var.ingress_with_self[count.index], "description", "Ingress Rule")}"

  port_min = "${lookup(var.ingress_with_self[count.index], "from_port", element(var.rules[lookup(var.ingress_with_self[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.ingress_with_self[count.index], "to_port", element(var.rules[lookup(var.ingress_with_self[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.ingress_with_self[count.index], "protocol", element(var.rules[lookup(var.ingress_with_self[count.index], "rule", "_")], 2))}"
}

# Computed - Security group rules with "self", but without "cidr_blocks" and "source_security_group_id"
resource "ibm_is_security_group_rule" "computed_ingress_with_self" {
  count = "${var.create ? var.number_of_computed_ingress_with_self : 0}"

  group = "${local.this_sg_id}"
  direction              = "ingress"

  self             = "${lookup(var.computed_ingress_with_self[count.index], "self", true)}"
#  ipv6_cidr_blocks = ["${var.ingress_ipv6_cidr_blocks}"]
#  prefix_list_ids  = ["${var.ingress_prefix_list_ids}"]
# description      = "${lookup(var.computed_ingress_with_self[count.index], "description", "Ingress Rule")}"

  port_min = "${lookup(var.computed_ingress_with_self[count.index], "from_port", element(var.rules[lookup(var.computed_ingress_with_self[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.computed_ingress_with_self[count.index], "to_port", element(var.rules[lookup(var.computed_ingress_with_self[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.computed_ingress_with_self[count.index], "protocol", element(var.rules[lookup(var.computed_ingress_with_self[count.index], "rule", "_")], 2))}"
}

#################
# End of ingress
#################

##################################
# Egress - List of rules (simple)
##################################
# Security group rules with "cidr_blocks" and it uses list of rules names
resource "ibm_is_security_group_rule" "egress_rules" {
  count = "${var.create ? length(var.egress_rules) : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

  remote      = "${var.egress_cidr_blocks}"
#  ipv6_cidr_blocks = ["${var.egress_ipv6_cidr_blocks}"]
#  prefix_list_ids  = ["${var.egress_prefix_list_ids}"]
# description      = "${element(var.rules[var.egress_rules[count.index]], 3)}"

  port_min = "${element(var.rules[var.egress_rules[count.index]], 0)}"
  port_max   = "${element(var.rules[var.egress_rules[count.index]], 1)}"
#  protocol  = "${element(var.rules[var.egress_rules[count.index]], 2)}"
}

# Computed - Security group rules with "cidr_blocks" and it uses list of rules names
resource "ibm_is_security_group_rule" "computed_egress_rules" {
  count = "${var.create ? var.number_of_computed_egress_rules : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

  remote      = "${var.egress_cidr_blocks}"
#  ipv6_cidr_blocks = ["${var.egress_ipv6_cidr_blocks}"]
#  prefix_list_ids  = ["${var.egress_prefix_list_ids}"]
# description      = "${element(var.rules[var.computed_egress_rules[count.index]], 3)}"

  port_min = "${element(var.rules[var.computed_egress_rules[count.index]], 0)}"
  port_max   = "${element(var.rules[var.computed_egress_rules[count.index]], 1)}"
#  protocol  = "${element(var.rules[var.computed_egress_rules[count.index]], 2)}"
}

#########################
# Egress - Maps of rules
#########################
# Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "ibm_is_security_group_rule" "egress_with_source_security_group_id" {
  count = "${var.create ? length(var.egress_with_source_security_group_id) : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

  source_security_group_id = "${lookup(var.egress_with_source_security_group_id[count.index], "source_security_group_id")}"
#  ipv6_cidr_blocks         = ["${var.egress_ipv6_cidr_blocks}"]
#  prefix_list_ids          = ["${var.egress_prefix_list_ids}"]
# description              = "${lookup(var.egress_with_source_security_group_id[count.index], "description", "Egress Rule")}"

  port_min = "${lookup(var.egress_with_source_security_group_id[count.index], "from_port", element(var.rules[lookup(var.egress_with_source_security_group_id[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.egress_with_source_security_group_id[count.index], "to_port", element(var.rules[lookup(var.egress_with_source_security_group_id[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.egress_with_source_security_group_id[count.index], "protocol", element(var.rules[lookup(var.egress_with_source_security_group_id[count.index], "rule", "_")], 2))}"
}

# Computed - Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "ibm_is_security_group_rule" "computed_egress_with_source_security_group_id" {
  count = "${var.create ? var.number_of_computed_egress_with_source_security_group_id : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

  source_security_group_id = "${lookup(var.computed_egress_with_source_security_group_id[count.index], "source_security_group_id")}"
#  ipv6_cidr_blocks         = ["${var.egress_ipv6_cidr_blocks}"]
#  prefix_list_ids          = ["${var.egress_prefix_list_ids}"]
# description              = "${lookup(var.computed_egress_with_source_security_group_id[count.index], "description", "Egress Rule")}"

  port_min = "${lookup(var.computed_egress_with_source_security_group_id[count.index], "from_port", element(var.rules[lookup(var.computed_egress_with_source_security_group_id[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.computed_egress_with_source_security_group_id[count.index], "to_port", element(var.rules[lookup(var.computed_egress_with_source_security_group_id[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.computed_egress_with_source_security_group_id[count.index], "protocol", element(var.rules[lookup(var.computed_egress_with_source_security_group_id[count.index], "rule", "_")], 2))}"
}

# Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"
resource "ibm_is_security_group_rule" "egress_with_cidr_blocks" {
  count = "${var.create ? length(var.egress_with_cidr_blocks) : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

  remote     = ["${split(",", lookup(var.egress_with_cidr_blockscount.index], "cidr_blocks", join(",", var.egress_cidr_blocks)))}"
#  prefix_list_ids = ["${var.egress_prefix_list_ids}"]
# description     = "${lookup(var.egress_with_cidr_blocks[count.index], "description", "Egress Rule")}"

  port_min = "${lookup(var.egress_with_cidr_blocks[count.index], "from_port", element(var.rules[lookup(var.egress_with_cidr_blocks[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.egress_with_cidr_blocks[count.index], "to_port", element(var.rules[lookup(var.egress_with_cidr_blocks[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.egress_with_cidr_blocks[count.index], "protocol", element(var.rules[lookup(var.egress_with_cidr_blocks[count.index], "rule", "_")], 2))}"
}

# Computed - Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"
resource "ibm_is_security_group_rule" "computed_egress_with_cidr_blocks" {
  count = "${var.create ? var.number_of_computed_egress_with_cidr_blocks : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

  remote     = ["${split(",", lookup(var.computed_egress_with_cidr_blockscount.index], "cidr_blocks", join(",", var.egress_cidr_blocks)))}"
#  prefix_list_ids = ["${var.egress_prefix_list_ids}"]
# description     = "${lookup(var.computed_egress_with_cidr_blocks[count.index], "description", "Egress Rule")}"

  port_min = "${lookup(var.computed_egress_with_cidr_blocks[count.index], "from_port", element(var.rules[lookup(var.computed_egress_with_cidr_blocks[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.computed_egress_with_cidr_blocks[count.index], "to_port", element(var.rules[lookup(var.computed_egress_with_cidr_blocks[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.computed_egress_with_cidr_blocks[count.index], "protocol", element(var.rules[lookup(var.computed_egress_with_cidr_blocks[count.index], "rule", "_")], 2))}"
}

# Security group rules with "ipv6_cidr_blocks", but without "cidr_blocks", "source_security_group_id" and "self"
resource "ibm_is_security_group_rule" "egress_with_ipv6_cidr_blocks" {
  count = "${var.create ? length(var.egress_with_ipv6_cidr_blocks) : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

#  ipv6_cidr_blocks = ["${split(",", lookup(var.egress_with_ipv6_cidr_blocks[count.index], "ipv6_cidr_blocks", join(",", var.egress_ipv6_cidr_blocks)))}"]
#  prefix_list_ids  = ["${var.egress_prefix_list_ids}"]
# description      = "${lookup(var.egress_with_ipv6_cidr_blocks[count.index], "description", "Egress Rule")}"

  port_min = "${lookup(var.egress_with_ipv6_cidr_blocks[count.index], "from_port", element(var.rules[lookup(var.egress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.egress_with_ipv6_cidr_blocks[count.index], "to_port", element(var.rules[lookup(var.egress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.egress_with_ipv6_cidr_blocks[count.index], "protocol", element(var.rules[lookup(var.egress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 2))}"
}

# Computed - Security group rules with "ipv6_cidr_blocks", but without "cidr_blocks", "source_security_group_id" and "self"
resource "ibm_is_security_group_rule" "computed_egress_with_ipv6_cidr_blocks" {
  count = "${var.create ? var.number_of_computed_egress_with_ipv6_cidr_blocks : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

#  ipv6_cidr_blocks = ["${split(",", lookup(var.computed_egress_with_ipv6_cidr_blocks[count.index], "ipv6_cidr_blocks", join(",", var.egress_ipv6_cidr_blocks)))}"]
#  prefix_list_ids  = ["${var.egress_prefix_list_ids}"]
# description      = "${lookup(var.computed_egress_with_ipv6_cidr_blocks[count.index], "description", "Egress Rule")}"

  port_min = "${lookup(var.computed_egress_with_ipv6_cidr_blocks[count.index], "from_port", element(var.rules[lookup(var.computed_egress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.computed_egress_with_ipv6_cidr_blocks[count.index], "to_port", element(var.rules[lookup(var.computed_egress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.computed_egress_with_ipv6_cidr_blocks[count.index], "protocol", element(var.rules[lookup(var.computed_egress_with_ipv6_cidr_blocks[count.index], "rule", "_")], 2))}"
}

# Security group rules with "self", but without "cidr_blocks" and "source_security_group_id"
resource "ibm_is_security_group_rule" "egress_with_self" {
  count = "${var.create ? length(var.egress_with_self) : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

  self             = "${lookup(var.egress_with_self[count.index], "self", true)}"
#  ipv6_cidr_blocks = ["${var.egress_ipv6_cidr_blocks}"]
#  prefix_list_ids  = ["${var.egress_prefix_list_ids}"]
# description      = "${lookup(var.egress_with_self[count.index], "description", "Egress Rule")}"

  port_min = "${lookup(var.egress_with_self[count.index], "from_port", element(var.rules[lookup(var.egress_with_self[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.egress_with_self[count.index], "to_port", element(var.rules[lookup(var.egress_with_self[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.egress_with_self[count.index], "protocol", element(var.rules[lookup(var.egress_with_self[count.index], "rule", "_")], 2))}"
}

# Computed - Security group rules with "self", but without "cidr_blocks" and "source_security_group_id"
resource "ibm_is_security_group_rule" "computed_egress_with_self" {
  count = "${var.create ? var.number_of_computed_egress_with_self : 0}"

  group = "${local.this_sg_id}"
  direction              = "egress"

  self             = "${lookup(var.computed_egress_with_self[count.index], "self", true)}"
#  ipv6_cidr_blocks = ["${var.egress_ipv6_cidr_blocks}"]
#  prefix_list_ids  = ["${var.egress_prefix_list_ids}"]
# description      = "${lookup(var.computed_egress_with_self[count.index], "description", "Egress Rule")}"

  port_min = "${lookup(var.computed_egress_with_self[count.index], "from_port", element(var.rules[lookup(var.computed_egress_with_self[count.index], "rule", "_")], 0))}"
  port_max   = "${lookup(var.computed_egress_with_self[count.index], "to_port", element(var.rules[lookup(var.computed_egress_with_self[count.index], "rule", "_")], 1))}"
#  protocol  = "${lookup(var.computed_egress_with_self[count.index], "protocol", element(var.rules[lookup(var.computed_egress_with_self[count.index], "rule", "_")], 2))}"
}

################
# End of egress
################
***********************************************************************************/
