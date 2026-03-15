module "test" {
  source = "../"

  project_id         = "test-project-id"
  region             = "us-central1"
  agent_display_name = "test-agent"
  description        = "Test conversational AI agent"

  default_language_code   = "en"
  time_zone               = "America/New_York"
  enable_spell_correction = true
  supported_languages     = ["es", "fr"]

  flows = [
    {
      display_name             = "Main Flow"
      description              = "Primary conversation flow"
      classification_threshold = 0.3
      transition_routes = [
        {
          condition        = "true"
          fulfillment_text = "Welcome! How can I help you today?"
        }
      ]
      event_handlers = [
        {
          event   = "sys.no-match-default"
          message = "I didn't understand that. Could you rephrase?"
        },
        {
          event   = "sys.no-input-default"
          message = "I didn't hear anything. Could you repeat that?"
        }
      ]
      pages = [
        {
          display_name  = "Collect Info"
          entry_message = "Let me gather some information."
          parameters = [
            {
              display_name = "user-name"
              entity_type  = "projects/-/locations/-/agents/-/entityTypes/sys.any"
              required     = true
              prompt       = "What is your name?"
            }
          ]
        }
      ]
    }
  ]

  intents = [
    {
      display_name = "greeting"
      description  = "User greeting intent"
      training_phrases = [
        "hello",
        "hi",
        "hey there",
        "good morning",
      ]
    },
    {
      display_name = "farewell"
      description  = "User farewell intent"
      training_phrases = [
        "bye",
        "goodbye",
        "see you later",
      ]
    }
  ]

  enable_vertex_ai_features = false
  storage_bucket_name       = null

  tags = {
    environment = "test"
    managed_by  = "terraform"
  }
}
