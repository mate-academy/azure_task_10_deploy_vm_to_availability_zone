# Create a Virtual Machine with Powershell

Now, when you learned aboud the SLA and availability, you know that with a single VM in Azure you are guaranteed to have only 99.9% of the VM uptime. That meant that your app can be unavailable for more than 40 minutes a week and you won't get any refund or discounts! Luckily, there are number of options you can affect the SLA for your VM infrastructure, and today you will explore one of them - availability zones. 

For two VMs, deployed to two distinct availability zones you will get 99.99% uptime SLA. It means that both VMs can be unavaiable at the same moment of time no longer than 4 minutes each month. In this task you will practice deploying VMs to availability zones. 

## How to complete tasks in this module 

Tasks in this module are relying on 2 PowerShell scripts: 

- `scripts/generate-artifacts.ps1` generates the task "artifacts" and uploads them to cloud storage. An "artifact" is evidence of a task completed by you. Each task will have its own script, which will gather the required artifacts. The script also adds a link to the generated artifact in the `artifacts.json` file in this repository — make sure to commit changes to this file after you run the script. 
- `scripts/validate-artifacts.ps1` validates the artifacts generated by the first script. It loads information about the task artifacts from the `artifacts.json` file.

Here is how to complete tasks in this module:

1. Clone task repository

2. Make sure you completed steps, described in the Prerequisites section

3. Complete the task, described in the Requirements section 

4. Run `scripts/generate-artifacts.ps1` to generate task artifacts. Script will update the file `artifacts.json` in this repo. 

5. Run `scripts/validate-artifacts.ps1` to test yourself. If tests are failing - follow the recomendation from the test script error message to fix or re-deploy your infrastructure. When you will be ready to test yourself again - **re-generate the artifacts** (step 4) and re-run tests again. 

6. When all tests will pass - commit your changes and submit the solution for a review. 

Pro tip: if you stuck with any of the implementation steps - run `scripts/generate-artifacts.ps1` and `scripts/validate-artifacts.ps1`. The validation script might give you a hint on what you should do.  

## Prerequisites

Before completing any task in the module, make sure that you followed all the steps described in the **Environment Setup** topic, in particular: 

1. Ensure you have an [Azure](https://azure.microsoft.com/en-us/free/) account and subscription.

2. Create a resource group called *"mate-resources"* in the Azure subscription.

3. In the *"mate-resources"* resource group, create a storage account (any name) and a *"task-artifacts"* container.

4. Install [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4) on your computer. All tasks in this module use Powershell 7. To run it in the terminal, execute the following command: 
    ```
    pwsh
    ```

5. Install [Azure module for PowerShell 7](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-11.3.0): 
    ```
    Install-Module -Name Az -Repository PSGallery -Force
    ```
If you are a Windows user, before running this command, please also run the following: 
    ```
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

6. Log in to your Azure account using PowerShell:
    ```
    Connect-AzAccount -TenantId <your Microsoft Entra ID tenant id>
    ```

## Requirements

In this task, you will need to write and run a Powershell script, which deploys 2 Virtual Machines across 2 distinct availability zones: 

1. Write your script code to the file 'task.ps1' in this repository:
    
    - In script, you should assume that you are already logged in to Azure and using correct subscription (don't use commands 'Connect-AzAccount' and 'Set-AzContext', if needed - just run them on your computer before running the script). 

    - Use any region you want, for example `uksouth`. 

    - Script already have code, which deploys single VM with no infrasstcuture redundancy. Update the code to deploy 2 VMs into 2 distinct availability zones. Check the documentation of [New-AzVm](https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-11.5.0) comandlet to learn how to set an availability zone during VM creation. 
    
    - Both VMs should be deployed to the `default` subnet of the virtual network `vnet`, use network security group `defaultnsg`, and ssh key `linuxboxsshkey` (check the documentation of [New-AzVm](https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-11.5.0) - it allows you to just specify names of those resources as comandlet parameters). 

    - VMs should use image with friendly name `Ubuntu2204` and size `Standard_B1s`.

    - Note that in this task you are not required to deploy a pubclic IP resource for the VMs. 

2. When script is ready, run it to deploy resources to your subcription. 

3. Run artifacts generation script `scripts/generate-artifacts.ps1`.

4. Test yourself using the script `scripts/validate-artifacts.ps1`.

5. Make sure that changes to both `task.ps1` and `result.json` are commited to the repo, and sumbit the solution for a review. 

6. When solution is validated, delete resources you deployed with the powershell script - you won't need them for the next tasks. 
