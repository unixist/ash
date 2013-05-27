all: ash

ash: ash.o
	ld ash.o -o ash

ash.o: ash.s
	as ash.s built_in.s util.s -o ash.o
