from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

def find_divisors(n):
    """Finds all divisors of a number n."""
    divisors = set()
    for i in range(1, int(n**0.5) + 1):
        if n % i == 0:
            divisors.add(i)
            divisors.add(n//i)
    return sorted(list(divisors))

class DivisibleView(APIView):
    """
    API view to find the factors of a given number.
    """
    def get(self, request, number):
        try:
            number = int(number)
            if number <= 0:
                return Response({"error": "Please enter a positive number to find its divisors."}, status=status.HTTP_400_BAD_REQUEST)
            if number > 99999999999999999:
                return Response({"error": "The number you entered is very large. Please try a smaller number."}, status=status.HTTP_400_BAD_REQUEST)
            
            factors = find_divisors(number)
            return Response({"factors": factors})
        except ValueError:
            return Response({"error": "Invalid input. Please provide a valid integer."}, status=status.HTTP_400_BAD_REQUEST)

class PrimeListView(APIView):
    """
    API view to get a list of prime numbers.
    """
    def get(self, request, number):
        try:
            number = int(number)
            if number <= 0:
                return Response({"error": "Please enter a positive number to get that many primes."}, status=status.HTTP_400_BAD_REQUEST)
            if number > 260000:
                return Response({"error": "You requested a very long list of prime numbers. Please try a smaller number."}, status=status.HTTP_400_BAD_REQUEST)
            
            primes = []
            num = 2
            while len(primes) < number:
                is_prime = True
                for i in range(2, int(num**0.5) + 1):
                    if num % i == 0:
                        is_prime = False
                        break
                if is_prime:
                    primes.append(num)
                num += 1
            return Response({"primes": primes})
        except ValueError:
            return Response({"error": "Invalid input. Please provide a valid integer."}, status=status.HTTP_400_BAD_REQUEST)

class NextPrimeView(APIView):
    """
    API view to get the next prime number.
    """
    def get(self, request, number):
        try:
            number = int(number)
            if number < 0:
                return Response({"error": "Please enter a non-negative number to find the next prime."}, status=status.HTTP_400_BAD_REQUEST)
            
            num = number + 1
            while True:
                is_prime = True
                for i in range(2, int(num**0.5) + 1):
                    if num % i == 0:
                        is_prime = False
                        break
                if is_prime:
                    return Response({"next_prime": num})
                num += 1
        except ValueError:
            return Response({"error": "Invalid input. Please provide a valid integer."}, status=status.HTTP_400_BAD_REQUEST)

class PreviousPrimeView(APIView):
    """
    API view to get the previous prime number.
    """
    def get(self, request, number):
        try:
            number = int(number)
            if number <= 2:
                return Response({"error": "There are no prime numbers smaller than the one you entered. Please try a larger number." }, status=status.HTTP_400_BAD_REQUEST)
            
            num = number - 1
            while True:
                is_prime = True
                for i in range(2, int(num**0.5) + 1):
                    if num % i == 0:
                        is_prime = False
                        break
                if is_prime:
                    return Response({"previous_prime": num})
                num -= 1
        except ValueError:
            return Response({"error": "Invalid input. Please provide a valid integer."}, status=status.HTTP_400_BAD_REQUEST)

class AllInOneView(APIView):
    """
    API view to get all the results from the other APIs.
    """
    def get(self, request, number):
        try:
            number = int(number)
            if number <= 0:
                return Response({"error": "Please enter a positive number."}, status=status.HTTP_400_BAD_REQUEST)
            if number > 260000:
                return Response({"error": "The number you entered is very large. Please try a smaller number."}, status=status.HTTP_400_BAD_REQUEST)

            # Divisible
            factors = find_divisors(number)

            # Prime List
            primes = []
            num = 2
            while len(primes) < number:
                is_prime = True
                for i in range(2, int(num**0.5) + 1):
                    if num % i == 0:
                        is_prime = False
                        break
                if is_prime:
                    primes.append(num)
                num += 1

            # Next Prime
            next_prime_num = number + 1
            while True:
                is_prime = True
                for i in range(2, int(next_prime_num**0.5) + 1):
                    if next_prime_num % i == 0:
                        is_prime = False
                        break
                if is_prime:
                    next_prime = next_prime_num
                    break
                next_prime_num += 1

            # Previous Prime
            previous_prime = None
            if number > 2:
                prev_prime_num = number - 1
                while prev_prime_num > 1:
                    is_prime = True
                    for i in range(2, int(prev_prime_num**0.5) + 1):
                        if prev_prime_num % i == 0:
                            is_prime = False
                            break
                    if is_prime:
                        previous_prime = prev_prime_num
                        break
                    prev_prime_num -= 1

            return Response({
                "divisible": factors,
                "list": primes,
                "prime_next": next_prime,
                "prime_prev": previous_prime
            })
        except ValueError:
            return Response({"error": "Invalid input. Please provide a valid integer."}, status=status.HTTP_400_BAD_REQUEST)

import logging

logger = logging.getLogger(__name__)

class HealthCheckView(APIView):
    """
    A simple view for the load balancer health check.
    This is a test comment to trigger the workflow.
    This is another test comment.
    This is a third test comment.
    This is a fourth test comment.
    This is a fifth test comment.
    This is a sixth test comment.
    This is a seventh test comment.
    """
    def get(self, request):
        try:
            logger.info("Health check endpoint called successfully.")
            return Response(status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return Response(status=status.HTTP_500_INTERNAL_SERVER_ERROR)