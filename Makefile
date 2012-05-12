# Tictactopa. (c) MLstate - 2010-2011
# @author Mathieu Barbin

.PHONY: doc

OPA=opa
OPAOPT=--parser classic
OPADOC=opadoc

tictactopa=tictactopa.opack

all: tictactopa.exe

tictactopa.exe:
	$(OPA) $(OPAOPT) $(tictactopa) -o tictactopa.exe

hello_grid.exe:
	$(OPA) $(OPAOPT) src/hello_grid.opa -o hello_grid.exe

doc:
	$(OPA) $(OPAOPT) $(tictactopa) --api -o tictactopa.exe
	$(OPADOC) src multitub -o doc

clean:
	rm -rf *.opx *.opx.broken
	rm -f *.exe
	rm -rf _build _tracks
	rm -f *.log
	rm -f *.apix
