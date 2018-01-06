;pmtest2
;进入保护模式并返回到实模式
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

[SECTION .ldt]
LABEL_LDT:
DescriptorCode32_LDT	Descriptor 0, LenSegCode32_LDT-1, DA_C+DA_32
LenLdt			equ	$-LABEL_LDT

;段选择子
SelectorCode32_LDT	equ	DescriptorCode32_LDT-LABEL_LDT+SA_TIL

;数据段
[SECTION .data]
[BITS 32]
LABEL_SEG_DATA:
SPValueInRealMode	dw	0
szPMMessage		db	"In Protect Mode now.", 0	;在保护模式中显示
OffsetPMMessage		equ	szPMMessage-$$
szTest			db	"abcdefghijklmnopqrstuvwxyz", 0 ;在LDT段中显示
OffsetTest		equ	szTest-$$
LenSegData		equ	$-LABEL_SEG_DATA

;堆栈段
[SECTION .stack]
[BITS 32]
LABEL_SEG_STACK:
times 512 db 0
TopOfStack		equ 	$-LABEL_SEG_STACK-1

[SECTION .ldtcode]
[BITS 32]
LABEL_SEG_CODE32_LDT:
	mov	ax, SelectorData
	mov	ds, ax
	mov	ax, SelectorVideo
	mov	gs, ax

	mov	edi, (80*10+0)*2
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

	mov	edi, (80*3+0)*2		;屏幕第一行第一列
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
;Load LDT
	mov	ax, SelectorLDT
	lldt	ax
	jmp 	SelectorCode32_LDT:0
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
