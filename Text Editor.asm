%include "./sys_equal.asm"
%include "./in_out.asm"
%include "./file_in_out.asm"

section .data
   fileDes dq 0
   
   fileContLen dq 0
   fileCharCnt dq 0
   fileWordCnt dq 0
   fileLineCnt dq 0

   charStr dq "# CHARACTER COUNT: ", 0
   wordStr dq "# WORDS COUNT: ", 0
   lineStr dq "# LINE COUNT: ", 0
   one dq 1
   zero dq 0

   searchResultCnt dq 0
   wrdLen dq 0
   bufLen dq 0
   cnt dq 0
   countSearchStr dq "# SEARCH RESULT: ", 0
   searchMsg dq "# ENTER A WORD TO SEARCH -> "
   indexMsg dq "# INDEXES: "

   appendLen dq 0
   appendMsg dq "# ENTER A WORD TO APPEND -> "
   appSuc dq "# APPEND SUCCESSFUL!", 0

   saveSuc dq "# SAVE SUCCESSFUL!", 0

   replaceInd dq 0
   NullSearchStr dq "# NO MATCH FOUND!", 0
   replaceWrdLen dq 0
   helperBufLen dq 0
   replaceMsg dq "# ENTER I-TH INDEX (e.g. 1 for first index in INDEXES list.) -> ", 0
   replaceSuc dq "# REPLACE SUCCESSFUL!", 0
    replaceMsgg dq "# ENTER A WORD TO REPLACE -> ", 0


   startMsg dq "# ASM TEXT EDITOR HAS STARTED!", NL, 0
   commandMsg dq "# LIST OF CMD: O(OPEN A FILE) - I(GET FILE INFO) - S(SEARCH) - R(SEARCH AND REPLACE) - D(DELETE) - A(APPEND) - X(REGEX) - V(SAVE) - E(SAVE AS) - Q(QUIT) -> ", NL, 0
   line dq "---------------------- FILE CONTENT -----------------------------", 0


   openMsg dq "# ENTER A FILE PATH (e.g. folder/file.txt) -> ", 0
   openSuc dq "# OPEN SUCCESSFUL!", 0

   delMsg dq "# ENTER THE NUMBER OF CHARACTERS TO DELETE -> ", 0
   delSuc dq "# DELETE SUCCESSFUL!", 0
    deleteCount dq 0

    invalidMsg dq "# INVALID COMMAND.", 0
    existErr dq "# ANOTHER FILE WITH THE SAME NAME ALREADY EXISTS (rename the file or save as in another directory).", 0
    openErr dq "# FILE DOES NOT EXISTS!", 0

    saveAsMsg dq "# ENTER A PATH TO SAVE FILE AS -> ", 0
    saveAsSuc dq "# SAVE AS SUCCESSFUL!", 0
   newFileDes dq 0

   here dq "heeere", 0

   regMsg dq "# ENTER A REGULAR EXPRESSION -> ", 0


section .bss
   fileCont resq 1000
   searchResultIndex resq 1000
   realSearchResultIndex resq 1000
   helperBuf resq 1000
   filePath resq 1000
   cmd resb 1
   find resq 1000
   appendStr resq 1000
   replaceWrd resq 1000
   helperMkdir resq 1000
   newFilePath resq 1000
   regCommand resq 1000

section .text
   global _start


piiiirint:
    push rcx
    push rbx
    xor rdx, rdx
    dec rdx
    bu:
        inc rdx
        mov al, [helperMkdir + rdx]
        call putc
        cmp rdx, rcx
        jne bu
    call newLine
    pop rbx
    pop rcx
    ret

mkdirSplit:
    xor rcx, rcx
    xor rax, rax
    mov rdi, newFilePath
    call getLen
    mov rax, rbx

    spltFile:
        mov al, [newFilePath + rbx]
        dec rbx
        cmp al, '/'
        jne spltFile
    inc rbx
    preparePath:
        xor rax, rax
        cmp rcx, rbx
        je recurMd
        mov al, [newFilePath + rcx]
        cmp al, '/'
        je recurMd
        mov [helperMkdir + rcx], al
        inc rcx
        jmp preparePath

    recurMd:
        push rcx

        mov rdi, helperMkdir
        mov rax, sys_mkdir
        mov rsi, 0q777
        syscall

        pop rcx
        cmp rcx, rbx
        je prepared
        mov byte[helperMkdir + rcx], '/'
        inc rcx
        jmp preparePath

    prepared:
    ret

