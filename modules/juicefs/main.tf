

resource "kubernetes_manifest" "juicefs" {
  manifest = {
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name      = "juicefs-pvc"
      namespace = "juicefs"
    }
    spec = {
        accessModes = ["ReadWriteMany"]
        resources = {
            requests = {
                storage = "100Gi"
            }
        }
        storageClassName : "juicefs-sc"
    }
  }
}
