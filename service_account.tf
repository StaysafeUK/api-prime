resource "google_service_account" "api_prime_svc_net" {
  account_id   = "api-prime-svc-net"
  display_name = "API Prime Service Account"
  project      = "archejrenet-dev-03102025"
}

resource "google_project_iam_member" "api_prime_svc_net_compute_instance_admin" {
  project = "archejrenet-dev-03102025"
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.api_prime_svc_net.email}"
}

resource "google_project_iam_member" "api_prime_svc_net_compute_network_admin" {
  project = "archejrenet-dev-03102025"
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.api_prime_svc_net.email}"
}

resource "google_project_iam_member" "api_prime_svc_net_compute_security_admin" {
  project = "archejrenet-dev-03102025"
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.api_prime_svc_net.email}"
}

resource "google_project_iam_member" "api_prime_svc_net_secretmanager_admin" {
  project = "archejrenet-dev-03102025"
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.api_prime_svc_net.email}"
}

resource "google_project_service" "secretmanager_api" {
  project            = "archejrenet-dev-03102025"
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}
