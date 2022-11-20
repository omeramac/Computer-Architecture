###############################
##        OMER AMAC          ##
##         323796            ##
##  BARDCODE 39 - DECODING   ##
###############################

.eqv BMP_FILE_SIZE 90122
.eqv HEADER_SIZE 54
.eqv BMP_MARKER 0x4D42

.data

##########################


##############################
file_err:			.asciz "Cant open the file\n"
size_err:			.asciz "Wrong image size\n"
format_err:			.asciz "Wrong format\n"
#file_msg:			.asciz "File opened successfully!\n"
output:				.asciz "Decoded Barcode =>> "
cont_err:			.asciz "Control Error\n"
store_char_code:		.asciz "000000000\n"
blank:				.asciz " "
input_image:			.asciz "tests/1.bmp"
#create sign and character codes
sign_table:			.asciz "*0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%"
char_codes: 			.asciz "121121211.111221211.211211112.112211112.212211111.111221112.211221111.112221111.111211212.211211211.112211211.211112112.112112112.212112111.111122112.211122111.112122111.111112212.211112211.112112211.111122211.211111122.112111122.212111121.111121122.211121121.112121121.111111222.211111221.112111221.111121221.221111112.122111112.222111111.121121112.221121111.122121111.121111212.221111211.122111211.121212111.121211121.121112121.111212121.\n"

#empty buffer for the output
code:				.space 60
#empty buffer for the header of bmp file
header: 			.space HEADER_SIZE
#empty buffer to save image
image:				.space BMP_FILE_SIZE


.text
##########################

##########################
open_file:
	#open file 
	li a7,1024
	la a0,input_image  #name of the input image
	li a1,0 	#0 for read, 1 for write
	ecall
	
	bltz a0,error1 #a0 is the output of the 1024 service (file descriptor) and if -1 error
	
	mv s0,a0 #store the file descriptor if it was able to open file
	
	#li a7,4
	#la a0,file_msg
	#ecall
	
	li a7,63    #read file service
	mv a0,s0	#set file descriptor to a0
	la a1,header  #set the output address of the read service to header
	li a2,HEADER_SIZE #read first 54 
	ecall
	
	bltz a0,error1 #if reading file is failed, give error

	la s2,header 	#load address of header to s2
	lhu s11,(s2)	#load bmp marker to s11
	lhu s6,18(s2)	#load width to s6
	lhu s7,22(s2)	#load height to s7
	li a4,BMP_MARKER
	li s4,0x00000258 	#600 image width
	li s3,0x00000032	#50 image height
	
	bne a4,s11,header_error	#check if bmp marker is correct
	bne s4,s6,header_error	#check if image width is correct
	bne s7,s3,header_error	#check if image height is correct
	
	li s10,BMP_FILE_SIZE #save image size to s10
	
	#save image to memory
	li a7,63	#read service
	mv a0,s0	#set descriptor to a0
	la a1,image	#load the image empty buffer to output of read service
	mv a2,s10
	ecall
	
	#read
	la s3,image	#load address of the image to s3
	li s10,45000	#half of the height is 25 and width is 600, 3bytes per RGB (25x600x3)
	add s3,s3,s10	#move offset to middle of the height of the image
	
search_black:
	lb s7,(s3)	#load the content of address s3 to s7
	beqz s7,black_found	#if equal to zero, it means we found black pixel
	li s10,3		#it is RGB, so we need to shift with 3 bytes
	add s3,s3,s10		#shift 3 bytes and loop till find the black pixel
	j search_black
	
black_found:
	li s1,1			#counter for black width

check_width:
	li s10,3	
	add s3,s3,s10		#shift 3 bytes again
	lb s7,(s3)
	bnez s7,black_finished	#check if it is black, if not jump to count space 
	li s10,1		
	add s1,s1,s10		#if still black, increase the width of black
	j check_width		#continue to count black pixels
	
	
black_finished:
	li s2,1			#set counter for width of space

#check how wide is the space	
width_of_space:
	li s10,3		#shift 3 bytes again
	add s3,s3,s10
	lb s7,(s3)
	beqz s7,space_finished	#if it is zero, space is finished 
	li s10,1		#if space, increase the space width counter
	add s2,s2,s10		
	j width_of_space	#loop till finish the spaces

#we know that barcode39 starts wit '*' and it is code is 121211121. 
#we found one space and one black, we must go after '*' sign	
space_finished:
	li s10,5
	mul t5,s1,s10		#we need 5 more narrow
	li s10,2
	mul s4,s2,s10		#we need 2 more wide
	add s4,s4,t5
	li s10,3
	mul s4,s4,s10		#3 bytes per RGB then we must multiply by 7x3
	add s3,s3,s4		#set the new pointer address to after '*' sign
	
	
	la s9,code		#load address of the output
	li s10,3		#restore the pointer in image buffer
	mul s4,s1,s10
	add s3,s3,s10
	
	li a1,0

read_marker:
	add s3,s3,s4
	la s8,store_char_code	#load address of the empty buffer for 9 digit char code for storage
	la s6,sign_table	#load address of character table
	la s7,char_codes	#load address of char code table
	li a7,0			#counter for 9 digits
	
load_dash_and_chars:
	li t6,1			#counter for widths

dash:
	lb t0,(s3)		#load pixel from the image buffer
	li s10,3		
	add s3,s3,s10		#shift for 3 bytes (RGB)
	bnez t0,chars		#if not equal to 0(not black) jump to characters
	li s10,1
	add t6,t6,s10		#increase the width
	j dash
	
chars:
	beq t6,s1,narrow	#if equal 1 (if narrow) jump to narrow section

