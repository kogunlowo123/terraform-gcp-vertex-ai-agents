resource "google_project_service" "dialogflow" {
  project = var.project_id
  service = "dialogflow.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "vertex_ai" {
  project = var.project_id
  service = "aiplatform.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "cloud_run" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_service_account" "agent_sa" {
  project      = var.project_id
  account_id   = "${var.agent_display_name}-agent-sa"
  display_name = "Vertex AI Agent Service Account"
  description  = "Service account for Dialogflow CX agent and webhook backends"
}

resource "google_project_iam_member" "agent_dialogflow" {
  project = var.project_id
  role    = "roles/dialogflow.admin"
  member  = "serviceAccount:${google_service_account.agent_sa.email}"
}

resource "google_project_iam_member" "agent_vertex_ai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.agent_sa.email}"
}

resource "google_project_iam_member" "agent_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.agent_sa.email}"
}

resource "google_project_iam_member" "agent_cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.agent_sa.email}"
}

resource "google_dialogflow_cx_agent" "agent" {
  display_name          = var.agent_display_name
  location              = var.region
  default_language_code = var.default_language_code
  time_zone             = var.time_zone
  description           = var.description
  project               = var.project_id

  supported_language_codes = var.supported_languages

  enable_spell_correction = var.enable_spell_correction

  speech_to_text_settings {
    enable_speech_adaptation = var.enable_speech_adaptation
  }

  advanced_settings {
    audio_export_gcs_destination {
      uri = var.storage_bucket_name != null ? "gs://${google_storage_bucket.agent_data[0].name}/audio-exports/" : null
    }
  }

  depends_on = [google_project_service.dialogflow]
}

resource "google_dialogflow_cx_flow" "flows" {
  for_each = { for flow in var.flows : flow.display_name => flow }

  parent       = google_dialogflow_cx_agent.agent.id
  display_name = each.value.display_name
  description  = each.value.description

  nlu_settings {
    classification_threshold = lookup(each.value, "classification_threshold", 0.3)
    model_type               = "MODEL_TYPE_ADVANCED"
  }

  dynamic "transition_routes" {
    for_each = lookup(each.value, "transition_routes", [])
    content {
      condition = transition_routes.value.condition
      trigger_fulfillment {
        messages {
          text {
            text = [transition_routes.value.fulfillment_text]
          }
        }
      }
    }
  }

  dynamic "event_handlers" {
    for_each = lookup(each.value, "event_handlers", [])
    content {
      event = event_handlers.value.event
      trigger_fulfillment {
        messages {
          text {
            text = [event_handlers.value.message]
          }
        }
      }
    }
  }
}

resource "google_dialogflow_cx_page" "pages" {
  for_each = {
    for page in flatten([
      for flow in var.flows : [
        for page in lookup(flow, "pages", []) : merge(page, {
          flow_name = flow.display_name
        })
      ]
    ]) : "${page.flow_name}-${page.display_name}" => page
  }

  parent       = google_dialogflow_cx_flow.flows[each.value.flow_name].id
  display_name = each.value.display_name

  entry_fulfillment {
    messages {
      text {
        text = [each.value.entry_message]
      }
    }
  }

  dynamic "form" {
    for_each = length(lookup(each.value, "parameters", [])) > 0 ? [1] : []
    content {
      dynamic "parameters" {
        for_each = each.value.parameters
        content {
          display_name = parameters.value.display_name
          entity_type  = parameters.value.entity_type
          required     = lookup(parameters.value, "required", true)

          fill_behavior {
            initial_prompt_fulfillment {
              messages {
                text {
                  text = [parameters.value.prompt]
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "google_dialogflow_cx_intent" "intents" {
  for_each = { for intent in var.intents : intent.display_name => intent }

  parent       = google_dialogflow_cx_agent.agent.id
  display_name = each.value.display_name
  description  = each.value.description

  dynamic "training_phrases" {
    for_each = each.value.training_phrases
    content {
      parts {
        text = training_phrases.value
      }
      repeat_count = 1
    }
  }

  dynamic "parameters" {
    for_each = lookup(each.value, "parameters", [])
    content {
      id          = parameters.value.id
      entity_type = parameters.value.entity_type
    }
  }
}

resource "google_dialogflow_cx_entity_type" "entity_types" {
  for_each = {
    for entity in flatten([
      for intent in var.intents : [
        for entity in lookup(intent, "entity_types", []) : entity
      ]
    ]) : entity.display_name => entity
  }

  parent       = google_dialogflow_cx_agent.agent.id
  display_name = each.value.display_name
  kind         = each.value.kind

  dynamic "entities" {
    for_each = each.value.entities
    content {
      value    = entities.value.value
      synonyms = entities.value.synonyms
    }
  }
}

resource "google_dialogflow_cx_webhook" "webhook" {
  count = var.webhook_url != null ? 1 : 0

  parent       = google_dialogflow_cx_agent.agent.id
  display_name = "${var.agent_display_name}-webhook"

  generic_web_service {
    uri = var.webhook_url
  }

  timeout = "30s"
}

resource "google_cloud_run_v2_service" "webhook_backend" {
  count = var.webhook_url == null && var.enable_vertex_ai_features ? 1 : 0

  name     = "${var.agent_display_name}-webhook-backend"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.agent_sa.email

    containers {
      image = "gcr.io/${var.project_id}/${var.agent_display_name}-webhook:latest"

      ports {
        container_port = 8080
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "REGION"
        value = var.region
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [google_project_service.cloud_run]
}

resource "google_cloud_run_v2_service_iam_member" "webhook_invoker" {
  count = var.webhook_url == null && var.enable_vertex_ai_features ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.webhook_backend[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.agent_sa.email}"
}

resource "google_vertex_ai_feature_store" "agent_memory" {
  count = var.enable_vertex_ai_features ? 1 : 0

  name    = replace("${var.agent_display_name}_memory", "-", "_")
  project = var.project_id
  region  = var.region

  online_serving_config {
    fixed_node_count = 1
  }

  force_destroy = true

  labels = var.labels

  depends_on = [google_project_service.vertex_ai]
}

resource "google_storage_bucket" "agent_data" {
  count = var.storage_bucket_name != null ? 1 : 0

  name          = var.storage_bucket_name
  project       = var.project_id
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  labels = var.labels

  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket_iam_member" "agent_data_access" {
  count = var.storage_bucket_name != null ? 1 : 0

  bucket = google_storage_bucket.agent_data[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.agent_sa.email}"
}
