from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class DivisibleView(APIView):
    """
    API view to check if a number is divisible by another number.
    """
    def get(self, request, number, range_limits):
        try:
            number= int(number)
            range_limit = int(range_limit)
            if number == 0:
                return Response({"error": "Number cannot be zero."}, status=status.HTTP_400_BAD_REQUEST)
            
            divisibles = [i for i in range(1, range_limit + 1) if i % number == 0]
            return Response({"divisibles": divisibles})
        except ValueError:
            return Response({"error": "Invalid input. Please provide valid integers."}, status=status.HTTP_400_BAD_REQUEST)
# Create your views here.
