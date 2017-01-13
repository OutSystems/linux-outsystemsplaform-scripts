#!/bin/bash
rm -rf res

python jstack_parser.py $1

mkdir res

cd threads

# delete byproducts of the parser
# this is the preamble of the stack trace files
rm -f dummy_*

for d in *; do
  for x in "$d"/*; do
    echo "$x" >> "../res/$d"
    cat "$x" >> "../res/$d"
  done
done

cd ..
rm -rf threads
# replace the temporary directory with the processed one
mv res threads

