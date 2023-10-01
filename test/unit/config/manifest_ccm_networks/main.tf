variable "kubeconfig" {
default = <<-EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: Y2VydGlmaWNhdGUtYXV0aG9yaXR5LWRhdGEtdGVzdAo=
    server: https://128.140.25.64:6443
  name: qa
contexts:
- context:
    cluster: qa
    user: qa
  name: qa
current-context: qa
kind: Config
preferences: {}
users:
- name: qa
  user:
    client-certificate-data: Y2xpZW50LWNlcnRpZmljYXRlLWRhdGEtdGVzdAo=
    client-key-data: Y2xpZW50LWtleS1kYXRhLXRlc3QK
EOT
}

locals {
   kubectl = "echo"
}
