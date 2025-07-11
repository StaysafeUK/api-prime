# Prime Number API

This API provides a simple way to find the prime factors of a given integer and list of prime numbers.

## Index

- [How to Use](#how-to-use)
- [API Endpoint](#api-endpoint)
- [Example](#example)

## How to Use

To use the API, you need to deploy the infrastructure using Terraform. The following variables are required:

- `git_user`      : Your GitHub username.
- `git_pat`       : Your GitHub Personal Access Token.
- `git_project`.  : Your Github project
- `cloud_project` : Your Cloud Project GCP
- `Terraform`     : terraform apply -var="git_user=USERNAME" -var="git_pat=1MT2JJI086bp64cYVqca+GHJlwtkU8KuBGHJklxbBPII4BQvqEwfJrmdmqu7phjqovUy8OP423YCST8jYrQOIj" -var="git_project=GIT_PROJECT" -var="cloud_project=CLOUD PROJECT_GCP"

Confirm that you have a token from GCP before continuing go to https://jrevansprofile.verifyus.co.uk/contact for details on how you can get a token.

Once the infrastructure is deployed, the API will be available at the external IP address of the VM.

## API Endpoint

The API has a single endpoint:

- `GET /<integer>`: Returns the prime factors of the given integer.
- `GET /api/list/<integer>`: Returns a list of prime numbers.
- `GET /api/prime_next/<integer>`: Returns the next prime number in the series.
- `GET /api/prime_prev/<integer>`: Returns the previous prime number in the series.

## Example

To get the prime factors of the number 12, you would make a GET request to the following URL:

`http://<EXTERNAL_IP>/12`

The API would return the following JSON response:

```json
{
  "factors": [1,2,3,4,6,12]
}
```

`select for Divisibles` : `http://<EXTERNAL_IP>:8000/api/divisible/12435/?format=json`
`select for list of primes` : `http://<EXTERNAL_IP>:8000/api/list/100/?format=json`
`select for next prime` : `http://<EXTERNAL_IP>:8000/api/prime_next/12/?format=json`
`select for previous prime` : `http://<EXTERNAL_IP>:8000/api/prime_prev/12/?format=json`

for json format only.