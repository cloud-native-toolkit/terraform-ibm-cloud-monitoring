output "sync" {
  value = "sysdig"
  depends_on = [helm_release.sysdig]
}
