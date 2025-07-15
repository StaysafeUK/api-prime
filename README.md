# Prime Number API

This API provides a simple way to find the prime factors of a given integer, list of prime numbers, previous prime number, next prime numbers and all prime number api's.

The API is built using a Docker Container 

## Index

- [How to Use](#how-to-use)
- [API Endpoint](#api-endpoint)
- [Example](#example)

## How to Use

To use the API, you need to deploy the infrastructure using Docker. Ensure you have docker-compose on your conputer.

- `DIRECTORY`       : ../api-prime/divisible_api
- `docker-compose`  : docker-compose up
```trf 
docker-compose up
curl 'http://localhost:8000/api/list/12/?format=json' 
{"primes":[2,3,5,7,11,13,17,19,23,29,31,37]}%  

```

Confirm that you have a token from GCP before continuing go to https://jrevansprofile.verifyus.co.uk/contact for details on how you can get a token.

Once the infrastructure is deployed, the API will be available at the external IP address of the VM.

## API Endpoint

The API has a single endpoint:

- `GET /<integer>`                : Returns the prime factors of the given integer.
- `GET /api/list/<integer>`       : Returns a list of prime numbers.
- `GET /api/prime_next/<integer>` : Returns the next prime number in the series.
- `GET /api/prime_prev/<integer>` : Returns the previous prime number in the series.
- `GET /api/all/<integer>`        : Returns the previous prime number in the series.


## Example

To get the prime factors of the number 12, you would make a GET request to the following URL:

`http://<EXTERNAL_IP>/12`


The API would return the following JSON response:

```json
{
  "factors": [1,2,3,4,6,12]
}
```

`select for Divisibles`     : `curl 'http://localhost:8000/api/divisible/12435/?format=json`
`select for list of primes` : `curl 'http://localhost:8000/api/list/100/?format=json`
`select for next prime`     : `curl 'http://localhost:8000/api/prime_next/12/?format=json`
`select for previous prime` : `curl 'http://localhost:8000/api/prime_prev/12/?format=json`
`select for All`            : `curl 'http://localhost:8000/api/all/12/?format=json`

for json format only.