;pmtest1
%include "pm.inc"
	org	0100h
	jmp	LABEL_BEGIN

;段描述符
[SECTION .gdt]
DescriptorGDT 		Descriptor 0, 0, 0
DescriptorCode32 	Descriptor 0, LenSegCode32-1, DA_C+DA_32
DescriptorVideo		Descriptor 0b8000h, 0ffffh, DA_DRW

;GDTR
LenGdt			equ	$-DescriptorGDT
GdtPtr			dw	LenGdt-1
			dd	0

;段选择子
SelectorCode32		equ	DescriptorCode32-DescriptorGDT
SelectorVideo		equ	DescriptorVideo-DescriptorGDT

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax

;初始化32位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [DescriptorCode32+2], ax
	shr	eax, 16
	mov 	byte [DescriptorCode32+4], al
	mov	byte [DescriptorCode32+7], ah

;准备加载gdtr
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add 	eax, DescriptorGDT
	mov	dword [GdtPtr+2], eax

;加载gdtr
	lgdt	[GdtPtr]

;关中断
	cli

;打开A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

;进入保护模式,将CR0的第0位PE置1,PE=0时CPU运行于实模式，置1时进入保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax
	jmp	dword SelectorCode32:0

[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	edi, (80*11+79)*2		;屏幕第一行第一列
	mov	ah, 0ch
	mov	al, 'P'
	mov	[gs:edi], ax
	jmp	$
;StrHelloWorld		db	'Hello,OS'
LenSegCode32		equ	$-LABEL_SEG_CODE32
