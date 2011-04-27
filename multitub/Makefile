# compile a simple example using multitub pattern
OPA=opa

SOURCES=multitub.opa hello_multitub.opa

all:hello_multitub.exe

hello_multitub.exe : $(SOURCES)
	$(OPA) $(OPAOPT) $(SOURCES)

clean:
	rm -f *.exe
	rm -rf _build _tracks
	rm -f *.log
