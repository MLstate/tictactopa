# Tictactopa. (c) MLstate - 2010
# @author Mathieu Barbin

.PHONY: doc

OPA=opa.exe

tictactopa=tictactopa.opack
conf=tictactopa.conf

all: tictactopa.exe

# for compiling under emacs, like an ide for poor
loop:
	while [ 1 ] ; do make -B all || true ; sleep 5 ; done

tictactopa.exe:
	$(OPA) $(OPAOPT) $(tictactopa) -o tictactopa.exe

doc:
	$(OPA) $(OPAOPT) $(tictactopa) --generate-interface
	opadoc.exe src multitub

clean:
	rm -rf *.opx
	rm tictactopa.exe
