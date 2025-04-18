[comment]: <> (please keep all comment items at the top of the markdown file)
[comment]: <> (please do not change the ***, as well as <div> placeholders for Note and Tip layout)
[comment]: <> (please keep the ### 1. and 2. titles as is for consistency across all demoguides)
[comment]: <> (section 1 provides a bullet list of resources + clarifying screenshots of the key resources details)
[comment]: <> (section 2 provides summarized step-by-step instructions on what to demo)


[comment]: <> (this is the section for the Note: item; please do not make any changes here)
***
### <your scenario title here>

<div style="background: lightgreen; 
            font-size: 14px; 
            color: black;
            padding: 5px; 
            border: 1px solid lightgray; 
            margin: 5px;">
</div>

[comment]: <> (this is the section for the Tip: item; consider adding a Tip, or remove the section between <div> and </div> if there is no tip)

***
### 1. What Resources are getting deployed
<add a one-paragraph lengthy description of what the scenario is about, and what is getting deployed>
These resources are configured in this manner to demonstrate the capabilities of LLMs, specifically RAG. We will provide you with a default index that you can use to showcase RAG capabilities within Azure OpenAI. You are welcome to add as many indexes as you want to showcase your scenario.

Provide a bullet list of the Resource Group and all deployed resources with name and brief functionality within the scenario. 
List of all resources within the deployed resource group:
- **Azure AI Hub**: Centralized repository for all your AI projects
- **Azure AI services**: A resource that allows you to deploy only Azure OpenAI models and build AI applications
- **Azure AI project**: A resource that allows you to deploy Azure OpenAI or other foundational models and use them to build AI applications
- **Deployment script**: The script that allows you to deploy these resources consistently
- **Storage account**: Stores files, images, videos, blobs etc. and allows the search service to reference that information when it utilizes the RAG method
- **Azure AI Search Service**: The service that acts as your repository for your indexes(vector and semantic) and helps your LLMs' work with the retrieved data
- **Event Grid System Topic**: The Azure Event Grid system topic is automatically created by Azure services to manage and publish events from those services.

### 2. What can I demo from this scenario after deployment

Provide clear step-by-step instructions on what can be demoed after the scenario got deployed. If your demo requires additional manual steps to configure or update settings or make changes to the deployed resources, please mention it here.

Add screenshots where relevant. They can be stored in their own subfolder under the demoguide folder.

Once the resources are all deployed. You can go ahead and demo RAG capabilities to your learners. You can do so by following the steps below.
1. Launch your Azure AI project
![image](https://github.com/user-attachments/assets/a45f0ea8-02d6-4371-b2a6-daa183d62c60)
2. Deploy an Azure OpenAI model(4o-mini is a good option)
3. Open the playground with the model
![image](https://github.com/user-attachments/assets/59fc3996-00f7-4557-bf01-768c424f3f83)
4. Open "Add your data" carat menu and click on the "Add a new data source" button
5.  Select "Upload files"
![image](https://github.com/user-attachments/assets/c566d33d-8368-4079-89c3-097046c8ed40)
6. Find a suitable file like a pdf.
7. Optionally, you can add a vector search if you want that as part of your RAG solution
8. Create a vector index
9. Use that Index alongside your LLM.
![image](https://github.com/user-attachments/assets/14f4e9af-78f0-498e-acfd-5c68070d88ae)
10. Now ask questions related to your index. So you can try out a query/input like "Which Hotels should I go to in London"





[comment]: <> (this is the closing section of the demo steps. Please do not change anything here to keep the layout consistant with the other demoguides.)
<br></br>
***
<div style="background: lightgray; 
            font-size: 14px; 
            color: black;
            padding: 5px; 
            border: 1px solid lightgray; 
            margin: 5px;">

**Note:** This is the end of the current demo guide instructions.
</div>




