;ECOAR PROJECT 2
;OMER AMAC
;323796

section .data

char_table: db	 '0','1','2', '3', '4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','-','.', ' ','$','/','+','%','*'
char_code: 	dd 111221211,  211211112, 112211112,  212211111, 111221112, 211221111, 112221111, 111211212, 211211211, 112211211, 211112112, 112112112, 212112111, 111122112,211122111,  112122111, 112122111,  211112211, 112112211, 111122211, 211111122, 112111122, 212111121, 111121122, 211121121, 112121121,111111222,  211111221, 112111221,  111121221, 221111112, 122111112, 222111111, 121121112, 221121111, 122121111, 121111212, 221111211,122111211,  121212111, 121211121,  121112121, 111212121, 121121211











	%define output     [ebp+16]		;output
	%define line_point [ebp+12]		;line pointer(25)
	%define image      [ebp+8]		;bmp img itself
	%define width      1800 		;600 width x 3 RGB
	%define bar_width  [ebp-4]		;local variable to store the witdth of first stripe
	
section .text
	global func
	extern printf
func:
   	push ebp
   	mov  ebp, esp
      	push ecx
   	push ebx
   	push esi
   	push edi
	xor  edx,edx
	xor  ecx,ecx
	mov  eax, image 		;move image to eax register
;##################################
	mov edx,[eax]
	cmp dx,0x4d42			;check bmp marker error
	jne bmp_error
	
	mov edx,[eax+18]
	cmp dx,0x00000258		;check the width of image
	jne size_error

	mov edx,[eax+22]
	cmp dx,0x00000032		;check the height of the image
	jne size_error

	xor edx,edx
;#####################################
	mov  ecx, width			;put the value of width into ecx
	imul ecx, line_point 	;multiply 25*1800, 
	add  eax, ecx 			;add pointer position to current address of the image, now pointer at the first pixel on the middle of image


	xor ecx, ecx	;reset the register 
	xor edi, edi	;reset the register, use as counter for the pointer
	xor ebx, ebx	;reset the register, use for counting the width of stripe
	
	mov esi, output ;assign output stack to esi register
	

look_for_black:				;start to check for the first black stripe, it is '*'
	mov ecx, eax
	cmp BYTE[ecx], 0 		;check if the pixel black
	je  black_found  		;if pixel black jump
	inc edi 				;counter for the pointer
	cmp edi,600 			;control to check if pointer is in the same line
	je  exit				;if pointer at last pixel(600) exit
	add eax,3 				;if not, add 3(pixels) and jump to look_for_black
	jmp look_for_black
	
black_found: 				;checking the wdith of the bar
	xor ecx, ecx 			;restore ecx again to use for space
	
	mov ecx, eax
	cmp BYTE[ecx], 0 		;checking if pixel is black
	jne first_black_complete		;jump if it is not black
	add eax, 3		 		;shift the pointer b 3(3 is because of RGB)
	inc ebx			 		; increment length of stipe
	inc edi			 		; check the position of pointer
	cmp edi, 600	 	
	je  exit					;if pointer at 600th pixel then exit
	jmp black_found
	
;######################################################################
	
first_black_complete: 		
	sub  edi,ebx			;set counter back to begining of the first black pixel
	imul ecx,ebx,3			
	sub  eax,ecx			;set eax to begining of the first black pixel
	xor  ecx,ecx
	
	mov bar_width, ebx		;set ebx as the width of the bar

;#######################################################################
	
decode:
	xor edx,edx			;reset the register, store char_ccode value inside
	xor ebx,ebx			;reset the register, length of the char_code (should be 9)
check_color:				;check the color of the pixel white or black
	xor ecx, ecx			;reset the register, will check the width of the stripe
	cmp BYTE[eax], 0		;Check if we have black or white color, than jump to proper label
	je  black			;jump to black pixel width count
	jne space			;jump to space pixel width count
	
black:
	inc ecx				;increase the width by 1
	add eax, 3			;shift pointer for next pixel
	inc edi				;increase the pointer control
	cmp edi,600			;exit if pointer control value is 600
	je  exit
	cmp BYTE[eax], 0		;check if next pixel is black or space
	je  black			;loop if it is black
	jmp color_end			;jump if it is not black anymore

	
space:
	inc ecx				;increase the width by 1
	add eax,3			;shift pointer for next pixel
	inc edi				;increase the pointer control
	cmp edi,600			;exit if pointer control value is 600
	je  exit
	cmp BYTE[eax], 0		;check if next pixel is black or space
	jne space			;loop if it is space
	jmp color_end			;jump if it is not space anymore
	
color_end:	
	cmp ebx,9			;check if we have 9 digits for the character codes
	je  find_char			;if we have already 9 then jump to find the character
	inc ebx				;if not thenincrease the length of char_code array
	cmp ecx, bar_width  		;check if it is narrow or thick 
	jg  wide			;jump to wide if greater than narrow
	jmp narrow			;else jump to narrow

wide:
	imul edx, 10			;multiply the char_code value by 10 to create place for next digit
	add edx, 2			;add 1 if it is narrow
	cmp ebx, 9			;check if we have 9 digits for the character codes
	je  find_char			;if we have already 9 then jump to find the character
	jmp check_color			;if not go back to start for the next digit

narrow:
	imul edx, 10			;multiply the char_code value by 10 to create place for next digit
	add  edx,1			;add 1 if it is narrow
	cmp  ebx, 9			;check if we have 9 digits for the character codes
	je   find_char			;if we have already 9 then jump to find the character
	jmp  check_color		;if not go back to start for the next digit
	

;##################################################################

find_char:
;EBX -> ARRAY  (with patterns)
;ECX -> POSITION IN ARRAY
	xor ebx, ebx		;reset the register, char_code address
	xor ecx, ecx		;reset the register, char_code pointer

find_position: 
;Iteration through array to check if encoded symbol equal one of the array.
	mov ebx, [char_code+4*ecx]		;load the first char_code into ebx
	cmp edx, ebx				;compare our array with the char_codes
	je  encode 				;if it is in the char_code jump to encode
	inc ecx					;if can not find loop over all codes in char_code
	cmp ecx, 44				;check if we are at the end of the char_code
	je  exit				;if yes, exit
	jmp find_position 			;if not continue to search for it
	
encode:
	xor edx, edx				;restore the register 
	mov bl, [char_table+ecx]		;move the content of the char_table into bl
	mov BYTE[esi],bl			;mov bl into output register esi
	inc esi					;increase esi by 1 for nect character
	
next_bar:						
	add eax, 3				;shift image pointer by 3(RGB)
	inc edi					;increase pointer by 1
	cmp edi, 600				;exit if we are at the end of the line
	je  exit
	cmp BYTE[eax], 0			;check if the next pixel is black
	je decode				;if black go to decode 
	jmp next_bar				;if not loop till find the black
	jmp exit
exit:
	mov eax,0
	jmp exit_last				;exit with success
	
bmp_error:
	mov eax,1				
	jmp exit_last				;exit with bmp marker error
size_error:
	mov eax,2	
	jmp exit_last				;exit with image size error

exit_last:					;exit the program
	
	pop edi
    	pop esi
    	pop ebx
    	pop ecx
    	mov esp,ebp
   	pop ebp
   	ret
   	