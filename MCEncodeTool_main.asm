# Author:	Erik Chavarin
# Date:		Apr 28, 2021
# Description:	Morse Code Encoding Tool takes an alphabetic (ASCII) input 
#		string and encodes each character to Morse Code. Each cha-
#		acter has a corresponding lookup table value that contains
#		a combination of dits and dahs encoded in binary. The dits
#		and dahs are printed and sounded to output according to d-
#		efined conventions which are played at a specified WPM.

.data

MCLookup:	.word 14, 171, 187, 43, 2, 186, 47, 170,	# A-Z correspond to indices 0-25
		10, 254, 59, 174, 15, 11, 63, 190, 239, 
		46, 42, 3, 58, 234, 62, 235, 251, 175, 2810,	# '?' is index 26
		1023, 1022, 1018, 1002, 938, 682, 683, 687, 	# 0-9 correspond to indices 27-36
		703, 767
		
# MCLookup Value Scheme:
#	0b10 encodes a "dit"
#	0b11 encodes a "dah"
#	*Bits are shifted to the RIGHT so the order is in reverse.
#
# Ex:	'A' is ".-"  which is 10 and 11, but 
#	'.' comes first so the value must be ordered as
#	"11-10" (14 / 0xE).

# International Morse Code Spacing Convetions (Modified for MARS output):
#	DIT..................1 unit	(Standard)	(MIDI)		1200ms
#	DAH..................3 units	(Standard)	(MIDI)		3600ms
#	Element Space (DIT)..1.25 units	(MARS)		(Sleep)		1500ms
#	Element Space (DAH)..3.2 units	(MARS)		(Sleep)		3800ms
#	Char Space...........3 unit	(Standard)	(Sleep)		3600ms
#	Word Space...........7 units	(Standard)	(Sleep)		8400ms
# WPM calculation is based on https://morsecode.world/international/timing.html
		

# Prompts
greet:		.asciiz "Welcome to Erik's Morse Code Encoding Tool!\n\n"
promptWPM:	.asciiz "Select desired WPM (1-5, default 1): "
promptPhrase:	.asciiz "Enter your favorite phrase or sentence:\n"

# Characters
nl:		.asciiz "\n"
DIT:		.asciiz "."
DAH:		.asciiz "-"
space:		.asciiz " "
slash:		.asciiz "/"
unknown: 	.asciiz "?"

userInput:	.space 50		#	#define MAX 50

# Register & Variable Guide
#
#	char userInput[MAX]
#
#	$s0 - the index 'i' in UserInput[i] -- basically a counter
#	$s1 - Holds ASCII value of userInput[i] -- basically uint8_t mcltIndex
#	$s2 - uint8_t mcltIndex
#	$s3 - int MCVal, i.e. MCLookup[mcltIndex]
#	$s4 - short ditDah (Holds either 2 or 3 for dit and dah)
#	$s5 - int WPM
#	
#	$t0 - bool isWordSpace = false
#	$t1 - bool isDigit
#	$t2 - bool isUnknown = false

# Stack Frame
#	-4:  Stores return address to main
#	-8:  Stores uint8_t mcltIndex
#	-12: Stores int MCVal
#	-16: Stores return address to Traverse
#	-20: Stores short ditDah
#	-24: Stores return address to AsciiParse


.text

main:					# int Main (void)
	li	$v0, 4			# {
	la	$a0, greet		#	print(*prompts*)
	syscall				#	Set_WPM()
	li	$v0, 4			#	fgets(userInput, MAX, stdin)
	la	$a0, promptWPM		#	Traverse(userInput)
	syscall				#
	jal	Set_WPM			#	return(0); // exit success
	jal	NewLine			# }
	
	li	$v0, 4
	la	$a0, promptPhrase
	syscall
	
	li	$v0, 8
	la	$a0, userInput
	li	$a1, 50
	syscall
	jal	NewLine

	jal	Traverse
	

	li	$v0, 10			# Exit
	syscall


