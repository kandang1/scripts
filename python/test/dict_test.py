#!/usr/bin/python3.9

import json

dict1 = {
  'meta-hostgroups': {
    'git': [ 'a', 'b', 'c', 'd', 'e'],
    'jira': [ 'f', 'g', 'h', 'a', 'b' ],
   },
  'test_key1_dict1': [ 'test_value_dict1' ],
  'test_key2_dict1': [ 'test_value_2_dict1' ],
}

dict2 = {
  'meta-hostgroups': {
    'git': [ 'a', 'b', 'c', 'd', 'e', 'DICT2_GIT', 'UNIQUE_VALUE_TO_DICT_2'],
    'jira': [ 'f', 'g', 'h', 'a', 'b', 'DICT2_JIRA' ],
   },
  'test_key1_dict1': [ 'test_value_dict1', 'DICT2_TEST_KEY1' ],
  'test_key2_dict1': [ 'test_value_2_dict2', 'DICT2_TEST_KEY2_DICT_2', 'some_unique_value_to_second_dict' ],
}

d = {}
#union dicts

d |= dict1

# all keys in a dict are a string
print('dict 1 is:')
print(json.dumps(dict1, indent=4, sort_keys=True))

print('dict 2 is:')
print(json.dumps(dict2, indent=4, sort_keys=True))

for key,value in dict2.items():
  if isinstance(value, dict):
    print('key is', key, 'and value', value, 'is a dictionary')
    if key in dict1:
      if key in dict2:
        print('dict 2 has the key', key, 'as well')
        if value not in dict1.items():
          print('value', value, 'NOT PRESENT in dict1')
          d[key] = value
  elif isinstance(value, list):
    print('key is', key, 'and value', value, 'is a list')
    for item in value:
      print('on the key', key)
      print('the value in this list is', value, 'and the item is', item)
  elif isinstance(value, list):
    print('key is', key, 'and value', value, 'is a list')
  else:
    print('passed on classifying', type(value), 'for key', key)
  

print('the dictionary D is:\n')
print(json.dumps(d, indent=4, sort_keys=True))
