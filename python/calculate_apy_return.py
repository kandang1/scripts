#!/usr/bin/env python3
# Author: Dan Kang

""" script to calculate the return based on APY
"""

import decimal

MONTHS = [ 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' ]

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
INITIAL_PRINCIPAL = PRINCIPAL

def compound_monthly(apy,principal,month):
#add the principal to the monthly interest and return that new number
  interestEarned = (apy*principal)+principal
  print(f'For the month of {month}, your account balance is', round(interestEarned,2))
  return MONTHLY_COMPOUNDED_BALANCES.append(interestEarned)

# Calculate and print monthly interest rate
print(f"\nBased on an APY of {APY} and a principal amount of {PRINCIPAL}, the monthly interest rate in decimal is :", calculate_monthly_interest_rate_to_decimal(APY)) # pylint: disable=line-too-long
# Convert and print the monthly rate back into percentage
monthlyInterest = calculate_monthly_interest_rate_to_decimal(APY) * PRINCIPAL
print("\nThe monthly interest gained without rounding is: $",monthlyInterest, " per month",sep='')

print("\nThe monthly interest gained is: $",round(monthlyInterest,2), " per month",sep='')
print("\nThe monthly interest rate is: ",round(calculate_monthly_interest_rate_to_decimal(APY)*100,2), "% per month",sep='') # pylint: disable=line-too-long

# Now compound it 12 times to get the total for 12 months / 1 year
MONTHLY_COMPOUNDED_BALANCES = []
MONTHLY_COMPOUNDED_BALANCES.append(PRINCIPAL)
cents = decimal.Decimal('.01')

for i in range(12):
  compound_monthly(calculate_monthly_interest_rate_to_decimal(APY),MONTHLY_COMPOUNDED_BALANCES[i],MONTHS[i])

FINAL_SUM = MONTHLY_COMPOUNDED_BALANCES[-1]
rounded_sum = decimal.Decimal(FINAL_SUM)

print(f'\nYour total balance after one year with an initial investment compounded monthly of', MONTHLY_COMPOUNDED_BALANCES[1]-monthlyInterest, f'and APY of {APY} is ${rounded_sum.quantize(cents,decimal.ROUND_HALF_UP)}')
