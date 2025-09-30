# Prime Number API

This API provides a simple way to find the prime factors of a given integer, list of prime numbers, previous prime number, next prime numbers and all prime number api's.

## Index

- [How to Use](#how-to-use)
- [API Endpoint](#api-endpoint)
- [Example](#example)

## How to Use

For New Relic monitoring run API-PRIME/scripts/newrelic.sh to add new-relic-api-key to Google
secrets manager FIRST:

To use the API, you need to deploy the infrastructure using Terraform. The following variables are required:

- `git_user`            : Your GitHub username.
- `git_pat`             : Your GitHub Personal Access Token.
- `git_project`.        : Your Github project
- `cloud_project`       : Your Cloud Project GCP
- `instance_count`      : Number of instances to apply
- `domain_name`         : Domain name for HTTPS LB
- `Terraform`           : Terraform command to build and deploy
- `celery_worker_count` : Celery worker count 
```trf 
terraform apply -var="instance_count=2" -var="celery_worker_count=2" -var="git_user=USERNAME" -var="git_pat=1MT2JJI086bp64cYVqEXAMPLETOKENI4BQvqEwfJrmdmqu7phjqovUy8OP423YCST8jYrQOIj" -var="git_project=GIT_PROJECT" -var="cloud_project=CLOUD PROJECT_GCP" -var="domain_name=api.yourdomain.co.uk" 
```

Confirm that you have a token from GCP before continuing go to https://jrevansprofile.verifyus.co.uk/contact for details on how you can get a token.

Once the infrastructure is deployed, the API will be available at the external IP address of the VM.

## API Endpoint

The API has a single endpoint:

- `GET /api/divisible/<integer>`  : Returns the prime factors of the given integer. > 99999999999999999
- `GET /api/list/<integer>`       : Returns a list of prime numbers. > 260000
- `GET /api/prime_next/<integer>` : Returns the next prime number in the series.
- `GET /api/prime_prev/<integer>` : Returns the previous prime number in the series.
- `GET /api/all/<integer>`        : Returns the previous prime number in the series. > 260000
- `GET /api/task_status/<TASK_ID>`: Use to get the status and result of a Celery driven task for > E17


## Example A

To get the prime factors of the number 12, you would make a GET request to the following URL:

`http://<EXTERNAL_IP>/12`

## Example B 

To get the prime factors of E 17+ this example E18 (999999999999999990), you would make a GET request to the following URL:

`https://<api.domainname.co.uk/api>/divisible/999999999999999999/format=json` this will generate a Celery Task ID example 6a862855-37b0-4f07-a94a-d8c71168145d.

You can then check the status, and result of the task by making a GET request to the following URL: `https://<api.domainname.co.uk/api/task_status/6a862855-37b0-4f07-a94a-d8c71168145d/?format=json`

The API would return the following JSON response:

```json
{
  "task_id": "6a862855-37b0-4f07-a94a-d8c71168145d",
  "status": "PENDING",
  "result": null
}

Refresh Until result is given
```

## External LB 

To find the external IP address of the Load blancer when two or more hosts are used use the following cloud command
`gcloud compute forwarding-rules describe api-prime-forwarding-rule \--global \`                                                                                  
`--project=GCP_PROJECT \`
`--format="value(IPAddress)"`

The API would return the following JSON response:

```json
{
  "factors": [1,2,3,4,6,12]
}
```

`select for Divisibles`     : `http://<EXTERNAL_IP>:8000/api/divisible/12435/?format=json`
`select for list of primes` : `http://<EXTERNAL_IP>:8000/api/list/100/?format=json`
`select for next prime`     : `http://<EXTERNAL_IP>:8000/api/prime_next/12/?format=json`
`select for previous prime` : `http://<EXTERNAL_IP>:8000/api/prime_prev/12/?format=json`
`select for All`            : `http://<EXTERNAL_IP>:8000/api/all/12/?format=json`
`select for task_status`    : `http://<EXTERNAL_IP:8000/api/task_status/6a862855-37b0-4f07-a94a-d8c71168145d"/?format=json>`

for json format only.