index2Replace:
    mov rdi, helperBuf
    mov rsi, helperBufLen
    ;call resetBuffer

    call newLine
    xor rdx, rdx
    mov rdx, [replaceInd] 
    cmp rdx, [cnt]
    jbe staaart
    mov rsi, NullSearchStr
    call printString
    ret
    staaart:

    mov rdi, replaceWrd
    call getLen
    mov qword[replaceWrdLen], rbx 

    mov rdi, find
    call getLen
    mov qword[wrdLen], rbx 


    xor rdx, rdx
    xor rcx, rcx
    xor rax, rax
    mov rcx, [replaceInd]
    dec rcx
    mov dl, [realSearchResultIndex + rcx]

    xor rcx, rcx
    xor rbx, rbx
    mov rcx, rdx
    add rcx, [wrdLen] 
    dec rcx
    dec rbx
    copybuf:
        inc rcx
        inc rbx
        cmp rcx, qword[fileContLen]
        je endcopy
        mov rax, qword[fileCont + rcx]
        mov qword[helperBuf + rbx], rax
        jmp copybuf
    endcopy:

    xor rcx, rcx
    dec rcx
    replace:
        inc rcx
        cmp rcx, qword[replaceWrdLen]
        je endreplace
        mov rax, qword[replaceWrd + rcx]
        mov [fileCont + rdx + rcx], al
        jmp replace
    endreplace:


    mov rdi, helperBuf
    call getLen
    mov qword[helperBufLen], rbx 

    add rdx, [replaceWrdLen]
    xor rcx, rcx
    dec rcx
    repair:
        inc rcx
        cmp rcx, qword[helperBufLen]
        je endrepair
        mov rax, qword[helperBuf + rcx]
        mov [fileCont + rdx + rcx], al
        jmp repair
    endrepair:

    xor rdx, rdx
    xor rbx, rbx
    mov rdx, [replaceWrdLen]
    mov rbx, [wrdLen]
    cmp rdx, rbx
    ja addToLen
    sub rbx, rdx
    sub [fileContLen], rbx
    jmp lenFixed
    
    addToLen:
    sub rdx, rbx
    add [fileContLen], rdx

    lenFixed:

    ret



saveAs:
    mov rdi, newFilePath
    mov rax, 2
    mov rsi, sys_IRUSR | sys_IWUSR 
    syscall     
    mov [newFileDes], rax
    cmp rax, 0
    jle notExist

    call newLine
    mov rsi, existErr
    call printString
    call newLine
    ret

    notExist:

    call mkdirSplit

    ;create file.txt
    mov rdi, newFilePath
    mov rax, sys_create
    mov rsi, sys_IRUSR | sys_IWUSR 
    syscall     
    mov [newFileDes], rax
    
    mov rdi, [newFileDes]
    mov rsi, fileCont
    mov rdx, [fileContLen]
    mov rax, sys_write
    syscall

    ;close file
    mov rdi, [newFileDes]
    mov rax, sys_close
    syscall


    mov rsi, saveAsSuc
    call printString
    call newLine

    ret

save:
    ;open file
    mov rdi, filePath
    mov rax, sys_create
    mov rsi, sys_IRUSR | sys_IWUSR      
    syscall
    mov [fileDes], rax

    mov rdi, [fileDes]
    mov rsi, fileCont
    mov rdx, [fileContLen]
    mov rax, sys_write
    syscall

    ;close file
    mov rdi, [fileDes]
    mov rax, sys_close
    syscall

    ret

append:
    xor rdi, rdi
    mov rdi, appendStr
    call getLen
    mov qword[appendLen], rbx


    xor rcx, rcx
    xor rbx, rbx
    xor rax, rax

    mov rbx, fileCont
    add rbx, qword[fileContLen]

    dec rcx
    bibb:
        inc rcx
        cmp rcx, qword[appendLen]
        je boob
        mov rax, qword[appendStr + rcx]
        mov qword[rbx + rcx], rax
        jmp bibb
    boob:

    xor rax, rax
    mov rax, qword[appendLen]
    add qword[fileContLen], rax
    mov qword[fileLineCnt], 0
    mov qword[fileWordCnt], 0
    call info

    ret

