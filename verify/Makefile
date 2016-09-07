# in Mega Elements (data type: integer)
SIZE=1

# random, sorted, reverse, xorshift
TYPE=reverse

all: 
	gcc -static -O3 -Wall -W merge.c -o merge

run: 
	./merge $(SIZE) $(TYPE)

dump:
	./merge $(SIZE) $(TYPE) > good.txt

diff:
	python verify.py
	diff -s good.txt test.txt

clean:
	rm -f merge quick *_flymake* bubble insertion selection *.txt teraterm.log
