import numpy as np
x = [1,2,3]
y = [x, x, x]
print(x)
print(y)
x[1] += 1 
y[2] = [4,4,4]
print(y)
x[2] = 0
print(y)
produkt = 1
for i in range (len(y)):
    produkt *= y[i][i]
print(produkt)
