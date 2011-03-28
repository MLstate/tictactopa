# Tictactopa. (c) MLstate - 2010-2011
# @author Mathieu Barbin

.PHONY: doc

OPA=opa.exe

opack=tictactopa.opack
conf=tictactopa.conf

tictactopa=$(opack) $(conf)

all: tictactopa.exe

tictactopa.exe:
	$(OPA) $(OPAOPT) $(tictactopa) -o tictactopa.exe

hello_grid.exe:
	$(OPA) $(OPAOPT) src/hello_grid.opa -o hello_grid.exe

doc:
	$(OPA) $(OPAOPT) $(tictactopa) --generate-interface
	opadoc.exe src multitub

clean:
	rm -rf *.opx
	rm -f *.exe
	rm -rf _build _tracks
	rm -f *.log
