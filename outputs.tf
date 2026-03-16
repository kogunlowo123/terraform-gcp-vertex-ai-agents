output "agent_id" {
  description = "The unique identifier of the Dialogflow CX agent."
  value       = google_dialogflow_cx_agent.agent.id
}

output "agent_name" {
  description = "The resource name of the Dialogflow CX agent."
  value       = google_dialogflow_cx_agent.agent.name
}

output "agent_start_flow" {
  description = "The start flow ID of the agent."
  value       = google_dialogflow_cx_agent.agent.start_flow
}

output "flow_ids" {
  description = "Map of flow display names to their IDs."
  value       = { for k, v in google_dialogflow_cx_flow.flows : k => v.id }
}

output "intent_ids" {
  description = "Map of intent display names to their IDs."
  value       = { for k, v in google_dialogflow_cx_intent.intents : k => v.id }
}

output "webhook_ids" {
  description = "List of webhook IDs."
  value       = [for w in google_dialogflow_cx_webhook.webhook : w.id]
}

output "cloud_run_service_url" {
  description = "URL of the Cloud Run webhook backend service."
  value       = var.webhook_url == null && var.enable_vertex_ai_features ? google_cloud_run_v2_service.webhook_backend[0].uri : null
}

output "storage_bucket_id" {
  description = "The ID of the GCS bucket for agent data."
  value       = var.storage_bucket_name != null ? google_storage_bucket.agent_data[0].id : null
}
