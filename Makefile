# Tictactopa. (c) MLstate - 2010
# @author Mathieu Barbin

.PHONY: doc

OPA=s3opa.exe

tictactopa=tictactopa.opack

all: tictactopa.exe

tictactopa.exe:
	$(OPA) $(OPAOPT) $(tictactopa) -o tictactopa.exe

doc:
	$(OPA) $(OPAOPT) $(tictactopa) --generate-interface
	opadoc.exe src multitub