Traverse:				# void Traverse(char userInput)
	sw	$ra, -4($sp)		# {
					#	for (int i = 0; i < strlen(userInput) - 1; i++)
	lbu	$s1, userInput($s0)	# 	{
					#		mcltIndex = get_ASCII(userInput[i])
	beq	$s1, 10, Done		# 		AsciiParse(mcltIndex) // mcltIndex means “MC Lookup Table Index”
	beq	$s1, 0, Done		# 		Spacing()
					#		isUnknown = false
	sw	$s1, -8($sp)		# 	}
					#	return;	// Returns to main
	jal	AsciiParse
	jal	Spacing
	lw	$ra, -4($sp)
	li	$t2, 0
	
	addi	$s0, $s0, 1
	j Traverse

	Done:	
	lw	$ra, -4($sp)
	jr	$ra
	

AsciiParse:				# void AsciiParse(uint8_t mcltIndex)
	lw	$s2, -8($sp)		# {
					#	if (isDigit(mcltIndex)) //
	sw	$ra, -16($sp)		# 	{
	jal	isDigit			# 		CheckBound(mcltIndex)
	lw	$ra, -16($sp)		#		mcltIndex -= 1
					#		MCVal = MCLookup[mcltIndex] // MIPS: (mcltIndex * 4) since it’s a WORD
	beq	$t1, 1, NumBreak	#		CalcDitDah(MCVal)
					#		return() // returns to Traverse
	sll	$s2, $s2, 27		#	}
	srl	$s2, $s2, 27		# 	else
					#	{
					#		mcltIndex <<= 27
	NumBreak:			#		mcltIndex >>= 27 // Removes alpha identifier bits
	li	$t1, 0			# 		CheckBound(mcltIndex)
					#		if (isWordSpace || isUnknown)
	jal	CheckBound		# 		{
	lw	$ra, -16($sp)		#			return()
					#		}
	beq	$t0, 1, ParseDone	# 		else
	beq	$t2, 1, ParseDone	#		{
					#			MCVal = MCLookup[mcltIndex]
	subi	$s2, $s2, 1		#			CalcDitDah(MCVal)
	mul	$s2, $s2, 4		#			return()
	lw	$s3, MCLookup($s2)	#		}
					#	}
	sw	$s3, -12($sp)		# }
					#
	jal	CalcDitDah		#
	lw	$ra, -16($sp)		#
	
	ParseDone:
	jr	$ra
	
	
isDigit:				# bool IsDigit(uint8_t mcltIndex) // Modifies the argument but returns as a bool
	and	$t1, $s2, 64		# {
	beq	$t1, 64, CharSorted	#	if (isAlpha(mcltIndex) || isSpace(mcltIndex))
	xor	$t1, $s2, 32		#	{
	beq	$t1, 0, CharSorted	#		return(false) // Returns to AsciiParse
					#	}
	xor	$s2, $s2, 16		#	else
	addi	$s2, $s2, -4		# 	{
	li	$t1, 1			#		mcltIndex ^= 16 
					#		mcltIndex -= 4 // makes the digit index 28-37
	CharSorted:			#		return(true)
	jr	$ra			# 	}
					# }
	
	
CheckBound:				# void CheckBound(uint8_t mcltIndex)
	bgt	$s2, 0, check37		# {
	j	outOfBounds		#	if (mcltIndex > 0 && mcltIndex < 38)
					# 	{
	check37:			#		return() // Returns to AsciiParse
	ble	$s2, 37, BoundChecked	#	}
					#	else if (mcltIndex == 0)
	outOfBounds:			#	{
	beq	$s2, 0, Space		#		print(‘/‘)
	beq	$s2, 43, QMark		#		isWordSpace = true
					#		return()
	b	PastRange		#	}
					#	else if (mcltIndex == ‘43’) // 43 is a result of ‘?’ falling thru the isDigit calculation
	Space:				#	{
	li	$v0, 4			#		mcltIndex = 27
	la	$a0, slash		#		return()
	syscall				#	}
	li	$t0, 1			#	else // PastRange
	j	BoundChecked		#	{
					#		print(‘?’)
	QMark:				#		isUnknown = true
	li	$s2, 27			#		return()
	j	BoundChecked		#	}
					# }

	PastRange:
	la	$a0, unknown
	li	$v0, 4
	syscall
	li	$t2, 1
	
	BoundChecked:
	jr	$ra
	


