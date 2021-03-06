%macro Descriptor 3	;段基址32位，段界限20位，属性16位
	dw	%2 & 0ffffh
	dw	%1 & 0ffffh
	db	(%1>>16) & 0ffh
	dw	(%2>>16) & 0fh | %3 & 0ffffh
	db	(%1>>24) & 0ffh
%endmacro

%macro Gate 4		;偏移32位，选择子32位，ParamCount8位，属性8位
	dw	%1 & 0ffffh
	dw	%2 & 0ffffh
	db	(%3 & 0ffh) 
	db	%4 & 0ffh
	dw	(%1>>16) & 0ffffh
%endmacro

;描述符属性
;7G 6D/B 50 4AVL 3-0LIMIT
;7P 6-5DPL 4S 3-0TYPE
;类型
DA_DPL0		EQU		00H
DA_DPL1		EQU		20H
DA_DPL2		EQU		40H
DA_DPL3		EQU		60H
DA_32		EQU		4000H	;D=1表示默认使用32位地址

;存储段 段在内存中存在P=1,S=1
DA_DR		EQU		10010000B	;TYPE=0只读
DA_DRW		EQU		10010010B	;TYPE=2读写
DA_DRWA		EQU		10010011B	;TYPE=3读写，已访问
DA_C		EQU		10011000B	;TYPE=8可执行
DA_CR		EQU		10011010B	;TYPE=A可读可执行
DA_CCO		EQU		10011100B	;TYPE=C可执行一致代码
DA_CCOR		EQU		10011110B	;TYPE=E可执行可读一致代码

;系统段 段在内存中存在P=1,S=0
DA_LDT		EQU		10000010B	;TYPE=2局部描述符表
DA_TASKGATE	EQU		10000101B	;TYPE=5任务门
DA_386TSS	EQU		10001001B	;TYPE=9任务状态段
DA_386CGATE	EQU		10001100B	;TYPE=C调用门
DA_386IGATE	EQU		10001110B	;TYPE=E中断门
DA_386TGATE	EQU		10001111B	;TYPE=F陷阱门

SA_TIL		EQU		0100B		;用第2位即TI位来区分LDT和GDT，TI=1时表示LDT
;打开A20
%macro EnableA20 0
	push	ax
	in	al, 92h
	or	al, 00000010b
	out	92h, al
	pop	ax
%endmacro

;关闭A20
%macro DisableA20 0
	push	ax
	in	al, 92h
	and	al, 11111101b
	out	92h, al
	pop	ax
%endmacro
