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

class NextPrimeViewTests(APITestCase):
    def test_next_prime_success(self):
        """
        Ensure we can get the next prime number.
        """
        url = '/api/prime_next/7/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, {'next_prime': 11})

    def test_next_prime_invalid_input(self):
        """
        Ensure invalid input is handled correctly.
        """
        url = '/api/prime_next/abc/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_next_prime_negative_input(self):
        """
        Ensure negative input is handled correctly.
        """
        url = '/api/prime_next/-1/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data, {'error': 'Number must be a non-negative integer.'})

