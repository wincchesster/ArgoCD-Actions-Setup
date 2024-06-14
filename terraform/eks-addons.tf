module "oidc-provider-data" {
  source     = "reegnz/oidc-provider-data/aws"
  version    = "0.0.3"
  issuer_url = module.eks.identity.0.oidc.0.issuer
}


# module "eks-external-dns" {
#   source                           = "lablabs/eks-external-dns/aws"
#   version                          = "1.2.0"
#   cluster_identity_oidc_issuer     = module.eks.identity.0.oidc.0.issuer
#   cluster_identity_oidc_issuer_arn = module.oidc-provider-data.arn
# }

