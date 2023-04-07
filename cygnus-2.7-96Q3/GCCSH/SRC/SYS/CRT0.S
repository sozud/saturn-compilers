	.section .text
	.global	start
start:
	mov.l	stack_k,r15

	! zero out bss
	mov.l	edata_k,r0
	mov.l	end_k,r1
	mov	#0,r2
start_l:
	 mov.l	r2,@r0
	add	#4,r0
	cmp/ge	r0,r1
	bt	start_l

	! call the mainline	
	mov.l	main_k,r0
	jsr	@r0
	or	r0,r0

	! call exit
	mov	r0,r4
	mov.l	exit_k,r0
	jsr	@r0
	or	r0,r0

	.align 2
stack_k:
	.long	_stack	
edata_k:
	.long	_edata
end_k:
	.long	_end
main_k:
	.long	_main
exit_k:
	.long	_exit

	.section .stack
_stack:	.long	0xdeaddead
