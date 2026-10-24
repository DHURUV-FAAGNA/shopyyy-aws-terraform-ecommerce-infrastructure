resource "aws_msk_cluster" "this" {
  cluster_name           = "${var.name}-kafka"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.broker_count

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.private_subnet_ids
    security_groups = [var.security_group_id]

    storage_info {
      ebs_storage_info {
        volume_size = var.broker_volume_size
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = var.client_broker_encryption
      in_cluster    = true
    }
  }

  client_authentication {
    unauthenticated = var.client_broker_encryption == "PLAINTEXT"

    dynamic "sasl" {
      for_each = var.client_broker_encryption == "TLS" ? [1] : []

      content {
        iam = true
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-kafka" })
}
