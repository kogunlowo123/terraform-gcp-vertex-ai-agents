###############################################################################
# Complete Vertex AI Agents Example
#
# This example deploys a fully-featured Dialogflow CX agent with:
# - Multiple conversation flows and pages
# - Custom intents with training phrases
# - Vertex AI Feature Store integration
# - Cloud Run webhook backend
# - GCS bucket for agent data and training artifacts
###############################################################################

module "vertex_ai_agent" {
  source = "../../"

  project_id         = var.project_id
  region             = var.region
  agent_display_name = "customer-support-agent"
  description        = "Customer support conversational AI agent powered by Vertex AI"

  default_language_code   = "en"
  time_zone               = "America/New_York"
  enable_spell_correction = true
  enable_speech_adaptation = true
  supported_languages     = ["es", "fr", "de"]

  # ── Flows ──────────────────────────────────────────────────────────────────
  flows = [
    {
      display_name             = "Main Flow"
      description              = "Primary customer support conversation flow"
      classification_threshold = 0.3
      transition_routes = [
        {
          condition        = "true"
          fulfillment_text = "Hello! Welcome to customer support. How can I assist you today?"
        }
      ]
      event_handlers = [
        {
          event   = "sys.no-match-default"
          message = "I'm sorry, I didn't understand that. Could you please rephrase your question?"
        },
        {
          event   = "sys.no-input-default"
          message = "I didn't catch that. Could you please repeat?"
        }
      ]
      pages = [
        {
          display_name  = "Collect Customer Info"
          entry_message = "I'd be happy to help. Let me start by getting some information."
          parameters = [
            {
              display_name = "customer-name"
              entity_type  = "projects/-/locations/-/agents/-/entityTypes/sys.any"
              required     = true
              prompt       = "What is your name?"
            },
            {
              display_name = "order-number"
              entity_type  = "projects/-/locations/-/agents/-/entityTypes/sys.any"
              required     = true
              prompt       = "Could you provide your order number?"
            }
          ]
        },
        {
          display_name  = "Issue Resolution"
          entry_message = "Thank you. Let me look into your issue now."
          parameters    = []
        }
      ]
    },
    {
      display_name             = "Billing Flow"
      description              = "Handles billing-related inquiries"
      classification_threshold = 0.4
      transition_routes = [
        {
          condition        = "true"
          fulfillment_text = "I can help you with billing questions."
        }
      ]
      event_handlers = []
      pages = [
        {
          display_name  = "Payment Info"
          entry_message = "Let me pull up your billing information."
          parameters = [
            {
              display_name = "account-id"
              entity_type  = "projects/-/locations/-/agents/-/entityTypes/sys.any"
              required     = true
              prompt       = "What is your account ID?"
            }
          ]
        }
      ]
    }
  ]

  # ── Intents ────────────────────────────────────────────────────────────────
  intents = [
    {
      display_name = "greeting"
      description  = "Recognizes user greetings"
      training_phrases = [
        "hello",
        "hi",
        "hey there",
        "good morning",
        "good afternoon",
        "howdy",
        "hi there"
      ]
    },
    {
      display_name = "farewell"
      description  = "Recognizes user farewells"
      training_phrases = [
        "bye",
        "goodbye",
        "see you later",
        "thanks bye",
        "that's all",
        "have a good day"
      ]
    },
    {
      display_name = "order-status"
      description  = "User wants to check order status"
      training_phrases = [
        "where is my order",
        "check order status",
        "track my package",
        "when will my order arrive",
        "order tracking",
        "I want to know about my order"
      ]
    },
    {
      display_name = "billing-inquiry"
      description  = "User has billing or payment questions"
      training_phrases = [
        "I have a billing question",
        "charge on my account",
        "payment issue",
        "refund request",
        "invoice question",
        "I was charged incorrectly"
      ]
    }
  ]

  # ── Vertex AI Features ────────────────────────────────────────────────────
  enable_vertex_ai_features = true

  # ── Storage ────────────────────────────────────────────────────────────────
  storage_bucket_name = "${var.project_id}-agent-data"

  # ── Tags ───────────────────────────────────────────────────────────────────
  tags = {
    environment = "production"
    team        = "conversational-ai"
    managed_by  = "terraform"
  }
}
