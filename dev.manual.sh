az login 
az ad sp create-for-rbac --name "GitHubActionsTerraform" --role Owner --scopes /subscriptions/c67fe336-eac2-49ff-9282-4e8570fd6d77 --sdk-auth