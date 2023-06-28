SRC = Videx_Videoterm_ROM 2.4.s

all: Videx_Videoterm_ROM_2.4-generated.bin
	@echo Done.

%.o: %.s
	ca65 --target apple2 -o "$@" "$<"

%-generated.bin: %.o
	ld65 --config apple2-asm.cfg -o "$@" "$<"

clean:
	rm -f Videx_Videoterm_ROM_2.4-generated.bin *.o
