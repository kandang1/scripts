#!/usr/local/bin/python3
# Author: Dan Kang

""" simple script to calculate the return based on APY
"""

def calculate_monthly_interest_rate_to_decimal(apy):
    """ Returns the monthly interest rate based on the apy input"""
    return (apy/100)/12

def ask_inputs(printtext):
    """ Function that asks a user for input and validates that its a float (or int) """
    while True:
        try:
            inputs = float(input(printtext))
            if inputs > 0 and isinstance(inputs,float):
                return inputs
                break
            else:
                print('Invalid input. Enter a positive numeric.')
        except ValueError:
            print('Invalid input. Enter a positive numeric.')

APY = ask_inputs('What is the APY ? ')
PRINCIPAL = ask_inputs('What is the principal amount ? ')

# Calculate and print monthly interest rate
print(f"\nBased on an APY of {APY} and a principal amount of {PRINCIPAL}, the monthly interest rate in decimal is :", calculate_monthly_interest_rate_to_decimal(APY)) # pylint: disable=line-too-long
# Convert and print the monthly rate back into percentage
monthlyInterest = calculate_monthly_interest_rate_to_decimal(APY) * PRINCIPAL
print("\nThe monthly interest gained is: $",round(monthlyInterest,2), " per month",sep='')
print("\nThe monthly interest rate is: ",round(calculate_monthly_interest_rate_to_decimal(APY)*100,2), "% per month",sep='') # pylint: disable=line-too-long
