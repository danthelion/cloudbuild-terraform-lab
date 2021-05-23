# Cloud Build / Terraform lab

## Overview

In this lab, you will learn how to manage infrastructure as code with Terraform and Cloud Build using
the popular GitOps methodology.

The process starts when you push Terraform code to the master branch.
In this scenario,  Cloud Build triggers and then applies Terraform manifests to achieve the state you want in the
respective environment. On the other hand, when you run Terraform code locally, you are able to change
the infrastructure of the development environment.

## Objectives


- Set up your GitHub repository.
- Configure Terraform to store state in a Cloud Storage bucket.
- Grant permissions to your Cloud Build service account.
- Create the initial development environment infrastrcture.
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
```shell
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   environments/dev/backend.tf
	modified:   environments/dev/terraform.tfvars
	modified:   environments/prod/backend.tf
	modified:   environments/prod/terraform.tfvars

no changes added to commit (use "git add" and/or "git commit -a")
```
5. Commit and push your changes.
```shell
git add --all
git commit -m "Update project IDs and buckets"
git push origin master
```

## Task 3 - Grant permissions to your Cloud Build service account.

To allow Cloud Build service account to run Terraform scripts with the goal of managing Google Cloud resources,
you need to grant it appropriate access to your project.
For simplicity, project editor access is granted in this tutorial.
But when the project editor role has a wide-range permission, in production environments
you must follow your company's IT security best practices, usually providing least-privileged access.

1. In Cloud Shell, retrieve the email for your project's Cloud Build service account:
```shell
CLOUDBUILD_SA="$(gcloud projects describe $PROJECT_ID \
    --format 'value(projectNumber)')@cloudbuild.gserviceaccount.com"
```
2.Grant the required access to your Cloud Build service account:
```shell
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$CLOUDBUILD_SA --role roles/editor
```

## Task 4 - Create the initial development environment infrastrcture.

Let's generate the initial state of the dev environment infrastructure on GCP. Run all of these commands from the
`terraform` folder.

1. Initialize the terraform configuration.
```shell
terraform init
```

2. See the proposed changes with plan. Make sure to specify the _dev_ enviroments `.tfvars` file, located at
`environments/dev/terraform.tfvars`.
```shell
terraform plan -var-file=environments/dev/terraform.tfvars
```

3. If everything looks ok apply the changes!.
```shell
terraform apply -var-file=environments/dev/terraform.tfvars
```