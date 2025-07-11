from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status

class PrimeListViewTests(APITestCase):
    def test_prime_list_success(self):
        """
        Ensure we can get a list of prime numbers.
        """
        url = '/api/list/5/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, {'primes': [2, 3, 5, 7, 11]})

    def test_prime_list_invalid_input(self):
        """
        Ensure invalid input is handled correctly.
        """
        url = '/api/list/abc/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_prime_list_zero_input(self):
        """
        Ensure zero input is handled correctly.
        """
        url = '/api/list/0/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data, {'error': 'Number must be a positive integer.'})

