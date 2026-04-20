# TODO: We need to import `profile` and use it to
# decorate the function which we want to profile 

def is_prime(number):
    print(f"Checking whether {number} is prime ...")
    if number < 2:
        return False
    for i in range(2, int(number**0.5) + 1):
        if number % i == 0:
            return False
    return True
    
print(is_prime(1087))
