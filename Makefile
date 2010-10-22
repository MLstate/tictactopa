# Tictactopa. (c) MLstate - 2010
# @author Mathieu Barbin

.PHONY: doc

OPA=s3opa.exe
SEPARATION=--separated -I $(MLSTATELIBS)/opa-packages

tictactopa=tictactopa.opack

all: tictactopa.exe

sep:
	$(OPA) $(OPAOPT) $(SEPARATION) $(tictactopa) -o tictactopa.exe

loop:
	while [ 1 ] ; do make -B all || true ; sleep 5 ; done

tictactopa.exe:
	$(OPA) $(OPAOPT) $(tictactopa) -o tictactopa.exe

doc:
	$(OPA) $(OPAOPT) $(tictactopa) --generate-interface
	opadoc.exe src multitub
