# Cloud Build / Terraform lab

## Overview

In this lab, you will learn how to manage infrastructure as code with Terraform and Cloud Build using
the popular GitOps methodology.

The process starts when you push Terraform code to the master branch.
In this scenario,  Cloud Build triggers and then applies Terraform manifests to achieve the state you want in the
respective environment. On the other hand, when you run Terraform code locally, you are able to change
the infrastructure of the development environment.

## Objectives

Part 1

- Set up your GitHub repository.
- Configure Terraform to store state in a Cloud Storage bucket.
- Grant permissions to your Cloud Build service account.
- Create the initial development environment infrastrcture.
- Change your environment configuration in a feature branch.
- Run terraform locally to change the development environment.
- Create a Cloud Build trigger to deploy infrastructure changes from the master branch.  
- Promote changes to the production environment.

Part 2

- Create an Event-Driven Cloud Function which loads data into BigQuery.
- Create a Cloud Pub/Sub trigger for the function.

## Requirements

- `gcloud` installed and authenticated to your GCP project.
- `terraform` version >= 0.14 installed. (You can check with `terraform version`)

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

- terraform init
- terraform plan
- terraform apply


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
4. Check whether all files were updated
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

## Task 4 - Create the initial development environment infrastructure.

Let's generate the initial state of the dev environment infrastructure on GCP. Run all of these commands from the
`terraform` folder.

1. Initialize the terraform configuration. Make sure to specify the _dev_ enviroments `.tfvars` file, located at
`environments/dev/terraform.tfvars`. This file contains the values which tell terraform that we are using
   the development environment.
```shell
terraform init -var-file=environments/dev/terraform.tfvars
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

4. Head over to your projects GCP console and verify that the resources have been created. You should see
a new BigQuery dataset and a table under it.
   
## Task 5 - Change your environment configuration in a feature branch.

If you would like to use an appropriate name for the new branch, the feature we will implement is a new
table under the test dataset called `beer`.

1. Create a feature branch from master in your local repostitory.
```shell
git checkout -b feature_branch_name
```

2. Create the schema for our new table in the directory `terraform/modules/bigquery/testdata/`.
- The already existing tables name is `testtable.json` so let's call our new file `beer.json` to follow the
   convention.
- The new table should have 3 columns with the following types. Feel free to use the already existing 
  `testtable.json` as an example.
  - name - STRING
  - brewery - FLOAT   
  - abv - FLOAT64
  
3. Add the terraform definiton for the new table.
- Create a new terraform resource in the file `terraform/modules/bigquery/testdata/main.tf`.
- All the fields are the same as the sample table definiton except for two:
  - table_id
  - schema
- The schema parameter should point to the `.json` file you created in the previous step.

4. Create a new variable for the new table name.
You have to define the new variable name in the following files: (`variable "beer_table_id" {}`)
 - `terraform/variables.tf`
 - `terraform/modules/bigquery/variables.tf`
 - `terraform/modules/bigquery/testdata/variables.tf`
 - `terraform/environments/dev/variables.tf`
 - `terraform/environments/prod/variables.tf`
  
In order to specify the actual value for the `dev` and `prod` environment, check out the following files:
- `terraform/environments/dev/terraform.tfvars`
- `terraform/environments/prod/terraform.tfvars`

and add a variable in each with your chosen table name, for example: `beer_table_id="beer"`

Lastly you will need to propagate the value in the following files for the BigQuery module definitons as well:
- `terraform/main.tf`
- `terraform/modules/bigquery/testdata/main.tf`

5. Before commiting your changes, verify them locally with terraform, on the `dev` environment.
```shell
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

6. Stage, commit and push your changes to the remote repository.

7. Create a pull request on GitHub, but before merging your branch to `master` complete the next task.

## Task 6 - Create a Cloud Build trigger to deploy infrastructure changes from the master branch.

1. Head over to the Cloud Build > Triggers page on your GCP console and Click `Manage Repositories`.
2. Click `Connect Repository`.
- Select GitHub as source.
- Select your GitHub account and this repository.
3. Select `Create a Trigger`.
- Give a name to your trigger, something like `Release to production` will work.
- Under `Event`, select `Push to a branch`.
- The source should be `your_github_user/cloudbuild-terraform-lab (GitHub App)`.
- For `Branch`, type in `master`, as we want this trigger to activate on code changes on the `master` branch only.
- Under `Configuration` select `Cloud Build configuration file (yaml or json)` for type and `Repository` for location.
  - The Cloud Build configuration file location is just `cloudbuild.yaml`, as the file is located in the repo root.
- Select `Create`. 

## Task 7 - Promote changes to the production environment.
1. Take a look at the file `cloudbuild.yaml` to study its contents before proceeding. This file
contains the build steps Cloud Build will go through when the trigger is activated which we created in
the previous step.
   
2. As you can see the build steps resemble the manual steps we did when promoting changes to the
dev environment, except for the `apply` step we skip the manual agreement via the `-auto-approve` flag,
   and we use the `.tfvars` file located at `terraform/environments/prod/terraform.tfvars` instead of
the dev environment one.
   
3. Merge your PR on GitHub, which will activate the Cloud Build trigger.

4. You can see the results on the GitHub PR page as well as on the Triggers page of the Cloud Build UI.

5. If the build is successful, make sure to verify it by checking out the new table on your BigQuery interface.

## Task 7 - Create an Event-Driven Cloud Function which loads data into BigQuery.
1. Uncomment the `pubsub` and `cloudfunctions` modules in `terraform/main.tf`.
2. Re-initialize terraform.
```shell
terraform init -var-file=environments/dev/terraform.tfvars
```
3. The code of the Cloud Function is located in the folder `terraform/modules/cloudfunctions/loader`.
`main.py` contains the Python function which will read the data from the Pub/Sub message and load it into
   BigQuery while `requirements.txt` defines the extra modules the function needs.
Edit the file `terraform/modules/cloudfunctions/loader/main.py` so when the function runs it loads
data into the correct bigquery table. Remember that because in this tutorial we only separate the `prod`
   and `dev` environments via the dataset name, your dataset will have a `_dev` postfix. Make sure to check
   the correct name before applying the infrastructure changes.
4. Apply the changes to the dev environment. 
```shell
terraform apply -var-file=environments/dev/terraform.tfvars
```
5. Test out the data pipeline by sending a message to the pubsub topic!
An example payload would look something like this:
```json
{"name": "Tripel Karmeliet", "brewery": "Bosteels Brewery", "abv": 8.4}
```
6. Check logs, BQ table