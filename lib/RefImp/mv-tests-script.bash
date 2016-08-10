#!/bin/bash

for t in $(find . -name \*.t); do n=$(echo ${t} | sed 's#/#-#g' | sed 's#^.\-#../../t/#'); echo git mv ${t} ${n}; done
