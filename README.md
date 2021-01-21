# SYSCHECK -- For the IBM i                                                                                                                                                                                                                                                                                                                                                                                               
An RPG program that returns current and previous DASD and CPU usage via the QWCRSSTS API

This program was just an exercise for me to:
- Utilize a Makefile to compile DDS source from the IFS
- Call an IBM API
- Create and interface with display files

I use something similar at our company to monitor the DASD usage of our system via Nagios. In that case Nagios hits an API endpoint (created with Node.JS) that calls the RPG program.

## Overview
The program returns DASD and CPU usage from three time intervals:
- Right now (when you call the program)
- Five minutes ago
- From the beginning of the day (after midnight)

I use a similar program (in conjunction with a Node.JS API and Nagios) to send alerts if our DASD usage exceeds a certain percent, exceeds a certain percentage increase over 5 minutes, or exceeds a certain percentage increase since the beginning of the day.

The program is meant to be called at regular intervals, every day, and the results monitored.

The program stores its information in a data area that is updated with the '5 minutes ago' time every five minutes and the 'Beginning of day' at the beginning of the day (just after midnight) - hence why it should be called at regular intervals.


## Compiling
1. Make sure you have basic Open Source things setup on the IBM i, including:
	- An SSH daemon (Optional)
	- A package manager (`yum`)
	- The `make` package

2. Download the source code and save it on the IFS
3. SSH into the i and `cd` into the source code you stored on the IFS (or use QShell - not tested but that should work too)
4. Run `make BIN_LIB=<library>` where `<library>` is the library you want the source compiled into

 You can alternatively copy the source code into a source physical file and compile as you wish.
 
## Usage
The program can be called in two ways:
1. Interactively with a display file
2. Non-interactively - this will return 6 variables that contain the DASD and CPU usage 

The first parameter is what controls if the display file will be used or not. This parm is 1 character; `'N'` will call the program with the display file and `'Y'` will return 6 parms (after the `'Y'`).

Called non-interactively you can expect the following parms:
1. `Char(1)` - This controls if the program uses the display file. `'Y'` for no display file, `'N'` for display file
2. `Char(26)` - A character version of a `TIMESTAMP` which represents the last time the data area was updated
3. `Zoned(6:4)`* - Current DASD usage (%)
4. `Zoned(6:4)`* - DASD usage 5 minutes ago (%)
5. `Zoned(6:4)`* - DASD usage at the beginning of the day (%)
6. `Zoned(3:1)`* - Current CPU usage (%)
7. `Zoned(3:1)`* - CPU usage 5 minutes ago (%)
8. `Zoned(3:1)`* - CPU usage at the beginning of the day (%)

\* - If these values haven't been instantiated yet they will return as `-1`

### Example Usage
```bash
# Call interactively 
CALL SYSCHECK
# - or -
CALL SYSCHEK PARM('N')
```
```bash
# Called non-interactively
CALL SYSCHECK PARM('Y')
```  

## Examples
Included is a super basic CL program (`SYSCHECKCL`) that calls the program non-interactively and returns the data in a program message.                                                                                                                                                                                                                                                                                                                                                                                                                          
