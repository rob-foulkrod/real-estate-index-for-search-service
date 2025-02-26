# AZD Trainer-Demo-Deploy Starter template

This template could be used as a starting point for creating your own AZD-compatible templates, which you will contribute to [Trainer-Demo-Deploy](https://aka.ms/trainer-demo-deploy). 

## ⬇️ Installation
- [Azure Developer CLI - AZD](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
    - When installing AZD, the above the following tools will be installed on your machine as well, if not already installed:
        - [GitHub CLI](https://cli.github.com)
        - [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
    - You need Owner or Contributor access permissions to an Azure Subscription to  deploy the scenario.

## 🚀 Cloning the scenario in 4 steps:

1. Create a new folder on your machine.
```
mkdir petender/azd-tdd-starter
```
2. Next, navigate to the new folder.
```
cd petender/azd-tdd-starter
```
3. Next, run `azd init` to initialize the deployment.
```
azd init -t petender/azd-tdd-starter
```
4. Copy the starter template into its own directory and modify the template.
```
Update the main.bicep and resources.bicep with your own resource information
```

## 🚀 Push the scenario to your own GitHub:

1. Sync the new scenario you created into your own GitHub account into a public repo



3. Once available, add the necessary "demo scenario artifacts" (demoguide, architecture diagram,...) 

4. With all template details and demo artifacts available in the repo, following the steps on how to [Contribute](https://microsoftlearning.github.io/trainer-demo-deploy/docs/contribute) to Trainer-Demo-Deploy.

   
## AI Hub from AI foundry on Azure
This repository provides a comprehensive guide on how to use AI Hub from AI Foundry on Azure. It includes step-by-step instructions, best practices, and examples to help you get started quickly and efficiently.

Table of Contents
Introduction
Prerequisites
Setup
Creating a Hub
Managing Projects
Best Practices
Troubleshooting
Contributing
License


### Introduction
AI Hub from AI Foundry on Azure is a centralized platform that allows teams to collaborate, manage resources, and streamline the development of AI projects. This guide will walk you through the basics of setting up and using AI Hub.

### Prerequisites
Before you begin, ensure you have the following:

An Azure account with appropriate permissions.
Access to Azure AI Foundry.
Basic knowledge of Azure services and AI development.
### Setup
Sign in to Azure AI Foundry: Go to the Azure AI Foundry portal and sign in with your Azure account.
Create a Project: If you don't have a project, create one by selecting + Create project at the top of the page.
### Creating a Hub
Navigate to Management Center: Select Management center from the left menu.
Create a New Hub: Select All resources, then the down arrow next to + New project, and finally + New hub.
Configure the Hub: Enter a name for your hub and modify other fields as needed. By default, a new AI services connection is created for the hub.
Review and Create: Review the information and select Create.
### Managing Projects
Once your hub is created, you can manage projects within it:

Create Projects: Developers can create projects from the hub and access shared resources.
Security and Resources: Projects inherit security settings and shared resource access from the hub.
### Best Practices
Organize Work: Use projects to organize work, isolate data, and restrict access as needed.
Preconfigure Resources: Set up connections to shared resources within the hub for easy access.
Troubleshooting
If you encounter any issues, refer to the Azure AI Foundry documentation for detailed troubleshooting steps.
 
