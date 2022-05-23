all:
	bsc -verilog HelloWorld.bsv

run:
	bsc -o sim -e mkHelloModule mkHelloModule.v
	./sim

clean:
	rm -rf *.bo *.v sim* web* x*
