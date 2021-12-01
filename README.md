# Overview

Using GitHub Actions + Terraform cloud for Azure deployment is a nice combo. Actions is nice because the GitHub hosted runners are [well documented](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners) in terms of setup, as opposed to Terraform. Terraform Cloud is nice because it always encrypts state at rest and protects it with TLS in transit.

# Setup

## Part 1:  Configure Terraform Cloud account and generate an API key
Overview: You will setup terraform cloud for remote API acces, and setup a workspace to be called by GitHub Actions.
1. Create a [Terraform cloud](https://www.terraform.io/cloud), or sign-in if you have one already.
1. Create a Terraform api token.
   1. Click on the "User Settings" under the user avatar in the upper right corner of the screen
   1. Click on "Tokens" on the left nav panel.
   1. Click on "Create an API token". You should give your token a sensible name that relates to where it is consumed. I follow the convention of "github_\<repo\>" for my tokens.
   1. The token will only be viewable once after generation, so save it somewhere secure for later when we apply it to your GitHub repo (e.g. a password safe).
1. Create a Terraform workspace.
   1. Click "+ New workspace"
   1. Select "API-driven workflow"
   1. Give your workspace a useful name (again, "github_\<repo\>" works here).
   1. Copy the Terraform code block which appears and save it for later as well.
   1. Go to "Settings" for your new workspace, and change execution mode to "Local". Click "Save settings" when complete.

## Part 2: Create Repo and configure for Terraform
Overview: You will create a github repo and configure it to connect to terraform cloud.
1. Create a repo in your account. You may want to use select Terraform as a .gitignore template for convenience.
1. After the repo is created, click "Settings" on the far right.
1. Locate "Secrets" on the left nav pane and click it.
1. Click "New repository secret".
1. Set the secret Name to "TF_API_TOKEN". The Terraform Action definition for GitHub expects this name.
1. Set the secret Value to the Terraform API token you generated in your Terraform cloud account.
1. Click "Add secret"
1. Click on "Actions"
1. Search for "Terraform" in the "search workflows" search box. As of this writing, there is only a single Terraform workflow, which is authored by HashiCorp.
1. Click "Configure" in the Terraform tile.
1. A new terraform.yml file will appear. At the moment, you don't need to do anything with it other than click "Start commit". I commited mine directly to main for this exercise.

## Part 3: Generate Azure Credentials
### Note: This section assumes you have an existing Azure account.
Overview: You will now generate an Azure Service Principal and corresponding credentials to assign to the terraform.yml file created above. These creds will be used by the [Azure Provider for Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) to deploy your Azure resources. The steps below are derived from the [Azure Provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret) regarding authenticaition.

1. If you haven't already, [install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
1. Run `az login`.
1. Run `az account list`
1. The above command will return a json blob. The "id" field within that blob is your subscription id. If you only have one subscription, this is the one you should use.
1. run `az account set --subscription="SUBSCRIPTION_ID"`, substituting in the subscription id you just extracted above.
1. run `az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID" --name="github_<repo>"`
   * Note: if you need to create identites or perform role binding, you should set `--role="Owner"`. More info [here](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all).
1. The resulting JSON blob contains 3 fields you need. Along with the subscription id from above, these fields will be used to set environment variables used by the Azure Provider for Terraform to make Azure API calls. These environment variables will be set in the terraform.yml created earlier. More info on how the Azure Provider consumes credentials [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#configuring-the-service-principal-in-terraform).
   * We will configure all of these fields in the next step, but here is how they will be mapped to environment variables.
   * The subcription id you're using  will be assigned to the `ARM_SUBSCRIPTION_ID` envrionment variable.
   * The appId field from above will be assigned to the `ARM_CLIENT_ID` environment variable.
   * The password field will be assigned to the `ARM_CLIENT_SECRET` environment variable.
   * The tenant field will be assigned to the `ARM_TENANT_ID` environment variable.

# Part 4: Set Azure envionment variables within the Terraform workflow in Actions.
Overview: You will set job level environment variables for your Terraform workflow for Azure using the four variables created in Part 3.

1. Configure your environment variables under the jobs->terraform->env in the terraform.yml file [like so](https://github.com/jcetina/tf_azure_poc/blob/809a7c5e6022413765fec74bc18929667b95475e/.github/workflows/terraform.yml#L58-L62), substituting your subcription, tenant, and client id accordingly.
1. Commit this change.
1. The `ARM_CLIENT_SECRET` will actually be stored as a secret. Navigate to the "Settings" for your repo, and click "Secrets" on the left side.
1. Create a secret with name `ARM_CLIENT_SECRET`, and set the value using the password/ARM_CLIENT_SECRET value from Part 3 above. The `${{ secrets.ARM_CLIENT_SECRET }}` expression in the terraform.yml file will extract the secret whenever this workflow is triggered.

# Part 5: Check-in main.tf
Overview: You will check-in a terraform file to trigger your workflow. Within this terraform file, you will configure remote settings for your terraform organization and workspace.
1. Create a new main.tf file at the top level of your repo. You can just do this in the GitHub UI if you'd like.
1. Copy the file contents [here](https://github.com/jcetina/tf_azure_poc/blob/8f9e59c4cabfb5cf278e9b609ea064b94c5fef79/main.tf) and paste them into the main.tf file above. DO NOT COMMIT THEM YET.
1. Modify the terraform remote name and workspace variables in the [backend block](https://github.com/jcetina/tf_azure_poc/blob/8f9e59c4cabfb5cf278e9b609ea064b94c5fef79/main.tf#L12-L18) in the editor to match the values in the code block you copied all the way up near the end of Part 1.
1. Once the backend block is configured corretly, you should commit main.tf to your repo. This will now trigger the Action do run the Terraform workflow.
1. If you click on "Actions" for your repo, you can watch the output of your Action.
1. If you log back in to your Terraform Cloud account, you should be able to see should be able to see any resources you created in the "Overview" tab for the remote workspace, and also any state under the "States" tab.
   
# Done!
Congratulations. Hopefully you were able to complete this without any hiccups. If something is not working, please feel free to open an issue and I'll do my best to help as time allows.

# References
* https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
* https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all
* https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
* https://www.terraform.io/docs/cloud/index.html
* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#configuring-the-service-principal-in-terraform