delete:
    xor rax, rax
    mov rax, qword[deleteCount]
    cmp qword[fileContLen], rax
    ja doSub
    mov qword[fileContLen], 0
    jmp setZero
    doSub:
    sub qword[fileContLen], rax
    setZero:
    mov qword[fileLineCnt], 0
    mov qword[fileWordCnt], 0
    call info

    ret

showSearchResult:
    mov rsi, countSearchStr
    call printString
    mov al, [cnt]
    call writeNum
    call newLine

    xor rcx, rcx

    mov rsi, indexMsg
    call printString

    nextres:
        cmp rcx, qword[cnt]
        je endres
        mov al, [searchResultIndex + rcx]
        inc al
        call writeNum
        mov al, Space
        call putc
        
        inc rcx
        jmp nextres
    endres:

   ret



;output: rbx = len find    
getLen:
    xor rbx, rbx
    while1:
        cmp byte[rdi + rbx], 0
        je end1
        inc rbx
        jmp while1
    end1:

   ret
;count in cnt
;r13 := main str, r12 := search word
search: 
   push rcx
   push rdi
   push rbx
   push rax
   push r11
   push r12
   push r8

   xor rdi, rdi
   mov rdi, r12
   call getLen
   mov qword[wrdLen], rbx
   
   xor rdi, rdi
   mov rdi, r13
   call getLen
   mov qword[bufLen], rbx

   cmp rbx, qword[wrdLen]
   jb enoughhh

   cont:
   xor rbx, rbx ;moves on search word
   xor rcx, rcx ;moves on str
   xor rdx, rdx ;keeps index
   xor r8, r8 ;moves on indes
   xor r9, r9 ;like rcx  withoud NL
   mov qword[cnt], 0


    loopFile:
        xor rax, rax
        mov al, [r13 + rcx]
        cmp al, NL
        jne loopWord
        inc r9
        loopWord:
        xor rax, rax
        mov al, [r13 + rcx]
        inc rcx
        cmp al, [r12 + rbx]
        jnz nextt
        
        inc rbx
        cmp rbx, qword[wrdLen]
        jb loopWord
        xor rdx, rdx
        mov rdx, rcx
        sub rdx, qword[wrdLen]
        mov qword[realSearchResultIndex + r8], rdx
        sub rdx, r9
        mov qword[searchResultIndex + r8], rdx
        inc r8
        add qword[cnt], 1
        
        nextt:
        cmp rbx, 0
        je ish
        cmp qword[wrdLen], 1
        je ish
        dec rcx
        ish:
        xor rbx, rbx
        cmp rcx, qword[bufLen]
        jb loopFile

   enoughhh:
   pop r8
   pop r12
   pop r13
   pop rax
   pop rbx
   pop rdi
   pop rcx
   ret

info:
    mov qword[fileCharCnt],  0
    mov qword[fileWordCnt],  0
    mov qword[fileLineCnt],  0

    xor rax, rax
    mov rax, qword[fileContLen]
    cmp rax, 0
    jz infodone
    add qword[fileLineCnt], 1
    add qword[fileWordCnt], 1
    
    xor rcx, rcx
    dec rcx
    nextch:
        inc rcx
        xor rax, rax
        cmp rcx, qword[fileContLen]
        je infodone
        mov rax, qword[fileCont + rcx]
        cmp al, NL
        jz addLine
        cmp al, Space
        je addWord
        jmp nextch
    addLine:
        add qword[fileLineCnt], 1
    addWord:
        add qword[fileWordCnt], 1
        jmp nextch
    infodone:

    ret

showInfo:
    mov rsi, charStr
    call printString

    mov rax, qword[fileContLen]
    cmp rax, 0
    jne notEmpty
    call writeNum
    call newLine
    jmp edame

    notEmpty:
    mov qword[fileCharCnt], rax
    mov rax, qword[fileLineCnt]
    dec rax
    sub qword[fileCharCnt], rax
    mov rax, [fileCharCnt]
    call writeNum
    call newLine

    edame:
    mov rsi, wordStr
    call printString
    mov rax, qword[fileWordCnt]
    call writeNum
    call newLine

    mov rsi, lineStr
    call printString
    mov rax, [fileLineCnt]
    call writeNum
    call newLine

    ret


