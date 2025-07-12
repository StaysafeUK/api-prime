data "external" "git-user-secret-exists" {
  program = ["bash", "-c", "gcloud secrets describe git-user --project=${var.cloud_project} >/dev/null 2>&1 && echo '{\"exists\": \"true\"}' || echo '{\"exists\": \"false\"}'"]
}

resource "google_secret_manager_secret" "git-user-secret" {
  count     = data.external.git-user-secret-exists.result.exists == "true" ? 0 : 1
  project   = var.cloud_project
  secret_id = "git-user"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "git-user-secret-version" {
  count       = data.external.git-user-secret-exists.result.exists == "true" ? 0 : 1
  secret      = one(google_secret_manager_secret.git-user-secret[*].id)
  secret_data = var.git_user
}

data "external" "git-pat-secret-exists" {
  program = ["bash", "-c", "gcloud secrets describe git-pat --project=${var.cloud_project} >/dev/null 2>&1 && echo '{\"exists\": \"true\"}' || echo '{\"exists\": \"false\"}'"]
}

resource "google_secret_manager_secret" "git-pat-secret" {
  count     = data.external.git-pat-secret-exists.result.exists == "true" ? 0 : 1
  project   = var.cloud_project
  secret_id = "git-pat"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "git-pat-secret-version" {
  count       = data.external.git-pat-secret-exists.result.exists == "true" ? 0 : 1
  secret      = one(google_secret_manager_secret.git-pat-secret[*].id)
  secret_data = var.git_pat
}

data "external" "allowed-hosts-ips-secret-exists" {
  program = ["bash", "-c", "gcloud secrets describe allowed-hosts-ips --project=${var.cloud_project} >/dev/null 2>&1 && echo '{\"exists\": \"true\"}' || echo '{\"exists\": \"false\"}'"]
}

resource "google_secret_manager_secret" "allowed-hosts-ips-secret" {
  count     = data.external.allowed-hosts-ips-secret-exists.result.exists == "true" ? 0 : 1
  project   = var.cloud_project
  secret_id = "allowed-hosts-ips"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "allowed-hosts-ips-secret-version" {
  count       = data.external.allowed-hosts-ips-secret-exists.result.exists == "true" ? 0 : 1
  secret      = one(google_secret_manager_secret.allowed-hosts-ips-secret[*].id)
  secret_data = "[]"
}