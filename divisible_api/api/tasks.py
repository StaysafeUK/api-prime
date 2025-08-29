from celery import shared_task

def is_prime(n):
    """Checks if a number is prime."""
    n = int(n)
    if n < 2:
        return False
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0:
            return False
    return True

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
    """Finds all divisors of a number n."""
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

