# 🤖 Salesforce AI Contact Generator

Generate realistic, industry-specific mock contact data for your Salesforce org using AI-powered prompt templates. Perfect for testing, training, and demonstrations.

## ✨ Features

- 🧠 **AI-Powered Generation**: Uses OpenAI GPT-4 Omni Mini to create realistic contact data
- 🏭 **Industry-Specific**: Generates job titles and descriptions relevant to any industry
- 🌍 **Diverse Names**: Creates contacts with culturally diverse names and backgrounds
- 📋 **Salesforce Native**: Built with Flows, Apex, and Einstein AI components
- ⚡ **Agent Integration**: Works seamlessly with Salesforce Agent Builder

## 🏗️ Components

- **Contact Generator Apex Class**: Processes AI-generated JSON and creates Contact records
- **AI Prompt Template**: Generates industry-relevant contact data with proper Salesforce formatting
- **Flow Definition**: Orchestrates the contact generation process
- **AI Plugin**: Enables natural language interaction for contact generation

## 🚀 Quick Start

1. Deploy to your Salesforce org:
   ```bash
   sf project deploy start --target-org your-org-alias
   ```

2. Use in Salesforce Agent Builder or invoke the Flow manually to generate contacts for any Account

## 💬 Usage Examples

- "Generate 5 contacts for this automotive company"
- "Create sample contacts for a healthcare organization"
- "Add 3 mock contacts in the fintech industry"

## 📊 Generated Contact Data

Each generated contact includes:
- Diverse first and last names
- Industry-relevant job titles
- Professional email addresses
- Realistic phone numbers
- Complete mailing addresses
- Industry-specific descriptions

## 🛠️ Development

Built with:
- Salesforce API Version 64.0
- Einstein AI Platform
- OpenAI GPT-4 Omni Mini
- Apex, Flows, and Lightning Web Components

## 📄 License

This project is for demonstration and educational purposes.
