AWS Terraform LoaRDSdbalancer deployment action
============================
This repository is home to a _RDS_ deployment GitHub action used as a template for
rapid development of Terraform based actions. The goal of this model is to
provide a common framework for deploying modularized infrastructure with
configuration paramters supplied as part of the GitHub workflow.

Usage
-----
Simply clone this repository and start developing your Terraform IAC. The
entrypoint handler for this action will automatically translate GitHub inputs
into terraform variables.

For example, if your define the following `action.yaml`:
```yaml
  - name: My Project
    id: project
    uses: aplaceformom/terraform-project-base-action@master
    with:
      workspace: dev
      project: my-project
      owner: myteam
      email: myteam@example.org
      remote_state_bucket: apfm-terraform-remotestate
      remote_lock_table: terraform-statelock
      shared_state_key: terraform/apfm.tfstate
        debug: false
  - name: RDS Deploy
    uses: aplaceformom/terraform-rds-action@master
    with:
      name: "rds-name"
```

### engine_version
ElasticSearch engine version
- default: 7.4

### ebs
Enable ebs storage.
- default: true

### instance_type
The ElasticSearch instance type to use. See: https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-supported-instance-types.html
- default: t2.medium.elasticsearch

### instance_count
The number of nodes to run in your instance. Note: enabling 3 instances will
make the cluster multi-availability-zone aware.
- default: 1

### volume_type
ElasticSearch Volume type (standard, gp2, io1)
- default: gp2

### volume_size
Per instance volume size (in gigs).
- default: 10

### log_type
A type of Elasticsearch log. Valid values: INDEX_SLOW_LOGS, SEARCH_SLOW_LOGS, ES_APPLICATION_LOGS
- default: INDEX_SLOW_LOGS

### public
Make ElasticSearch accessible publicly (dangerous). If you enable this option
then the ElasticSearch cluster will be made available on a public IP.  You
should configured the `allowed_ips` to restrict access to the instance.
- default: false

### allowed_ips
A comman seperated list of network maps (in CIDR format) which should be
granted access to this ElasticSearch instance (only valid if public = true).
- example: x.x.x.x/32,y.y.y.y/24
- default: N/A

- More information about the valid options to be used, can be found [here](https://aplaceformom.atlassian.net/wiki/spaces/TECHOPS/pages/1049133728/2020+AWS+Tagging+Standards) 

Test executed
-------------

- Add more nodes to a cluster previously created: 
  - Result: Nodes were added without interrupt service.
- Remove nodes from the cluster previosly created:
  - Result: Nodes were removed without interruption.
- Upsize nodes:
  - Result: Nodes were resized without interrupt service.
- Downsize nodes:
  - Result: Nodes were downsized without interruption.

References
----------

- https://www.terraform.io/docs/providers/aws/r/elasticsearch_domain.html
- https://docs.aws.amazon.com/cli/latest/reference/es/create-elasticsearch-domain.html
- https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-supported-instance-types.html
- https://docs.aws.amazon.com/cli/latest/reference/es/create-elasticsearch-domain.html
