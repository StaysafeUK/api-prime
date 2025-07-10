# Prime Number Factor API

This API provides a simple way to find the prime factors of a given integer.

## Index

- [How to Use](#how-to-use)
- [API Endpoint](#api-endpoint)
- [Example](#example)

## How to Use

To use the API, you need to deploy the infrastructure using Terraform. The following variables are required:

- `git_user`: Your GitHub username.
- `git_pat`: Your GitHub Personal Access Token.

Once the infrastructure is deployed, the API will be available at the external IP address of the VM.

## API Endpoint

The API has a single endpoint:

- `GET /<integer>`: Returns the prime factors of the given integer.

## Example

To get the prime factors of the number 12, you would make a GET request to the following URL:

`http://<EXTERNAL_IP>/12`

The API would return the following JSON response:

```json
{
  "number": 12,
  "factors": [2, 2, 3]
}
```