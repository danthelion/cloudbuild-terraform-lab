# Cloud Build / Terraform lab

## Overview

In this lab, you will learn how to manage infrastructure as code with Terraform and Cloud Build using the popular GitOps methodology.

The process starts when you push Terraform code to either a feature branch or the master branch. In the scenario when you push to the master branch, Cloud Build triggers and then applies Terraform manifests to achieve the state you want in the respective environment. On the other hand, when you push Terraform code to any other branch—for example, to a feature branch—Cloud Build runs to execute terraform plan, but nothing is applied to any environment.

Ideally, either developers or operators must make infrastructure proposals to non-protected branches and then submit them through pull requests. The Cloud Build GitHub app, discussed later in this tutorial, automatically triggers the build jobs and links the terraform plan reports to these pull requests. This way, you can discuss and review the potential changes with collaborators and add follow-up commits before changes are merged into the base branch.

If no concerns are raised, you must first merge the changes to the master branch. This merge triggers an infrastructure deployment to the prod environment triggering the infrastructure installation to the production environment.


## Objectives


- Set up your GitHub repository.
- Configure Terraform to store state in a Cloud Storage bucket.
- Grant permissions to your Cloud Build service account.
- Connect Cloud Build to your GitHub repository.
- Change your environment configuration in a feature branch.
- Run terraform locally to change the development environment.
- Promote changes to the production environment.

## Task 1 - Set up your GitHub repository.
Fork this repository and clone the fork to your local machine.

![image info](./assets/gh-fork.png)

The code in the *terraform* folder of this repository is structured as follows:

- The environments/ folder contains subfolders that represent environments, such as dev and prod,
  which provide logical separation between workloads at different stages of maturity,
  development and production, respectively.
  Although it's a good practice to have these environments as similar as possible,
  each subfolder has its own Terraform configuration to ensure they can have unique settings as necessary.
- The modules/ folder contains inline Terraform modules.
  These modules represent logical groupings of related resources and are used to share code across
  different environments.
- The cloudbuild.yaml file is a build configuration file that contains instructions for Cloud Build,
  such as how to perform tasks based on a set of steps.
  This file specifies a conditional execution depending on the branch Cloud Build is fetching the code from,
  for example:

For the master branc, the following steps are executed:

terraform init
terraform plan
terraform apply


For any other branch, the following steps are executed:

terraform init for all environments subfolders
terraform plan for all environments subfolders
The reason terraform init and terraform plan run for all environments subfolders is to make sure that
the changes being proposed hold for every single environment.
This way, before merging the pull request, you can review the plans to make sure access is not being
granted to an unauthorized entity, for example.

## Task 2 - Configure Terraform to store state in a Cloud Storage bucket.

By default, Terraform stores state locally in a file named `terraform.tfstate`.
This default configuration can make Terraform usage difficult for teams,
especially when many users run Terraform at the same time and each machine has
its own understanding of the current infrastructure.

To help you avoid such issues, this section configures a remote state that points to a Cloud Storage bucket.
Remote state is a feature of backends and, in this tutorial, is configured in the `backend.tf`.

1. Create the Cloud Storage bucket
```shell
PROJECT_ID=$(gcloud config get-value project)
gsutil mb gs://${PROJECT_ID}-tfstate
```
2. Enable Object Versioning to keep the history of your deployments
```shell
gsutil versioning set on gs://${PROJECT_ID}-tfstate
```
3. Replace the PROJECT_ID placeholder with the project ID in both the terraform.tfvars and backend.tf files.
```shell
cd terraform
sed -i s/PROJECT_ID/$PROJECT_ID/g environments/*/terraform.tfvars
sed -i s/PROJECT_ID/$PROJECT_ID/g environments/*/backend.tf
```
4. Check whether all files were updates
```shell
git status
```
the output looks like this: