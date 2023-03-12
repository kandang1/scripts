#!/usr/local/bin/python3
# Author: Dan Kang

""" simple script to calculate the return based on APY
"""

def calculateMonthlyInterestRatetoDecimal(apy):
  return (apy/100)/12

def convertMonthlyRatetoDecimal(apy):
  return apy*100

def askInputs(printtext):
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

APY = askInputs('What is the APY ? ')
PRINCIPAL = askInputs('What is the principal amount ? ')

# Calculate and print monthly interest rate
print(f"\nBased on an APY of {APY} and a principal amount of {PRINCIPAL}, the monthly interest rate in decimal is :", calculateMonthlyInterestRatetoDecimal(APY))
# Convert and print the monthly rate back into percentage
monthlyInterest = calculateMonthlyInterestRatetoDecimal(APY) * PRINCIPAL
print(f"\nThe monthly interest gained is: $",round(monthlyInterest,2), " per month",sep='')
print(f"\nThe monthly interest rate is: ",round(calculateMonthlyInterestRatetoDecimal(APY)*100,2), "% per month",sep='')
