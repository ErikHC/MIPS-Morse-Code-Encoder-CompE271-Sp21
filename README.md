# MIPS-Morse-Code-Encoder-CompE271-Sp21
Using bitwise operations in MIPS to encode A-Z (upper and lower), 0-9, and '?' in International Morse code

## Background and Usage Basics
This project is specifically made for use in the MARS 4.5 (I use MARS 4.5.1) IDE. A video demonstration of the project can be found [here](https://www.youtube.com/watch?v=On-NI-TE1LI). This tool can take all standard input as input (the caveat being that symbols like '*', '(', '%', etc. will have garbage Morse Code outputs). The tool has both audio and symbolic output where '.' is "dit" and '-' is "dah". This tool also has the ability to (crudely) change the WPM speed to between integers 1 and 5 (it defaults at 1 so it's important that you change it).

My MIPS file has many of the usages and technical details commented in but to highlight the scheme that I use, this is a pretty useful comment:

>MCLookup Value Scheme:

0b10 encodes a "dit"

0b11 encodes a "dah"

>Bits are shifted to the RIGHT so the order is in reverse.

>Ex:	'A' is ".-"  which is 10 and 11, but '.' comes first so the value must be ordered as "11-10" (14 or 0xE).

Most importantly, this project relies heavily on the ASCII numbering system to obtain the index value for the Morse Code symbolic value (e.g. 1110 for 'A' as described earlier). For example, the ASCII values for 'A' and 'a' are 01000001 and 01100001 respectively. If you are saavy to the ASCII scheme, you probably know that the LSBs (bits #1-6 containing values 0-16) correspond to the order that alphabetical letters appear in the alphabet, notice how with 'A' or 'a' we have 0100000**1** and 0110000**1**. The only difference between them is bit #6 (32) so we can do one of two things: 1.) use a bitwise operator (e.g. AND with a mask like 0b11111) 2.) left-shift the identifier bits (27 places since MIPS uses 32-bit registers) out of existence and then right-shift the number back. To not have to deal with another variable, I just went with the second option (which probably has its drawbacks in one way or another but, for practicality, it works). After this, we finally have the index value 1 which will give us 0xE (A/a/.-) in our lookup table! Dit-dah! (That was a "Ta-da" joke... sorry)

"Well what about 0-9 and '?' since they have more arbitrary numbering conventions" you ask? ...Well, I'll leave that to my [report on Google Docs](https://docs.google.com/document/d/1AIigjFuADEqdseeRCFAoilsbMI8Fc2Hj9CDM2NY0fok/edit?usp=sharing) (see pg. #9 for details) since the scheme is a bit of an arithmetic number soup but it *is* closely related to the stuff I described above.
