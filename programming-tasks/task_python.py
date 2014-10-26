#!/bin/env python

import itertools
import collections
import re

array = [['a','b','c'],['d','e','f']]
print(array)
array_flat = itertools.chain.from_iterable(array)
for a in array_flat: print a

brands = collections.Counter()
file = open('top10_sample.csv', 'r')
for row in file:
  words = re.sub(r'^\"\[|^\[|\]\"$|\]$', '', row.rstrip()).split(',')
  for word in words:
    brands[word] += 1
for b in sorted(brands, key=brands.get, reverse=True):
  print "Band : %s - Count = %d" % (b, brands[b])
