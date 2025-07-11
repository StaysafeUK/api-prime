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