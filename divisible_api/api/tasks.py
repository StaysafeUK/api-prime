from celery import shared_task
import random

def is_prime(n):
    """
    Checks if a number is prime using the Miller-Rabin primality test.
    This is a probabilistic test, but highly accurate for large numbers.
    """
    n = int(n)
    if n < 2:
        return False
    if n == 2 or n == 3:
        return True
    if n % 2 == 0 or n % 3 == 0:
        return False

    d = n - 1
    s = 0
    while d % 2 == 0:
        d //= 2
        s += 1

    # Run the test k times for better accuracy
    k = 5 
    for _ in range(k):
        a = random.randrange(2, n - 1)
        x = pow(a, d, n)
        if x == 1 or x == n - 1:
            continue
        for _ in range(s - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    return True

@shared_task
def find_divisors_task(number):
    """Celery task to find all divisors of a number."""
    return find_divisors(number)

@shared_task
def check_prime_task(number):
    """Celery task to check if a number is prime."""
    return is_prime(number)

@shared_task
def prime_list_task(number):
    """Celery task to get a list of prime numbers."""
    primes = []
    num = 2
    while len(primes) < number:
        if is_prime(num):
            primes.append(num)
        num += 1
    return primes

def find_divisors(n):
    """
    Finds all divisors of a number n.
    Note: This will be slow for very large numbers with large prime factors.
    """
    n = int(n)
    divisors = set()
    for i in range(1, int(n**0.5) + 1):
        if n % i == 0:
            divisors.add(i)
            divisors.add(n//i)
    return sorted(list(divisors))

@shared_task
def next_prime_task(number):
    """Celery task to find the next prime number."""
    number = int(number)
    num = number + 1
    while True:
        if is_prime(num):
            return num
        num += 1

@shared_task
def previous_prime_task(number):
    """Celery task to find the previous prime number."""
    number = int(number)
    num = number - 1
    while num > 1:
        if is_prime(num):
            return num
        num -= 1
    return None

@shared_task
def all_in_one_task(number):
    """Celery task to get all the results from the other APIs."""
    number = int(number)
    # Divisible
    factors = find_divisors(number)

    # Prime List
    primes = prime_list_task(number)

    # Next Prime
    next_prime = next_prime_task(number)

    # Previous Prime
    previous_prime = previous_prime_task(number)

    return {
        "divisible": factors,
        "list": primes,
        "prime_next": next_prime,
        "prime_prev": previous_prime
    }

