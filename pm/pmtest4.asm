;pmtest4
;1.进入保护模式,输出'In Protect Mode now'
;2.进入R3,输出'3'
;3.通过调用门调用R0代码，输出大写字母
;4.调用局部描述符的代码段，输出小写字母
;5.返回到实模式
%include "pm.inc"
	org	0100h
	jmp	LABEL_BEGIN

;段描述符
[SECTION .gdt]
LABEL_GDT:
DescriptorGDT 		Descriptor 0, 0, 0
DescriptorNormal	Descriptor 0, 0ffffh, DA_DRW
DescriptorCode32 	Descriptor 0, LenSegCode32-1, DA_C+DA_32
DescriptorCode16	Descriptor 0, 0ffffh, DA_C
DescriptorVideo		Descriptor 0b8000h, 0ffffh, DA_DRW
DescriptorData		Descriptor 0, LenSegData-1, DA_DRW
DescriptorStack		Descriptor 0, TopOfStack, DA_DRWA+DA_32
DescriptorLDT		Descriptor 0, LenLdt-1, DA_LDT

DescriptorCodeGate	Descriptor 0, LenSegCode32_Gate-1, DA_C+DA_32
DescriptorGate		Gate 0, SelectorCodeGate, 0, DA_386CGATE+DA_DPL3
DescriptorTss		Descriptor 0, LenSegTss-1, DA_386TSS

DescriptorCode_r3	Descriptor 0, LenSegCode_r3, DA_C+DA_32+DA_DPL3
DescriptorStack_r3	Descriptor 0, TopOfStack3, DA_DRWA+DA_32+DA_DPL3
DescriptorVideo_r3	Descriptor 0b8000h, 0ffffh, DA_DRW+DA_DPL3

;GDTR
LenGDT			equ	$-DescriptorGDT
PtrGDT			dw	LenGDT-1
			dd	0

;段选择子
SelectorNormal		equ 	DescriptorNormal-LABEL_GDT
SelectorCode32		equ	DescriptorCode32-LABEL_GDT
SelectorCode16		equ	DescriptorCode16-LABEL_GDT
SelectorVideo		equ	DescriptorVideo-LABEL_GDT
SelectorData		equ	DescriptorData-LABEL_GDT
SelectorStack		equ	DescriptorStack-LABEL_GDT
SelectorLDT		equ	DescriptorLDT-LABEL_GDT

SelectorCodeGate	equ	DescriptorCodeGate-LABEL_GDT
SelectorGate		equ	DescriptorGate-LABEL_GDT+SA_RPL3
SelectorTss		equ	DescriptorTss-LABEL_GDT

SelectorCode_r3		equ	DescriptorCode_r3-LABEL_GDT+SA_RPL3
SelectorStack_r3	equ	DescriptorStack_r3-LABEL_GDT+SA_RPL3
SelectorVideo_r3	equ	DescriptorVideo_r3-LABEL_GDT+SA_RPL3

[SECTION .ldt]
LABEL_LDT:
DescriptorCode32_LDT	Descriptor 0, LenSegCode32_LDT-1, DA_C+DA_32
LenLdt			equ	$-LABEL_LDT

;段选择子
SelectorCode32_LDT	equ	DescriptorCode32_LDT-LABEL_LDT+SA_TIL

;TSS
[SECTION .tss]
[BITS 32]
LABEL_SEG_TSS:
	dd	0			;上一任务链接
	dd	TopOfStack		;第0级堆栈
	dd	SelectorStack
	dd	0			;第1级堆栈
	dd	0
	dd	0			;第2级堆栈
	dd	0
	dd	0			;CR3
	dd	0			;EIP
	dd	0			;EFLAGS
	dd	0			;EAX
	dd	0			;ECX
	dd	0			;EDX
	dd	0			;EBX
	dd	0			;ESP
	dd	0			;EBP
	dd	0			;ESI
	dd	0			;EDI
	dd	0			;ES
	dd	0			;CS
	dd	0			;SS
	dd	0			;DS
	dd	0			;FS
	dd	0			;GS
	dd	0			;LDT
	DW	0			;调试陷阱标志T
	DW	$-LABEL_SEG_TSS+2	;I/O位图基址
	DB	0ffh			;I/O位图结束标志
LenSegTss		equ	$-LABEL_SEG_TSS

;数据段
[SECTION .data]
[BITS 32]
LABEL_SEG_DATA:
SPValueInRealMode	dw	0
szPMMessage		db	"In Protect Mode now.", 0	;在保护模式中显示
OffsetPMMessage		equ	szPMMessage-$$
szTest			db	"abcdefghijklmnopqrstuvwxyz", 0 ;在LDT段中显示
OffsetTest		equ	szTest-$$
szTest2			db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0 ;在门调用时使用
OffsetTest2		equ	szTest2-$$
LenSegData		equ	$-LABEL_SEG_DATA

;堆栈段
[SECTION .stack]
[BITS 32]
LABEL_SEG_STACK:
times 512 db 0
TopOfStack		equ 	$-LABEL_SEG_STACK-1

;R3下代码段
[SECTION .code3]
[BITS 32]
LABEL_SEG_CODE_R3:
	mov	ax, SelectorVideo_r3
	mov	gs, ax

	mov	edi, (80*15+3)*2
	mov	ah, 0ch
	mov	al, '3'
	mov	[gs:edi], ax

	call	SelectorGate:0
	jmp	$
LenSegCode_r3		equ	$-LABEL_SEG_CODE_R3

