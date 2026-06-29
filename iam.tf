resource "google_project_iam_member" "profesor_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "user:vdrestrepot@unal.edu.co"
}

resource "google_project_iam_member" "mario_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "user:mcalleag@unal.edu.co"
}

resource "google_project_iam_member" "mafe_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "user:mcanas@unal.edu.co"
}
