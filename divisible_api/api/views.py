from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class DivisibleView(APIView):
    """
    API view to find the factors of a given number.
    """
    def get(self, request, number):
        try:
            number = int(number)
            if number <= 0:
                return Response({"error": "Number must be a positive integer."}, status=status.HTTP_400_BAD_REQUEST)
            
            factors = [i for i in range(1, number + 1) if number % i == 0]
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
                return Response({"error": "Number must be a positive integer."}, status=status.HTTP_400_BAD_REQUEST)
            
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
                return Response({"error": "Number must be a non-negative integer."}, status=status.HTTP_400_BAD_REQUEST)
            
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
                return Response({"error": "No prime number less than the given number."}, status=status.HTTP_400_BAD_REQUEST)
            
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