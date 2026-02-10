PROJECT_ID=$(az cognitiveservices account project show --name my-foundry-resource --resource-group my-foundry-rg --project-name my-foundry-project --query id -o tsv)

az role assignment create --role "Azure AI User" --assignee "user@contoso.com" --scope $PROJECT_ID

az role assignment create --role "Azure AI User" --assignee-object-id "<security-group-object-id>" --assignee-principal-type Group --scope $PROJECT_ID

