from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status

class DivisibleViewTests(APITestCase):
    def test_divisible_success(self):
        """
        Ensure we can get a list of divisors.
        """
        url = '/api/divisible/10/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, {'factors': [1, 2, 5, 10]})

    def test_divisible_invalid_input(self):
        """
        Ensure invalid input is handled correctly.
        """
        url = '/api/divisible/abc/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_divisible_zero_input(self):
        """
        Ensure zero input is handled correctly.
        """
        url = '/api/divisible/0/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data, {'error': 'Please enter a positive number to find its divisors.'})

    def test_divisible_limit(self):
        """
        Ensure the divisible limit is enforced.
        """
        url = '/api/divisible/100000000000000000/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data, {'error': 'The number you entered is very large. Please try a smaller number.'})

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
        self.assertEqual(response.data, {'error': 'Please enter a positive number to get that many primes.'})

    def test_prime_list_limit(self):
        """
        Ensure the prime list limit is enforced.
        """
        url = '/api/list/260001/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data, {'error': 'You requested a very long list of prime numbers. Please try a smaller number.'})

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
        self.assertEqual(response.data, {'error': 'Please enter a non-negative number to find the next prime.'})

class PreviousPrimeViewTests(APITestCase):
    def test_previous_prime_success(self):
        """
        Ensure we can get the previous prime number.
        """
        url = '/api/prime_prev/7/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, {'previous_prime': 5})

    def test_previous_prime_invalid_input(self):
        """
        Ensure invalid input is handled correctly.
        """
        url = '/api/prime_prev/abc/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_previous_prime_no_prime(self):
        """
        Ensure no prime number is returned when there are no smaller primes.
        """
        url = '/api/prime_prev/2/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data, {'error': 'There are no prime numbers smaller than the one you entered. Please try a larger number.'})

class AllInOneViewTests(APITestCase):
    def test_all_in_one_success(self):
        """
        Ensure we can get all the results from the other APIs.
        """
        url = '/api/all/10/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, {
            'divisible': [1, 2, 5, 10],
            'list': [2, 3, 5, 7, 11, 13, 17, 19, 23, 29],
            'prime_next': 11,
            'prime_prev': 7
        })

    def test_all_in_one_limit(self):
        """
        Ensure the all-in-one limit is enforced.
        """
        url = '/api/all/260001/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data, {'error': 'The number you entered is very large. Please try a smaller number.'})