printFile:
    xor rcx, rcx
    dec rcx
    next:
        inc rcx
        cmp rcx, qword[fileContLen]
        je printdone
        mov rax, [fileCont + rcx]
        call putc
        jmp next
    printdone:
    ret

matchDigits:
    xor rbx, rbx
    loopDigits:
        xor rax, rax
        mov al, byte[fileCont + rbx]
        cmp al, '0'
        jb nextDig
        cmp al, '9'
        ja nextDig
        call putc
        nextDig:
        cmp rbx, qword[fileContLen]
        je endDigit
        inc rbx
        jmp loopDigits
    endDigit:
    call newLine
    ret

matchNonDigit:
    xor rbx, rbx
    loopNonDigits:
        xor rax, rax
        mov al, byte[fileCont + rbx]
        cmp al, '0'
        jb nextNonDig
        cmp al, '9'
        ja nextNonDig
        jmp notDigit
        nextNonDig:
        call putc
        notDigit:
        cmp rbx, qword[fileContLen]
        je endNonDigit
        inc rbx
        jmp loopNonDigits
    endNonDigit:
    call newLine
    ret

matchAlphanum:
    xor rbx, rbx
    loopAN:
        xor rax, rax
        mov al, byte[fileCont + rbx]
        cmp al, '_'
        jne dig
        call putc
        call trash
        dig:
        cmp al, '0'
        jb trash
        cmp al, '9'
        ja capChar
        call putc
        call trash
        capChar:
        cmp al, 'A'
        jb trash
        cmp al, 'Z'
        ja lowChar
        call putc
        call trash
        lowChar:
        cmp al, 'a'
        jb trash
        cmp al, 'z'
        ja trash
        call putc
        trash:
        cmp rbx, qword[fileContLen]
        je endAN
        inc rbx
        jmp loopAN
    endAN:
    call newLine
    ret


matchWhitespace:
    xor rbx, rbx
    loopW:
        xor rax, rax
        mov al, byte[fileCont + rbx]
        cmp al, 32
        jne otherW
        call putc
        call nextW
        otherW:
        cmp al, 11
        jb nextW
        cmp al, 13
        ja nextW
        call putc
        nextW:
        cmp rbx, qword[fileContLen]
        je endW
        inc rbx
        jmp loopW
    endW:
    call newLine
    ret
matchNonWhitespace:
    xor rbx, rbx
    loopNW:
        xor rax, rax
        mov al, byte[fileCont + rbx]
        cmp al, 32
        je notNW
        cmp al, 10
        jb nextNW
        cmp al, 13
        ja nextNW
        jmp notNW
        nextNW:
        call putc
        notNW:
        cmp rbx, qword[fileContLen]
        je endNW
        inc rbx
        jmp loopNW
    endNW:
    call newLine
    ret
; ------------------ helper functions ------------------
;input rdi = buffer address
resetBuffer:
   push rcx
   xor rcx, rcx
   setBuffer2Zero:
      mov qword[rdi + rcx], 0
      inc rcx
      cmp rcx, 10000
      jz endZero
      jmp setBuffer2Zero
   endZero:
   mov qword[rsi], 0
   pop rcx
   ret

getInput:
   xor rcx, rcx
   nextchar:
      xor rax, rax
      call getc
      cmp al, NL
      jz stopInp
      mov qword[rcx + rdi], rax
      inc rcx
      jmp nextchar
   stopInp:
   mov qword[rcx + rdi], 0
   ret

openAfile:

    mov rsi, openMsg
    call printString

    mov rdi, filePath
    call getInput 

    ;open file
    mov rdi, filePath
    mov rax, sys_open
    mov rsi, O_RDWR     
    syscall
    mov [fileDes], rax
    cmp rax, 0
    jge openExist

    mov rsi, openErr
    call printString
    call newLine
    ret


    openExist:


    ;read file and write to buffer
    mov rdi, [fileDes]
    mov rsi, fileCont
    mov rdx, 1000
    mov rax, sys_read
    syscall
    mov [fileContLen], rax

    ;close file
    mov rdi, [fileDes]
    mov rax, sys_close
    syscall

    mov rsi, openSuc
    call printString
    call newLine

    mov rsi, line
    call printString
    call newLine
    call newLine

    call printFile
    call newLine
    call newLine

    ret


