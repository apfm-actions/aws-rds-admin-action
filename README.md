AWS Terraform RDS Admin action
============================
This repository is home to a _RDS_ deployment GitHub action this action create a single database in our internal cluster.

WARNING
-------

This action is ONE TIME execution, you should only run this one time.

Usage
-----
You can use it in 2 ways, add the following section to a workflow into a github actions or your can execute them manually from you workstation.

*Github Action:*

For example, if your define the following `action.yaml`:
```yaml
      - name: Shared Info
        id: project
        uses: 'docker://apfm/terraform-project-base-action:latest'
        with:
          project: demo-project
          owner: techops
          email: techops@aplaceformom.com
          tf_assume_role: TerraformApply
          remote_state_bucket: apfm-terraform-remotestate
          remote_lock_table: terraform-statelock
          shared_state_key: terraform/apfm.tfstate
          debug: false
    - name: "Create a new database"
      uses: apfm-actions/aws-ecs-exec-action@master
      with:
          project: demo-project
          name: create-demo-database
          image: ${{ steps.project.outputs.account_root_id }}.dkr.ecr.${{ steps.project.outputs.network_region }}.amazonaws.com/aws-rds-admin-action:latest
          cpu: 256
          memory: 512
          command: '["entrypoint.sh"]'
          wait: true
          timeout: 600
          cluster: ${{ steps.project.outputs.cluster_id }}
          environment: DB_NAME,ENGINE
          debug: true
      env:
        DB_NAME: name_new_database
        ENGINE: postgresql
```

## Environment Variables required

### DB_NAME
Name of the database
- default: none
- required: true

### ENGINE
Name of the database
- default: none
- required: true
- options: mysql, postgresql

*Manual execution:*

```
#!/bin/sh
export AWS_DEFAULT_REGION='YOUR_REGION'
export AWS_ACCESS_KEY_ID='YOUR_ACCESS_KEY'
export AWS_SECRET_ACCESS_KEY='YOURSECRETKEY'
export EXTERNAL_ID='YOUR_EXTERNAL_ID'
export ROOT_ACCOUNT_ID='YOUR_ROOT_ACCOUNT_ID'

AWS_ACCESS_JSON=$(aws sts assume-role --external-id ${EXTERNAL_ID} --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/TerraformApply" --role-session-name "aws-rds-exec-action")

export AWS_ACCESS_KEY_ID="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.AccessKeyId')"
export AWS_SECRET_ACCESS_KEY="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.SecretAccessKey')"
export AWS_SESSION_TOKEN="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.SessionToken')"

export DB_NAME='YOUR_DABATASE_NAME'
export ENGINE='YOUR_ENGINE'
export INPUT_AWS_ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/TerraformApply

./entrypoint.sh
```
