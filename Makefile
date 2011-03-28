# Tictactopa. (c) MLstate - 2010-2011
# @author Mathieu Barbin

.PHONY: doc

OPA=opa.exe
OPADOC=opadoc-gen.exe

tictactopa=tictactopa.opack

all: tictactopa.exe

tictactopa.exe:
	$(OPA) $(OPAOPT) $(tictactopa) -o tictactopa.exe

hello_grid.exe:
	$(OPA) $(OPAOPT) src/hello_grid.opa -o hello_grid.exe

doc:
	$(OPA) $(OPAOPT) $(tictactopa) --generate-interface-and-compile -o tictactopa.exe
	$(OPADOC) src multitub

clean:
	rm -rf *.opx *.opx.broken
	rm -f *.exe
	rm -rf _build _tracks
	rm -f *.log
	rm -f *.apix
