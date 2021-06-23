resource "aws_acm_certificate" "eks_domain_cert" {
  domain_name       = var.dns_base_domain
  validation_method = "DNS"
  subject_alternative_names = [
    "*.${var.dns_base_domain}",
  ]
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.dns_base_domain}"
    },
  )
}

data "aws_route53_zone" "eks_domain" {
  name         = var.dns_base_domain
  private_zone = false
}

resource "aws_route53_record" "domain" {
  for_each = {
    for dvo in aws_acm_certificate.eks_domain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.eks_domain.zone_id
}

resource "aws_acm_certificate_validation" "eks_domain_cert_validation" {
  certificate_arn         = aws_acm_certificate.eks_domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.domain : record.fqdn]
}

# deploy Kong Gateway Enterprise
resource "kubernetes_namespace" "kong" {
  metadata {
    name = "kong"
    annotations = {
      "kuma.io/sidecar-injection" = "enabled"
    }
  }
}

resource "kubernetes_secret" "kong-enterprise-license" {
  metadata {
    name      = "kong-enterprise-license"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }

  data = {
    license = "${file("${path.module}/gateway/license.json")}"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "kong-enterprise-superuser-password" {
  metadata {
    name      = "kong-enterprise-superuser-password"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }

  data = {
    password = var.kong_superuser_password
  }

  type = "Opaque"
}

resource "helm_release" "kong_gateway" {
  name      = var.kong_gateway_release_name
  chart     = var.kong_gateway_chart_name
  namespace = kubernetes_namespace.kong.metadata[0].name

  values = [
    file("${path.module}/gateway/kong-gateway-values.yaml")
  ]
  set {
    name  = "proxy.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = aws_acm_certificate.eks_domain_cert.arn
  }
  set {
    name  = "proxy.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "kong-proxy-tls"
  }
  set {
    name  = "proxy.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "http"
  }
}

data "kubernetes_service" "kong_gateway" {
  metadata {
    name      = join("-", [helm_release.kong_gateway.name, helm_release.kong_gateway.name, "proxy"])
    namespace = kubernetes_namespace.kong.metadata[0].name
  }
  depends_on = [module.eks-cluster]
}

resource "aws_route53_record" "gateway_proxy" {
  zone_id = data.aws_route53_zone.eks_domain.zone_id
  name    = "kong"
  type    = "CNAME"
  records = [data.kubernetes_service.kong_gateway.status.0.load_balancer.0.ingress.0.hostname]
  ttl     = 60
}

# Install Kong Mesh
resource "kubernetes_namespace" "kong-mesh-system" {
  metadata {
    name = "kong-mesh-system"
    annotations = {
      "kuma.io/sidecar-injection" = "enabled"
    }
  }
}

resource "kubernetes_secret" "kong-mesh-license" {
  metadata {
    name      = "kong-mesh-license"
    namespace = kubernetes_namespace.kong-mesh-system.metadata[0].name
  }

  data = {
    license = "${file("${path.module}/mesh/license.json")}"
  }

  type = "Opaque"
}

resource "helm_release" "kong_mesh" {
  name       = var.kong_mesh_release_name
  repository = var.kong_mesh_chart_repo
  chart      = var.kong_mesh_chart_name
  namespace  = kubernetes_namespace.kong-mesh-system.metadata[0].name
  values = [
      file("${path.module}/mesh/kong-mesh-values.yaml")
    ]
}