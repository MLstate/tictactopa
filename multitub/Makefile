# compile a simple example using multitub pattern
OPA=s3opa.exe

SOURCES=multitub.opa hello_multitub.opa

all:hello_multitub.exe

hello_multitub.exe : $(SOURCES)
	$(OPA) $(OPAOPT) $(SOURCES)