;R3下堆栈段
[SECTION .stack3]
[BITS 32]
LABEL_SEG_STACK_R3:
	times 512 db 0
TopOfStack3		equ	$-LABEL_SEG_STACK_R3-1

;门调用代码段
[SECTION .gatecode]
[BITS 32]
LABEL_SEG_CODE32_GATE:
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	ax, SelectorData
	mov	ds, ax
	mov	esi, OffsetTest2
	mov	edi, (80*5+1)*2
	mov	ah, 0ch
.1:
	lodsb
	test	al, al
	jz	.2
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1
.2:
;Load LDT
	mov	ax, SelectorLDT
	lldt	ax
	jmp 	SelectorCode32_LDT:0

LenSegCode32_Gate	equ	$-LABEL_SEG_CODE32_GATE

;由LDT访问的代码段
[SECTION .ldtcode]
[BITS 32]
LABEL_SEG_CODE32_LDT:
	mov	ax, SelectorData
	mov	ds, ax
	mov	ax, SelectorVideo
	mov	gs, ax

	mov	edi, (80*10+2)*2
	mov	esi, OffsetTest
	mov	ah, 0ch
	cld
.1:
	lodsb	
	test	al, al
	jz	.2
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1
.2:
	jmp	SelectorCode16:0	
LenSegCode32_LDT	equ	$-LABEL_SEG_CODE32_LDT

;入口处16位代码
[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	mov	[LABEL_GO_REAL+3], ax
	mov	word [SPValueInRealMode], sp

;初始化16位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE16
	mov	word [DescriptorCode16+2], ax
	shr	eax, 16
	mov 	byte [DescriptorCode16+4], al
	mov	byte [DescriptorCode16+7], ah

;初始化32位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [DescriptorCode32+2], ax
	shr	eax, 16
	mov 	byte [DescriptorCode32+4], al
	mov	byte [DescriptorCode32+7], ah

;初始化数据段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_SEG_DATA
	mov	word [DescriptorData+2], ax
	shr	eax, 16
	mov 	byte [DescriptorData+4], al
	mov	byte [DescriptorData+7], ah

;初始化堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_SEG_STACK
	mov	word [DescriptorStack+2], ax
	shr	eax, 16
	mov 	byte [DescriptorStack+4], al
	mov	byte [DescriptorStack+7], ah

;初始化R3下代码段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_SEG_CODE_R3
	mov	word [DescriptorCode_r3+2], ax
	shr	eax, 16
	mov 	byte [DescriptorCode_r3+4], al
	mov	byte [DescriptorCode_r3+7], ah
	
;初始化R3下堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_SEG_STACK_R3
	mov	word [DescriptorStack_r3+2], ax
	shr	eax, 16
	mov 	byte [DescriptorStack_r3+4], al
	mov	byte [DescriptorStack_r3+7], ah

;初始化TSS段
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_SEG_TSS
	mov	word [DescriptorTss+2], ax
	shr	eax, 16
	mov 	byte [DescriptorTss+4], al
	mov	byte [DescriptorTss+7], ah

;初始化调用门的代码段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32_GATE
	mov	word [DescriptorCodeGate+2], ax
	shr	eax, 16
	mov	byte [DescriptorCodeGate+4], al
	mov	byte [DescriptorCodeGate+7], ah

;初始化LDT在GDT中的描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_LDT
	mov	word [DescriptorLDT+2], ax
	shr	eax, 16
	mov	byte [DescriptorLDT+4], al
	mov	byte [DescriptorLDT+7], ah

;初始化LDT代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32_LDT
	mov	word [DescriptorCode32_LDT+2], ax
	shr	eax, 16
	mov 	byte [DescriptorCode32_LDT+4], al
	mov	byte [DescriptorCode32_LDT+7], ah

;准备加载gdtr
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add 	eax, LABEL_GDT
	mov	dword [PtrGDT+2], eax

;加载gdtr
	lgdt	[PtrGDT]

;关中断
	cli

;打开A20
	EnableA20

;进入保护模式,将CR0的第0位PE置1,PE=0时CPU运行于实模式，置1时进入保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax
	jmp	dword SelectorCode32:0

;32位代码段,由实模式进入
[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
	mov	ax, SelectorData
	mov	ds, ax
	mov	ax, SelectorStack
	mov	ss, ax
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	esp, TopOfStack

	mov	edi, (80*1+1)*2		;屏幕第一行第一列
	mov	esi, OffsetPMMessage
	mov	ah, 0ch
	cld
.1:
	lodsb
	test	al, al
	jz	.2
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1
.2:
;Enter the ring3
	mov	ax, SelectorTss
	ltr	ax

	push	SelectorStack_r3
	push	TopOfStack3
	push	SelectorCode_r3
	push	0
	retf
LenSegCode32		equ	$-LABEL_SEG_CODE32

;跳转到进入实模式的代码
[SECTION .s16]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
	mov	ax, SelectorNormal
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax

	mov	eax, cr0
	and	eax, 0fffffffeh
	mov	cr0, eax
LABEL_GO_REAL:
	jmp	0:LABEL_REAL_ENTRY	
LenSegCode16		equ	$-LABEL_SEG_CODE16

[SECTION .real]
[BITS 16]
LABEL_REAL_ENTRY:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, [SPValueInRealMode]

;关闭A20
	DisableA20

;开中断
	sti

;回到DOS
	mov	ax, 4c00h
	int	21h			

