###############################################################################
# Project & Region
###############################################################################

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resource deployment"
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region (e.g., us-central1, europe-west1)."
  }
}

###############################################################################
# Agent Configuration
###############################################################################

variable "agent_display_name" {
  description = "Display name for the Dialogflow CX agent"
  type        = string

  validation {
    condition     = length(var.agent_display_name) >= 1 && length(var.agent_display_name) <= 64
    error_message = "Agent display name must be between 1 and 64 characters."
  }
}

variable "default_language_code" {
  description = "Default language code for the agent"
  type        = string
  default     = "en"

  validation {
    condition     = can(regex("^[a-z]{2}(-[A-Z]{2})?$", var.default_language_code))
    error_message = "Language code must be a valid BCP-47 language code (e.g., en, en-US, fr)."
  }
}

variable "time_zone" {
  description = "Time zone for the agent"
  type        = string
  default     = "America/New_York"
}

variable "description" {
  description = "Description of the Dialogflow CX agent"
  type        = string
  default     = "Vertex AI-powered conversational agent"
}

variable "enable_speech_adaptation" {
  description = "Enable speech adaptation for improved speech recognition"
  type        = bool
  default     = false
}

variable "enable_spell_correction" {
  description = "Enable spell correction for user inputs"
  type        = bool
  default     = true
}

variable "supported_languages" {
  description = "List of additional supported language codes"
  type        = list(string)
  default     = []
}

###############################################################################
# Flows
###############################################################################

variable "flows" {
  description = "List of conversation flow configurations"
  type = list(object({
    display_name             = string
    description              = string
    classification_threshold = optional(number, 0.3)
    transition_routes = optional(list(object({
      condition        = string
      fulfillment_text = string
    })), [])
    event_handlers = optional(list(object({
      event   = string
      message = string
    })), [])
    pages = optional(list(object({
      display_name  = string
      entry_message = string
      parameters = optional(list(object({
        display_name = string
        entity_type  = string
        required     = optional(bool, true)
        prompt       = string
      })), [])
    })), [])
  }))
  default = [
    {
      display_name = "Main Flow"
      description  = "Primary conversation flow"
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
      pages = []
    }
  ]
}

###############################################################################
# Intents
###############################################################################

variable "intents" {
  description = "List of intent configurations"
  type = list(object({
    display_name     = string
    description      = string
    training_phrases = list(string)
    parameters = optional(list(object({
      id          = string
      entity_type = string
    })), [])
    entity_types = optional(list(object({
      display_name = string
      kind         = string
      entities = list(object({
        value    = string
        synonyms = list(string)
      }))
    })), [])
  }))
  default = [
    {
      display_name = "greeting"
      description  = "User greeting intent"
      training_phrases = [
        "hello",
        "hi",
        "hey there",
        "good morning",
        "good afternoon",
        "howdy"
      ]
    },
    {
      display_name = "farewell"
      description  = "User farewell intent"
      training_phrases = [
        "bye",
        "goodbye",
        "see you later",
        "thanks, bye",
        "that's all"
      ]
    }
  ]
}

###############################################################################
# Webhook
###############################################################################

variable "webhook_url" {
  description = "External webhook URL for fulfillment. If null and enable_vertex_ai_features is true, a Cloud Run backend is created."
  type        = string
  default     = null
}

###############################################################################
# Vertex AI Features
###############################################################################

variable "enable_vertex_ai_features" {
  description = "Enable Vertex AI Feature Store and Cloud Run webhook backend"
  type        = bool
  default     = false
}

###############################################################################
# Storage
###############################################################################

variable "storage_bucket_name" {
  description = "Name for the GCS bucket to store agent data and training artifacts. Set to null to skip bucket creation."
  type        = string
  default     = null
}

###############################################################################
# Tags / Labels
###############################################################################

variable "tags" {
  description = "Labels to apply to GCP resources"
  type        = map(string)
  default     = {}
}
