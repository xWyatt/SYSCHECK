# Default Library:
BIN_LIB=SYSCHECK
DBGVIEW=*ALL

.PHONY: default all dspf rpg rpgle tosda fromsda dtaara clle
default: all


sysCheck.pgm: sysCheck.rpgle

dspf: sysCheck.dspf
rpgle: sysCheck.pgm
clle: sysCheckCL.clle

rpg: rpgle
all: dspf rpgle dtaara

tosda: sysCheck.tosda
fromsda: sysCheck.fromsda

dtaara:
	system "CRTDTAARA DTAARA($(BIN_LIB)/SYSCHECK) TYPE(*CHAR) LEN(59)"

%.clle:
	system "CRTBNDCL PGM($(BIN_LIB)/$*) SRCSTMF('./QCLLESRC/$*.clle') REPLACE(*YES)"

%.tosda:
	-system "CRTSRCPF FILE($(BIN_LIB)/QDDSSRC)"
	system "CPYFRMIMPF FROMSTMF('./QDDSSRC/$*.dspf') TOFILE($(BIN_LIB)/QDDSSRC $*) RMVBLANK(*TRAILING) RCDDLM(*ALL) MBROPT(*REPLACE)"
	system "CHGPFM FILE($(BIN_LIB)/QDDSSRC) MBR($*) SRCTYPE(DSPF)"

%.fromsda:
	system "CPYTOIMPF FROMFILE($(BIN_LIB)/QDDSSRC $*) TOSTMF('./QDDSSRC/$*.dspf') MBROPT(*REPLACE) RCDDLM(*CRLF) STRDLM(*NONE) RMVBLANK(*TRAILING)"

%.dspf:
	-system "CRTSRCPF FILE($(BIN_LIB)/TMP4CMPILE)"
	system "CPYFRMIMPF FROMSTMF('./QDDSSRC/$*.dspf') TOFILE($(BIN_LIB)/TMP4CMPILE $*) RMVBLANK(*TRAILING) RCDDLM(*ALL) MBROPT(*REPLACE)"
	system "CRTDSPF FILE($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/TMP4CMPILE) SRCMBR($*)" 
	-system "DLTF FILE($(BIN_LIB)/TMP4CMPILE)"

%.rpgle:
	system "CRTRPGMOD MODULE($(BIN_LIB)/$*) SRCSTMF('./QRPGLESRC/$*.rpgle') DBGVIEW($(DBGVIEW)) REPLACE(*YES)"

%.pgm:
	system "CRTPGM PGM($(BIN_LIB)/$*) MODULE($(patsubst %,$(BIN_LIB)/%,$(basename $^))) ENTMOD(*PGM) REPLACE(*YES)"