wide:
	li t1,'2'		#load '2' in t1	
	sb t1,(s8)		#put '2' in 9 digit code buffer for wide line
	j increase_9_digit
	
narrow:
	li t1,'1'
	sb t1,(s8)		#put '1' in 9 digit code buffer for narrow line
increase_9_digit:
	li s10,1
	add s8,s8,s10		#increase the pointer for 9 digit code buffer
	add a7,a7,s10		#increase the counter for 9 digits
	li t6,0			#restore width
	li s10,9
	beq a7,s10,written	#check if we read 9 digits or not, if yes jump to write section
	li t6,1			#if not increase the width by 1 again
	
	
space_f:
	lb t0,(s3)		#load the new pixel and check
	li s10,3
	add s3,s3,s10		#shift for 3 bytes
	beqz t0,sign_2		#if zero black pixel found go and check the width
	li s10,1
	add t6,t6,s10
	j space_f
	
sign_2:
	beq t6,s1,narrow_2	#check the width, if narrow go to narrow 2 section
wide_2:
	li t1,'2'
	sb t1,(s8)		#if not narrow put '2' for wide line 
	j done
	
narrow_2:
	li t1,'1'
	sb t1,(s8)		#if narrow put '1' in 9 digit char code
	
done:
	li s10,1
	add s8,s8,s10		#increase image pointer by 1
	add a7,a7,s10		#increase digit buffer pointer by 1
	
	
	j load_dash_and_chars	#go to check new line till we have 9 digits
	
	

	
written:
	
	li s10,3
	mul s4,s1,s10
	
	la s8,store_char_code	#load address of the 9 digit code of char
	li t2,0
	


decode:
	lb t1,(s8)		#load char codes (9 digit)
	lb t2,(s7)		#load characters table
	li s10,'.'		#seperator '.'
	beq t2,s10,found	#if find seperator jump found section
	li s10,1		#shift pointer by 1 for char codes
	add s7,s7,s10		#shift pointer by 1 for char table
	add s8,s8,s10		#if not equal go to different
	bne t1,t2,different
	j decode
	
different:
	li s10,1	
	add s6,s6,s10		#shift the offset in char table

tab_dashes:
	lb t2,(s7)		#load the value from char_codes (1 or 2) or '.'
	li s10,1
	add s7,s7,s10		#shift the pointer for char codes by one for next loop
	li s10,'\n'
	beq t2,s10,finish_write	#check if there is sth left to read in char_codes buffer
	li s10,'.'
	bne t2,s10,tab_dashes	#if it is '.' loop in same section and check next byte
	j written		#if not null and not '.' go to check the character again
	
found:	
	lb t3,(s6)		#load char from char table from pointer s6
	li s10,'*'
	beq t3,s10,finish_write	#if char is '*' finish writing
	li s10,1
	add a1,a1,s10		#if not increase a1
	sb t3,(s9)		#store the char in output buffer
	add s9,s9,s10		
	j read_marker		#jump to read marker for next character
	



	
finish_write:
	li s10,1
	sub s9,s9,s10
	lb t5,(s9)		#load byte from our output buffer
	la t4,code		#load address of output buffer make copy of s9
	#reset registers
	li s4,0
	li a7,0
	li s7,0
	li s2,0
	
	
control_sign:
	li s10,1
	add a7,a7,s10
	beq a7,a1,out_thr	#check size of the string, if one go to out
	lb t6,(t4)		#load byte from output string
	add t4,t4,s10		#shift pointer by one for next loop
	la s6,sign_table	#load address of char table to compare
	add s6,s6,s10		#increase by one to jump after '*' sign
	li s1,0			#length counter for string
	
find_char:
	lb s2,(s6)		#load the char from char_table
	li s10,1
	add s6,s6,s10		#increase the offset by one for next loop
	beq s2,t6,number_found	#compare output string and char table if same char go to number_found
	add s1,s1,s10		#increase counter
	j find_char
	
number_found:
	li s10,'\0'
	beq t6,s10,number_error	#if null character give error
#calculate checksum value
control_sign_2:
	add s4,s4,s1		#increase s4 by 1 through loops
	li s10,42
	ble s4,s10,control_sign	#if less than 43 go back to contr
	li s10,43
	sub s4,s4,s10		#subtract 43 from s4
	j control_sign

	
out_thr:
	la s6,sign_table        #load address of sign table buffer
	li s10,1
	########
	lb a5,(s6)	#just for control
	##########
	add s6,s6,s10	#increase the sign table pointer by 1
	li s1,0
	
decode_control_sign:
	lb s2,(s6)		#load address
	li s10,1
	add s6,s6,s10
	beq s1,s4,control	#if equal everything is okey, go to next
	add s1,s1,s10		#till find it loop
	j decode_control_sign
	
control:
	#bne t5,s2,control_error
	li t6,'\n'
	sb t5,(t4)	#write the char in output(code) buffer
	li s10,1
	add t4,t4,s10
	sb t6,(t4)
#print the decoded barcode	
print_code:
	li a7,4
	la a0,output	#output message
	ecall
	li a7,4
	la a0,code	#decoded string
	ecall

close_file:	#close the file
	li a7,57
	mv a0,t0
	ecall
	j exit
	
control_error:	#control error
	li a7,4
	la a0,cont_err
	ecall
	j exit

header_error:	#header error
	li a7,4
	la a0,size_err
	ecall
	j exit	
number_error:
	j exit
error1:		#filer error
	li a7,4
	la a0,file_err
	ecall
	j exit
exit:		#exit from program
	#li a7,4
	#la a0,finish
	#ecall
	li a7,10
	ecall
	
	
	
	
