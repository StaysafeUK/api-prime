
from django.http import JsonResponse
from .primenum3 import is_prime

def is_prime_api(request, number):
    result = is_prime(number)
    return JsonResponse({'number': number, 'is_prime': result})
