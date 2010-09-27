# Tictactopa. (c) MLstate - 2010
# @author Mathieu Barbin

OPA=s3opa.exe

tictactopa=tictactopa.opack

all: tictactopa.exe

main.exe:
	$(OPA) $(OPAOPT) $(tictactopa) -o tictactopa.exe
