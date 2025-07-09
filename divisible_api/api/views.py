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