SRC = Videx\ Videoterm\ ROM 2.4.s

all: Videx\ Videoterm\ ROM\ 2.4.s-generated.bin
	@echo Done.

%.o:
	ca65 --target apple2 -o "$@" Videx\ Videoterm\ ROM\ 2.4.s

%.bin:	Videx\ Videoterm\ ROM\ 2.4.o
	ld65 --config apple2-asm.cfg -o Videx\ Videoterm\ ROM\ 2.4-generated.bin "$<"

clean:
	rm -f Videx\ Videoterm ROM\ 2.4-generated.bin *.o
