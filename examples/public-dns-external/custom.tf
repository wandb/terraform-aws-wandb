terraform {
  cloud {
    organization = "weights-and-biases"
    workspaces {
      name = "apple-replica-msk"
    }
  }
}