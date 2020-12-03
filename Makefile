# Default Library:
BIN_LIB=DASDCHEK
DBGVIEW=*ALL

.PHONY: default all dspf rpg rpgle
default: all


dasdcheck.pgm: dasdcheck.rpgle

dspf: dasdcheck.dspf
rpgle: dasdcheck.pgm

rpg: rpgle
all: dspf rpgle

%.dspf:
	-system "CRTSRCPF FILE($(BIN_LIB)/TMP4CMPILE)"
	system "CPYFRMIMPF FROMSTMF('./QDDSSRC/$*.dspf') TOFILE($(BIN_LIB)/TMP4CMPILE $*) RMVBLANK(*TRAILING) RCDDLM(*ALL) MBROPT(*REPLACE)"
	system "CRTDSPF FILE($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/TMP4CMPILE) SRCMBR($*)" 
	-system "DLTF FILE($(BIN_LIB)/TMP4CMPILE)"

%.rpgle:
	system "CRTRPGMOD MODULE($(BIN_LIB)/$*) SRCSTMF('./QRPGLESRC/$*.rpgle') DBGVIEW($(DBGVIEW)) REPLACE(*YES)"

%.pgm:
	system "CRTPGM PGM($(BIN_LIB)/$*) MODULE($(patsubst %,$(BIN_LIB)/%,$(basename $^))) ENTMOD(*PGM) REPLACE(*YES)"
