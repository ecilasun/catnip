option casemap:none

includelib libucrt.lib
includelib libvcruntime.lib
includelib libcmt.lib
includelib kernel32.lib

.data
    msg db "Hello World!",0Ah, 00h
    msglen equ $-msg

.code
    extrn puts :NEAR
    extrn printf :NEAR
    extrn exit :NEAR
    PUBLIC main

main proc

sub rsp, 40
lea rcx, msg
call puts
add rsp, 40

xor eax,eax
push rax
call exit

main endp

end
