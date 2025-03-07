# AI Hub from AI foundry on Azure

This repository contains the AI Hub from AI foundry on Azure platform, designed to serve as a foundation to doems involving AI Hubs, AI Projects, and Azure AI Search.

[Screen shot here]


## 🚀 Deployment

1. **Create a new folder on your machine.**
   ```sh
   mkdir rob-foulkrod/real-estate-index-for-search-service
   ```

2. **Navigate to the new folder.**
   ```sh
   cd rob-foulkrod/real-estate-index-for-search-service
   ```

3. **Initialize the deployment with `azd init`.**
   ```sh
   azd init -t rob-foulkrod/real-estate-index-for-search-service
   ```

4. **Trigger the actual deployment with `azd up`.**
   ```sh
   azd up
   ```

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
To create a New Hub, Select All resources, then the down arrow next to + New project, and finally + New hub.
Please go ahead and configure the Hub: Enter a name for your hub and modify other fields as needed. By default, a new AI services connection is created for the hub. The hub and the appropriate settings will be set up by the script as well. We have these instructions here as backup.
Review and Create: Review the information and select Create.
### Managing Projects
Once your hub is created, you can manage projects within it:

Create Projects: Developers can create projects from the hub and access shared resources.
Security and Resources: Projects inherit security settings and shared resource access from the hub.
### Best Practices
Organize Work: Use projects to organize work, isolate data, and restrict access as needed.
Preconfigure Resources: Set up connections to shared resources within the hub for easy access. For SFI purposes, we are going to have the following roles: Search Index contributor, search index data contributor, Storage blob data reader, and a managed identity of Azure AI administrator for the ML service to the AI foundry hub.

### Security roles needed
1. The user service principal needs to be an owner on the search service
2. AI hub and project need to contributors on the search service
3. The AI hub and the user service principal need to have the following roles: Search Index Data Contributor, Search Service Contributor, Storage Blob data reader, Storage Table Data Contributor and Storage file Data privileged reader
4. The user service principal has the Azure AI Inference Deployment Operator role
5. The AI project has the Azure AI administrator role to itself
6. The AI hub needs to have the user service principal have Azure AI inference deployment operator and the AI hub needs to have the Azure AI adminstrator role for itself.
7. The user service principal needs owner access to the AI hub.


### Troubleshooting
If you encounter any issues, refer to the Azure AI Foundry documentation for detailed troubleshooting steps.
 
