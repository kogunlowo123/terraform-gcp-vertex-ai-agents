output "agent_id" {
  description = "The unique identifier of the Dialogflow CX agent"
  value       = module.vertex_ai_agent.agent_id
}

output "agent_name" {
  description = "The resource name of the Dialogflow CX agent"
  value       = module.vertex_ai_agent.agent_name
}

output "flow_ids" {
  description = "Map of flow display names to their IDs"
  value       = module.vertex_ai_agent.flow_ids
}

output "intent_ids" {
  description = "Map of intent display names to their IDs"
  value       = module.vertex_ai_agent.intent_ids
}

output "cloud_run_service_url" {
  description = "URL of the Cloud Run webhook backend service"
  value       = module.vertex_ai_agent.cloud_run_service_url
}

output "storage_bucket_id" {
  description = "The ID of the GCS bucket for agent data"
  value       = module.vertex_ai_agent.storage_bucket_id
}