getInformation:
    call newLine
    call info
    call showInfo
    call newLine
    ret
deleteWords:
    mov qword[deleteCount], 0
    
    mov rsi, delMsg
    call printString

    call readNum 
    mov qword[deleteCount], rax

    call delete

    mov rsi, delSuc
    call printString
    call newLine

    mov rsi, line
    call printString
    call newLine
    call newLine

    call printFile
    call newLine
    call newLine

    ret

findWord:
    mov rsi, searchMsg
    call printString

    mov rdi, find
    call getInput 

    xor r12, r12
    xor r13, r13
    mov r12, find
    mov r13, fileCont
    call search

    call showSearchResult
    call newLine
    ret

appendWord:
    mov rsi, appendMsg
    call printString

    mov rdi, appendStr
    call getInput 

    call append

    mov rsi, appSuc
    call printString
    call newLine

    mov rsi, line
    call printString
    call newLine
    call newLine

    call printFile
    call newLine
    call newLine

    ret

saveFile:
    call save
    mov rsi, saveSuc
    call printString

    call newLine
    ret

saveFileAs:
    mov rsi, saveAsMsg
    call printString

    mov rdi, newFilePath
    call getInput 

    call saveAs

    call newLine
    ret

searchAndReplace:
    call findWord

    xor rax, rax
    mov rax, qword[cnt]
    cmp rax, 0
    jnz getind
    ret

    getind:

    mov rsi, replaceMsg
    call printString

    call readNum
    mov qword[replaceInd], rax

    mov rsi, replaceMsgg
    call printString


    mov rdi, replaceWrd
    call getInput 

    call index2Replace

    mov rsi, replaceSuc
    call printString
    call newLine

    mov rsi, line
    call printString
    call newLine
    call newLine

    call printFile
    call newLine
    call newLine
    ret

regexSearch:
    mov rsi, regMsg
    call printString

    mov rdi, regCommand
    call getInput
    
    cmp byte[regCommand + 1], "d"
    jne reg1
    call matchDigits
    
    reg1:
    cmp byte[regCommand + 1], "D"
    jne reg2
    call matchNonDigit
    
    reg2:
    cmp byte[regCommand + 1], "w"
    jne reg3
    call matchAlphanum

    reg3:
    cmp byte[regCommand + 1], "s"
    jne reg4
    call matchWhitespace

    reg4:
    cmp byte[regCommand + 1], "S"
    jne reg5
    call matchNonWhitespace

    reg5:
    ret

_start:
    mov rsi, startMsg
    call printString
    call newLine

    inp:
    mov qword[cmd], 0
    mov rsi, commandMsg
    call printString

    mov rdi, cmd
    call getInput
    mov al, [cmd]

    cmp byte[cmd], "Q"
    je end

    cmp byte[cmd], "O"
    jne stop1
        call openAfile
        jmp inp

    stop1:
    cmp byte[cmd], "I"
    jne stop2
        call getInformation
        jmp inp

    stop2:
    cmp byte[cmd], "D"
    jne stop3
        call deleteWords
        jmp inp
    
    stop3:
    cmp byte[cmd], "S"
    jne stop4
        call findWord
        jmp inp

    stop4:
    cmp byte[cmd], "A"
    jne stop6
        call appendWord
        jmp inp

    stop6:
    cmp byte[cmd], "V"
    jne stop7
        call saveFile
        jmp inp

    stop7:
    cmp byte[cmd], "E"
    jne stop8
        call saveFileAs
        jmp inp
    
    stop8:
    cmp byte[cmd], "R"
    jne stop9
        call searchAndReplace
        jmp inp

    stop9:
    cmp byte[cmd], "X"
    jne stop10
        call regexSearch
        jmp inp

    stop10:
    mov rsi, invalidMsg
    call printString
    call newLine
    jmp inp

    end:

Exit:
    mov rax, sys_exit
    mov rdi, rdi
    syscall