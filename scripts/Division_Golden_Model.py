import random

MASK32 = 0xFFFFFFFF # 32-bit wide mask for unsigned division results, python integers do not overflow so infinite this forces to behave like hardware

directed_test_vectors = [
    (0,1),
    (1,1),
    (1,2),
    (2,1),
    (0xFFFFFFFF,1),
    (0xFFFFFFFF,2),
    (0xFFFFFFFF,0xFFFFFFFF),
    (0xFFFFFFFF,0),   
]

def division_golden_model_unsigned(dividend, divisor):

    dividend = dividend & MASK32 # Ensure dividend is treated as 32-bit unsigned
    divisor = divisor & MASK32 # Ensure divisor is treated as 32-bit unsigned

    if divisor == 0:
        Quotient = 0xFFFF_FFFF & MASK32 # unsigned division Quotient div by zero condition
        Remainder = dividend & MASK32 # unsigned division by zero remainder condition
        return Quotient, Remainder
    else:
        Quotient = (dividend // divisor) & MASK32 # unsigned division Quotient
        Remainder = (dividend % divisor) & MASK32 # unsigned division Remainder

    return Quotient, Remainder

f = open("division_vectors.txt", "w")

f.write("Dividend  Divisor Quotient Remainder\n") # write header line to file

for dividend, divisor in directed_test_vectors: # for every vector in the directed test vector list, compute the quotient and remainder using the golden model and write to file
    quotient, remainder = division_golden_model_unsigned(dividend, divisor)
    f.write(f"{dividend:08X} {divisor:08X} {quotient:08X} {remainder:08X}\n")

    

for i in range(0,100000): # for 100000 random test vectors, compute the quotient and remainder using the golden model and write to file
    dividend = random.randint(0, 0xFFFFFFFF)
    divisor  = random.randint(0, 0xFFFFFFFF)

    quotient, remainder = division_golden_model_unsigned(dividend, divisor)
    f.write(f"{dividend:08X} {divisor:08X} {quotient:08X} {remainder:08X}\n")
    
f.close()