CalcDitDah:				# void CalcDitDah(int MCVal)
	lw	$s3, -12($sp)		# {
					#	while (MCVal != 0)
	while:				#	{
	beq	$s3, 0, AtZero		# 		ditDah = MCVal & 3 // magic number 3!
	and	$s4, $s3, 3		#		OutputDIT_Dah (ditDah)
					#		MCVal >> 2
	sw 	$s4, -20($sp)		#	}
					# 	return() // Returns to AsciiParse
	sw	$ra, -24($sp)		# }
	jal	OutputDIT_DAH
	lw	$ra, -24($sp)


	srl	$s3, $s3, 2
	j	while

	AtZero:
	jr	$ra
	
	
OutputDIT_DAH:				# void OutputDIT_DAH(short ditDah)
	lw	$s4, -20($sp)		# {
	beq	$s4, 3, Dah		#	if (ditDah == 3)
					#	{
	Dit:				#		print(‘-’)
	la	$a0, DIT		#		MIDI_DAH(WPM) // Assume this function is part of a library
	li	$v0, 4			#		return() // Returns to CalcDitDah
	syscall				#	}
					#	else
	li	$v0, 31			#	{
	li	$a0, 60			#		print(‘.’)
	li	$a1, 1200		#		MIDI_DIT(WPM) // includes element space as well
	div	$a1, $a1, $s5		#		return()
	li	$a2, 20			#	}
	li	$a3, 100		# }
	syscall
	li	$v0, 32			# Element Space
	li	$a0, 1500
	div	$a0, $a0, $s5
	syscall
	
	jr	$ra
		
	Dah:
	la	$a0, DAH
	li	$v0, 4
	syscall
	
	li	$v0, 31	
	li	$a0, 60
	li	$a1, 3600
	div	$a1, $a1, $s5
	li	$a2, 20			# Organ (20)
	li	$a3, 100
	syscall
	li	$v0, 32
	li	$a0, 3800
	div	$a0, $a0, $s5
	syscall
	
	jr	$ra
	
	
Spacing:				# void Spacing(void)
	beq	$t0, 1, WordSpace	# {
					#	if (isWordSpace)
	li	$v0, 4			#	{
	la	$a0, space		#		print(‘ ‘)
	syscall				#		sleep( 7 units )
					#		isWordSpace = false
	li	$v0, 32			#		return() // Returns to Traverse
	li	$a0, 3600		#	}
	div	$a0, $a0, $s5		#	else
	syscall				#	{
	jr	$ra			#		print(‘ ‘)
					#		sleep( 3 units ) // char space
	WordSpace:			#	}
	li	$v0, 4			# }
	la	$a0, space
	syscall
	li	$v0, 32
	li	$a0, 8400
	div	$a0, $a0, $s5
	syscall
	li	$t0, 0
	jr	$ra


NewLine:
	la	$a0, nl			# print('\n')
	li	$v0, 4			# return(); (to main)	
	syscall
	jr	$ra


Set_WPM:				# void Set_WPM(void)
	li	$v0, 12			# {
	syscall				#	WPM = get_int()
	sll 	$s5, $v0, 28		# 	if (!(WPM > 0 && WPM < 6))
	srl	$s5, $s5, 28		#	{
					#		WPM = 1
	blt	$s5, 1, WPMDefault	#	}
	bgt	$s5, 5, WPMDefault	#	return() // Returns to Main
	jr	$ra			# }
	
	WPMDefault:
	li	$s5, 1
	jr	$ra
