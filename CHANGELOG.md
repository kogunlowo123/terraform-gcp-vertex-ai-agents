# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added

- Initial release of the GCP Vertex AI Agent Builder Terraform module.
- Dialogflow CX agent provisioning with configurable language, time zone, and speech settings.
- Conversation flow management with NLU settings, transition routes, and event handlers.
- Page definitions within flows including form parameters and entry fulfillment.
- Intent management with training phrases and parameter extraction.
- Entity type definitions with synonym support.
- Webhook configuration for external fulfillment endpoints.
- Cloud Run v2 service deployment for webhook backend hosting.
- Vertex AI Feature Store integration for agent memory and context persistence.
- GCS bucket for agent data storage and training artifacts.
- Service account with scoped IAM bindings for Dialogflow, Vertex AI, Storage, and Cloud Run.
- Automatic API enablement for Dialogflow, Vertex AI, Cloud Run, and Storage.
