[org 0x1000]

mov     si, loader   ; 1 传入字符串
call    print     ; 2 调用

detect_memory:
    ; 将 ebx 置为 0
    xor ebx, ebx

    ; es:di 结构体的缓存位置
    mov ax, 0
    mov es, ax
    mov edi, ards_buffer

    mov edx, 0x534d4150; 固定签名

.next:
    ; 子功能号
    mov eax, 0xe820
    ; ards 结构的大小 (字节)
    mov ecx, 20
    ; 调用 0x15 系统调用
    int 0x15

    ; 如果 CF 置位，表示出错
    jc error

    ; 将缓存指针指向下一个结构体
    add di, cx

    ; 将结构体数量加一
    inc word [ards_count]

    cmp ebx, 0
    jnz .next

    mov si, detecting
    call print

    jmp prepare_protected_mode

; 如何调用
; mov     si, msg   ; 1 传入字符串
; call    print     ; 2 调用
print:
    mov ah, 0x0e
    mov bh, 0
    mov bl, 0x01
.loop:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10

    inc si
    jmp .loop
.done:
    ret

prepare_protected_mode:

    cli; 关闭中断

    ; 打开 A20 线
    in al,  0x92
    or al, 0b10
    out 0x92, al

    lgdt [gdt_ptr]; 加载 gdt

    ; 启动保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp code_selector:protect_mode

[bits 32]
protect_mode:
    ;xchg bx, bx; 断点
    mov ax, data_selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax; 初始化段寄存器,

    mov byte [0xb8000], 'P'

    mov edi, 0x10000; 读取的目标内存
    mov ecx, 3; 起始扇区
    mov bl, 200; 扇区数量

    call read_disk

    ; xchg bx, bx; 断点

    mov eax, 0x20220205; 内核魔数
    mov ebx, ards_count; ards 数量指针

    jmp code_selector:0x10040

read_disk:
    ; 设置读写扇区的数量
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx; 0x1f3
    mov al, cl; 起始扇区的前八位
    out dx, al

    inc dx; 0x1f4
    shr ecx, 8
    mov al, cl; 起始扇区的中八位
    out dx, al

    inc dx; 0x1f5
    shr ecx, 8
    mov al, cl; 起始扇区的高八位
    out dx, al

    inc dx; 0x1f6
    shr ecx, 8
    and cl, 0b1111; 将高四位置为 0

    mov al, 0b1110_0000;
    or al, cl
    out dx, al; 主盘 - LBA 模式

    inc dx; 0x1f7
    mov al, 0x20; 读硬盘
    out dx, al

    xor ecx, ecx; 将 ecx 清空
    mov cl, bl; 得到读写扇区的数量

    .read:
        push cx; 保存 cx
        call .waits; 等待数据准备完毕
        call .reads; 读取一个扇区
        pop cx; 恢复 cx
        loop .read
    ret

    .waits:
        mov dx, 0x1f7
        .check:
            in al, dx
            and al, 0b1000_1000
            cmp al, 0b0000_1000
            jnz .check
        ret

    .reads:
        mov dx, 0x1f0
        mov cx, 256; 一个扇区 256 字
        .readw:
            in ax, dx
            mov [edi], ax
            add edi, 2
            loop .readw
        ret


code_selector equ (1 << 3)
data_selector equ (2 << 3)

memory_base equ 0; 内存开始的位置：基地址

; 内存界限 4G / 4K - 1
memory_limit equ ((1024 * 1024 * 1024 * 4) / (1024 * 4)) - 1

gdt_ptr:
    dw (gdt_end - gdt_base) - 1
    dd gdt_base
gdt_base:
    dd 0, 0; NULL 描述符
gdt_code:
    dw memory_limit & 0xffff; 段界限 0 ~ 15 位
    dw memory_base & 0xffff; // 基地址 0 ~ 16 位
    db (memory_base >> 16) & 0xff; // 基地址 0 ~ 16 位
    ; 存在 - dlp 0 - S _ 代码 - 非依从 - 可读 - 没有被访问过
    db 0b_1_00_1_1_0_1_0;
    ; 4k - 32 位 - 不是 64 位 - 段界限 16 ~ 19
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf;
    db (memory_base >> 24) & 0xff; 基地址 24 ~ 31 位
gdt_data:
    dw memory_limit & 0xffff; 段界限 0 ~ 15 位
    dw memory_base & 0xffff; // 基地址 0 ~ 16 位
    db (memory_base >> 16) & 0xff; // 基地址 0 ~ 16 位
    ; 存在 - dlp 0 - S _ 数据 - 向上 - 可写 - 没有被访问过
    db 0b_1_00_1_0_0_1_0;
    ; 4k - 32 位 - 不是 64 位 - 段界限 16 ~ 19
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf;
    db (memory_base >> 24) & 0xff; 基地址 24 ~ 31 位
gdt_end:

detecting:
    db "Detecting Memory Success...", 10, 13, 0; \n\r

error:
    mov si, .msg
    call print
    hlt; 让 CPU 停止
    jmp $
    .msg db "Loading Error!!!", 10, 13, 0

loader:
    db "Loader my os...", 10, 13, 0; \n\r

ards_count:
    dd 0
ards_buffer: