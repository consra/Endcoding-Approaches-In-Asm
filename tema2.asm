;%include "io.inc"
extern puts
extern printf
extern strstr
extern strchr 

section .data
filename: db "./input.dat",0
inputlen: dd 2263
fmtstr: db "Key: %d",0xa,0
format db "%d ",0

section .text
global main

; TODO: define functions and helper functions
  ; macro folosit pentru conversi de la exercitiul 4
  %macro convert 1
      cmp %1, 0x40
      jg %%case1
      sub %1, 0x18
      jmp %%case2
   %%case1: 
      sub %1,0x41
   %%case2:
   %endmacro

;exercitiul 6 
break_substitution:
    push ebp
    mov ebp, esp
    mov ebx, [ebp + 8]
    mov edi, [ebp + 12]
    mov ecx, 0xffffffff ;folosesc rep si nu vreau sa am probleme cu ec 
    
    mov esi, [ebp + 12]
while:                 
    xor eax, eax
    mov al, byte[ebx]   ;caracterul cautat il pun in al
    mov edx, 0
    mov edi,[ebp + 12]  ;pun tabela in edi 
    
    repnz scasb         ;parcurg tabela pana gasesc caracterul din al
    dec edi             ;imi returneaza cu o pozitie in fata 
    mov edx, edi 
    sub edx, esi
    and edx, 0x1        ;daca pozitia este impara inseamna ca litera este incriptata 
    jnz right_position  ;daca nu este , atunci nu parcurg in continuare sirul
    inc edi
    repnz scasb
    dec edi
    
right_position:             
    mov ah, byte[edi-1] ;litera corecta 
    mov byte[ebx], ah   ;suprascriu sirul initial
    inc ebx 
    cmp byte[ebx], 0
    jne while
    
    mov ecx, [ebp + 8]  ;sirul initial
    mov eax, [ebp + 12] ;tabela 
   
    leave 
    ret 
bruteforce_singlebyte_xor:
    push ebp
    mov ebp, esp
    sub esp, 6          ;salvez cuvantul force pe stiva pentru a folosi strstr
    mov byte[esp],'f'
    mov byte[esp+1],'o'
    mov byte[esp+2],'r'
    mov byte[esp+3],'c'
    mov byte[esp+4],'e'
    mov byte[esp+5], 0    
    mov ebx, esp
    
    mov ecx, [ebp + 8]
    xor edx, edx
    mov dl, 0x00        ;incep cu cheia 0 
    
simple_xor:
    mov ecx, [ebp + 8]
start:
    mov dh, byte[ecx]   ;pun caracterul din ecx in h
    xor dh, dl          ;xor cu cheia
    mov byte[ecx], dh   ;suprascriu caracterul din ecx 
    inc ecx 
    cmp byte[ecx], 0
    jne start           ;repet pana la sfarsitul sirului
    
    mov ecx, [ebp + 8]
    push edx            ;imi salvez registri pentru a nu fi suprascrisi la strstr
    push ebx
    
    push ebx
    push ecx
    call strstr         ;folosesc strstr din standard c 
    add esp, 8
    
    pop ebx
    pop edx 
    
    cmp eax, 0           ;daca rezultatul salvat in eax e diferit de 0 atunci am gasit
    jne done             ;cheia si sar la sfarsit
    mov ecx, [ebp + 8]
    
reverse_xor:             ;daca cheia nu e ceea corect fac din xor pentru a ma intoarce                           
    mov dh, byte[ecx]    ;la mesajul initial 
    xor dh, dl
    mov byte[ecx], dh
    inc ecx 
    cmp byte[ecx], 0
    jne reverse_xor
    
    inc dl                ;cresc cheia si incerc din nou
    cmp dl,0xFF
    jne simple_xor
    
done:                     ; daca am terminat pun adresa initiala in ecx 
    mov ecx,[ebp + 8]
    mov eax, ecx
    
    add esp, 6  
    leave
    ret
    
converting_byts:           ;functie ajutatoare pentru 4 
                           ;ce converteste 8 octeti de forma 000 aaaaa in 5                       
    push ebp               ;de forma aaa aaaaa
    mov ebp, esp
    mov ecx, [ebp + 8]
    mov esi, [ebp + 8]

    xor edx, edx           ;toti registri ii fac 0 pentru a ma ajuta la conversie
    xor eax, eax
    xor ebx, ebx
    xor edi, edi
                           ;in codul de mai jos ma folosesc de operatii pe biti 
                           ;pentru conversia octetilor
jump:
    mov dl, byte[ecx]      
    convert dl             ;am folosit un macrou pentru conversie 
    shl dl,3
   
    inc ecx 
    mov bl, byte[ecx]
    convert bl
    
    shr bl,2
    xor dl, bl 
    mov byte[esi],dl 
    inc esi
                            ;primul e gata
                             
    mov bl, byte[ecx] ; 000 aaaaa          
    convert bl        ; 000 aaaaa
    and bl,0x03       ; 000 000aa
    shl bl,6          ; aa0 00000   
    
    
    inc ecx
    mov dl, byte[ecx] ; 000 aaaaa
    convert dl        ; 000 aaaaa
    
    shl dl, 1         ; 00a aaaa0
    xor bl,dl         ; aaa aaaa0
    
    
    inc ecx
    mov dl, byte[ecx] ; 000 aaaaa
    convert dl        ; 000 aaaaa
    
    and dl, 0x10      ; 000 a0000
    shr dl, 4         ; 000 0000a
    xor bl, dl        ; aaa aaaaa
    
    mov byte[esi], bl
    inc esi 
                             ;al doilea octet complet
    
    mov bl, byte[ecx] ; 000 aaaaa 
    convert bl        ; 000 aaaaa
    
    and bl, 0xEF      ; 000 0aaaa
    shl bl, 4         ; aaa a0000
    
    inc ecx           ; 
    mov dl, byte[ecx] ; 000 aaaaa
    convert dl        ; 000 aaaaa
    
    shr dl, 1         ; 000 0aaaa
    or bl, dl         ; aaa aaaaa
    
    mov byte[esi], bl
    inc esi
                      ;al treilea octet complet 
    
    mov bl, byte[ecx] ; 000 aaaaa
    convert bl        ; 000 aaaaa
    
    and bl, 0x1       ; 000 0000a
    shl bl, 7         ; a00 00000
   
    inc ecx           ;
    mov dl, byte[ecx] ; 000 aaaaa
    convert dl        ; 000 aaaaa
    
    shl dl, 2         ; 0aa aaa00
    or bl, dl         ; aaa aaa00
    
    inc ecx
    mov dl, byte[ecx] ; 000 aaaaa
    convert dl
    and dl, 0x18      ; 000 aa000
    shr dl, 3         ; 000 000aa
    xor bl, dl        ; aaa aaaaa
    
    mov byte[esi], bl
    inc esi
    ; al patrulea byte complet 
    
    mov bl,byte[ecx]
    convert bl
    and bl, 0x7
    shl bl, 5
    
    inc ecx 
    mov dl, byte[ecx]
    convert dl
    xor bl, dl
    mov byte[esi],bl
    inc esi
    inc ecx
    cmp byte[ecx], 0 
    jne jump
    
    ;al cincelea byte complet
    

    sub esi, 3 
    mov byte[esi], 0
    leave 
    ret
    
base32decode:               ;functia principala pentru 4 
    push ebp
    mov ebp, esp
    mov ecx, [ebp + 8]
    
    push ecx
    push ecx
    call converting_byts
    add esp, 4
    
    mov eax, [ebp + 8]
    mov ecx, [ebp + 8]   
    
    leave 
    ret
    
    
new_string:                  ;creaza un nou string cu transformandu-l pe cel  
    push ebp                 ;primit transformand doi octeti intr-unul singur
    mov ebp, esp             ;si suprascrie in sirul sursa 
    
    mov esi, [ebp + 8]
    mov eax,esi
    xor edx, edx
   
converting:   
    mov dl,byte[esi]         ;prelucrez primul octet 
    cmp dl,0x59              ;determin daca e litera sau cifra 
    jg letter1
    sub dl,0x30
    jmp number1
letter1:
    sub dl ,0x57
number1: 

    shl dl, 4 
    inc esi             
    mov dh ,byte[esi]         ;prelucrez al doilea octet 
    
    cmp dh, 0x00 
    je complete
    
    cmp dh,0x59
    jg letter2
    sub dh,0x30
    jmp number2
letter2:
    sub dh ,0x57
number2:

    or dl,dh                ;noul octet e in dl
    inc esi
    mov byte[eax],dl        ;suprascriu
    inc eax
    cmp byte[esi], 0x00
    jne converting
complete:   
    mov byte[eax], 0x00     ; o sa am un sir de 2 ori mai scurt asa ii pun la sfarsit
    mov eax,[ebp + 8]       ; terminatorul de sir 
    leave
    ret
    
xor_hex_strings:
    push ebp
    mov ebp, esp
    
    mov esi, [ebp + 8]
   
                            ;prelucrez primul sir 
    push esi
    call new_string
    add esp, 4
    
    push eax

                            ;prelucrez  al doilea sir 
    mov ebx, [ebp + 12]
    push ebx
    call new_string
    add esp, 4
    mov ebx, eax
    pop esi
    
                            ;apelez functia de la exercitiul 1 
    push esi
    push ebx
    call xor_strings
    add esp, 8
    
    leave 
    ret
    
                            ;exercitiul 2 
rolling_xor: 
    push ebp
    mov ebp, esp
    
    mov eax, [ebp+8]
    xor ebx, ebx
    xor edx, edx
    mov dl, byte[eax]        ;octetul trec il am in dl
    push eax
    
.while:
    inc eax 
    mov bl, byte[eax]        ;pun bytul curent in bl
    test bl,bl               ;testez daca am ajuns la capat
    jz finish
    xor dl, bl               ;fac xor din bytul trecut si bytul curent 
    mov byte[eax], dl        ;suprascriu
    mov dl, bl               ;salvezul bytul trecut 
    cmp bl,0
    jne .while
    
 finish:   
    pop eax
    
    leave
    ret
    
xor_strings:                 ;functia de la exercitiul 1
    push ebp
    mov ebp, esp
  
    mov eax, [ebp + 8]
    mov ebx, [ebp + 12]
    
    push ecx 
    xor ecx,ecx
    
again:
    mov dl, byte[eax]        ;bytul curent din eax
    mov cl, byte[ebx]        ;bytul curent din ebx 
    xor dl, cl               ;fac xor dinte ele
    mov byte[eax],dl         ;suprascriu inapoi
    inc eax
    inc ebx
    cmp dl,0 
    jne again
   
    
    mov eax, [ebp+8]
    push eax
    call puts
    add esp, 4
    
    pop ecx

    leave    
    ret
    
strlen:
    push ebp
    mov ebp, esp
    
    push ecx
    cld                   ; setăm DF = 0
    mov al, 0x00          ; char-ul pe care vrem să îl căutăm
    mov edi, [ebp + 8]    ; zona de memorie în care căutăm
    repne scasb      
    pop ecx 
 
    sub edi, [ebp + 8]  
    mov eax ,edi
    leave     
    ret

main:
    mov ebp, esp; for correct debugging
    push ebp
    mov ebp, esp
    sub esp, 2300
    
    ; fd = open("./input.dat", O_RDONLY);
    mov eax, 5
    mov ebx, filename
    xor ecx, ecx
    xor edx, edx
    int 0x80
    
	; read(fd, ebp-2300, inputlen);
	mov ebx, eax
	mov eax, 3
	lea ecx, [ebp-2300]
	mov edx, [inputlen]
	int 0x80

	; close(fd);
	mov eax, 6
	int 0x80

	
	; all input.dat contents are now in ecx (address on stack)

	; TASK 1: Simple XOR between two byte streams
	; TODO: compute addresses on stack for str1 and str2
	; TODO: XOR them byte by byte
	;push addr_str2
	;push addr_str1
     push ecx
     call strlen
     add esp, 4

     push eax
     push ecx
     add ecx,eax
     push ecx
     call xor_strings
     add esp, 8
     
     pop eax 
     add ecx,eax
    ; push ecx 
    ; call puts 
    ; add esp,4
     
     ;PRINT_DEC 4,eax
    
     ; Print the first resulting string
	;push addr_str1
	;call puts
	;add esp, 4

	; TASK 2: Rolling XOR
	; TODO: compute address on stack for str3
	; TODO: implement and apply rolling_xor function
     push ecx
     
	push ecx
	call rolling_xor
	add esp, 4
     push eax
     call puts
     add esp,4
     pop ecx
     push ecx 
     call strlen
     add esp, 4 
     
     add ecx, eax
     
    
	; Print the second resulting string
	;push addr_str3
	;call puts
	;add esp, 4

	
	; TASK 3: XORing strings represented as hex strings
	; TODO: compute addresses on stack for strings 4 and 5
	; TODO: implement and apply xor_hex_strings
     push ecx
     call strlen
     add esp, 4
     
     push ecx 
     
     ;push addr_str5
	;push addr_str4
	;call xor_hex_strings
	;add esp, 8
     add ecx,eax
     push ecx    
     sub ecx,eax
     push ecx
     call xor_hex_strings 
     add esp, 8
	
     ;Print the third string
	;push addr_str4
	;call puts
	;add esp, 4
     pop ecx
     
     push ecx
     call strlen
     add esp, 4
     add ecx,eax
     
     push ecx
     call strlen
     add esp, 4
     add ecx,eax
     
     push ecx
     call strlen
     add esp, 4
     add ecx,eax
     
     push ecx
     call strlen
     add esp, 4
     add ecx,eax
     
   
	; TASK 4: decoding a base32-encoded string
	; TODO: compute address on stack for string 6
	; TODO: implement and apply base32decode
     push ecx
	push ecx
     call base32decode
	add esp, 4

 
	; Print the fourth string
	;push addr_str6
	;call puts
	;add esp, 4
     push eax
    call puts
    add esp,4 
    
    pop ecx 
    
    push ecx
    call strlen
    add esp,4 
    add ecx,eax
    
    push ecx
    call strlen
    add esp,4
    add ecx, eax
	; TASK 5: Find the single-byte key used in a XOR encoding
	; TODO: determine address on stack for string 7
	; TODO: implement and apply bruteforce_singlebyte_xor
     push ecx
     sub esp, 4
     mov edx,esp 
	push eax
	push ecx
	call bruteforce_singlebyte_xor
	add esp, 8
     
	; Print the fifth string and the found key value

     push edx
	push eax
	call puts
	add esp, 4
     pop edx 
     
     xor dh,dh 
     add esp, 4
	push edx
	push fmtstr
	call printf
	add esp, 8
     
     pop ecx
     push ecx
     call strlen
     add esp, 4    
     add ecx, eax
     
     sub esp, 60
     
     mov byte[esp],'a'
     mov byte[esp+1],'q'
     mov byte[esp+2],'b'    
     mov byte[esp+3],'r'     
     mov byte[esp+4],'c'
     mov byte[esp+5],'w'
     mov byte[esp+6],'d'
     mov byte[esp+7],'e'
     mov byte[esp+8],'e'     
     mov byte[esp+9],' '    
     mov byte[esp+10],'f'
     mov byte[esp+11],'u'
     mov byte[esp+12],'g'     
     mov byte[esp+13],'t'
     mov byte[esp+14],'h'
     mov byte[esp+15],'y'
     mov byte[esp+16],'i'
     mov byte[esp+17],'i'     
     mov byte[esp+18],'j'     
     mov byte[esp+19],'o'   
     mov byte[esp+20],'k'
     mov byte[esp+21],'p'
     mov byte[esp+22],'l'
     mov byte[esp+23],'f'     
     mov byte[esp+24],'m'
     mov byte[esp+25],'h'
     mov byte[esp+26],'n'
     mov byte[esp+27],'.'
     mov byte[esp+28],'o'     
     mov byte[esp+29],'g'     
     mov byte[esp+30],'p'
     mov byte[esp+31],'d'
     mov byte[esp+32],'q'
     mov byte[esp+33],'a'     
     mov byte[esp+34],'r'     
     mov byte[esp+35],'s'
     mov byte[esp+36],'s'
     mov byte[esp+37],'l'
     mov byte[esp+38],'t'     
     mov byte[esp+39],'k'
     mov byte[esp+40],'u'    
     mov byte[esp+41],'m'
     mov byte[esp+42],'v'
     mov byte[esp+43],'j'
     mov byte[esp+44],'w'
     mov byte[esp+45],'n'
     mov byte[esp+46],'x'     
     mov byte[esp+47],'b'     
     mov byte[esp+48],'y'     
     mov byte[esp+49],'z'     
     mov byte[esp+50],'z'
     mov byte[esp+51],'v'
     mov byte[esp+52],' '
     mov byte[esp+53],'c'
     mov byte[esp+54],'.'
     mov byte[esp+55],'x'
     mov byte[esp+56],0
     
       
	; TASK 6: Break substitution cipher
	; TODO: determine address on stack for string 8
	; TODO: implement break_substitution
	push esp
	push ecx
	call break_substitution
	add esp, 8
    
	; Print final solution (after some trial and error)
     push eax
	push ecx
	call puts
	add esp, 4
     pop eax 
	; Print substitution table
	push eax
	call puts
	add esp, 4
     add esp, 60
	; Phew, finally done
    xor eax, eax
    leave
    ret
