section .data
    prompt      db  'Enter statement : '   ; ข้อความที่จะแสดงให้ผู้ใช้พิมพ์
    prompt_len  equ $ - prompt             ; ความยาวของ prompt คำนวณจากตำแหน่งปัจจุบัน ($) ลบต้น prompt
    newline     db  10                     ; ASCII 10 = '\n' สำหรับขึ้นบรรทัดใหม่

section .bss
    buf     resb 32     ; buffer รับ input จากผู้ใช้ (สูงสุด 32 bytes)
    outbuf  resb 8      ; buffer สำหรับแปลงตัวเลข → string ก่อนพิมพ์

section .text
global _start       ; บอก linker ว่า _start คือจุดเริ่มต้นโปรแกรม (เหมือน main)
_start:

    mov     rax, 1              ; syscall number 1 = sys_write
    mov     rdi, 1              ; file descriptor 1 = stdout (หน้าจอ)
    mov     rsi, prompt         ; address ของ string ที่จะพิมพ์
    mov     rdx, prompt_len     ; จำนวน bytes ที่จะพิมพ์
    syscall                     ; เรียก kernel → พิมพ์ข้อความ

    mov     rax, 0              ; syscall number 0 = sys_read
    mov     rdi, 0              ; file descriptor 0 = stdin (แป้นพิมพ์)
    mov     rsi, buf            ; address ที่จะเก็บข้อมูลที่รับมา
    mov     rdx, 32             ; รับสูงสุด 32 bytes (ป้องกัน buffer overflow)
    syscall                     ; เรียก kernel → รอ user พิมพ์แล้วกด Enter

    mov     rsi, buf            ; ตั้ง pointer (rsi) ชี้มาที่ต้น buf
    xor     rbx, rbx            ; rbx = 0  (จะสะสมค่า Operand1 ที่นี่)

    movzx   rax, byte [rsi]     ; อ่าน 1 byte จาก address rsi → rax (zero-extend)
    cmp     al, ' '             ; เทียบกับ ASCII 32 = space
    jne     .read_digits_op1    ; ถ้าไม่ใช่ space → เริ่มอ่านตัวเลข
    inc     rsi                 ; ถ้าเป็น space → เลื่อน pointer ไปตัวถัดไป
    jmp     .skip_space_op1     ; วนซ้ำข้ามต่อ

    movzx   rax, byte [rsi]     ; อ่านตัวอักษรปัจจุบัน
    cmp     al, '0'             ; ตรวจว่า >= '0' (ASCII 48)
    jl      .done_op1           ; ถ้าน้อยกว่า → ไม่ใช่ตัวเลข หยุด
    cmp     al, '9'             ; ตรวจว่า <= '9' (ASCII 57)
    jg      .done_op1           ; ถ้ามากกว่า → ไม่ใช่ตัวเลข หยุด

    sub     al, '0'             ; แปลง ASCII → digit: '7' (55) - '0' (48) = 7
    imul    rbx, 10             ; เลื่อนหลัก: rbx × 10 เพื่อเปิดที่ให้หลักใหม่
    add     rbx, rax            ; บวกหลักใหม่: เช่น 12×10 + 3 = 123

    inc     rsi                 ; เลื่อน pointer ไปตัวอักษรถัดไป
    jmp     .read_digits_op1    ; วนอ่านหลักถัดไป

.done_op1:
.skip_to_op:
    movzx   rax, byte [rsi]     ; อ่านตัวอักษรปัจจุบัน
    cmp     al, ' '             ; ถ้าเป็น space → ข้าม
    je      .next_op_char

    cmp     al, '+'             ; เปรียบกับ +
    je      .found_op
    cmp     al, '-'             ; เปรียบกับ -
    je      .found_op
    cmp     al, '*'             ; เปรียบกับ *
    je      .found_op
    cmp     al, '/'             ; เปรียบกับ /
    je      .found_op

.next_op_char:
    inc     rsi                 ; ไม่ใช่ operator → เลื่อนต่อ
    jmp     .skip_to_op

.found_op:
    mov     r8b, al             ; เก็บ operator character ไว้ใน r8b
    inc     rsi                 ; เลื่อน pointer ผ่าน operator ไปยัง Operand2
    xor     rcx, rcx            ; rcx = 0 (จะสะสมค่า Operand2 ที่นี่)

.skip_space_op2:
    movzx   rax, byte [rsi]     ; อ่านตัวอักษรปัจจุบัน
    cmp     al, ' '             ; ถ้าเป็น space → ข้าม
    jne     .read_digits_op2
    inc     rsi
    jmp     .skip_space_op2

.read_digits_op2:
    movzx   rax, byte [rsi]     ; อ่านตัวอักษรปัจจุบัน
    cmp     al, '0'
    jl      .done_op2
    cmp     al, '9'
    jg      .done_op2

    sub     al, '0'             ; แปลง ASCII → digit
    imul    rcx, 10             ; เลื่อนหลัก
    add     rcx, rax            ; บวกหลักใหม่

    inc     rsi
    jmp     .read_digits_op2

.done_op2:

    cmp     r8b, '+'            ; operator คือ + ?
    je      do_add
    cmp     r8b, '-'            ; operator คือ - ?
    je      do_sub
    cmp     r8b, '*'            ; operator คือ * ?
    je      do_mul
    jmp     do_div              ; ถ้าไม่ใช่สามอย่างข้างบน ต้องเป็น /

do_add:
    mov     rax, rbx            ; rax = Operand1
    add     rax, rcx            ; rax = Operand1 + Operand2
    jmp     print_result

do_sub:
    mov     rax, rbx            ; rax = Operand1
    sub     rax, rcx            ; rax = Operand1 - Operand2
    jmp     print_result

do_mul:
    mov     rax, rbx            ; rax = Operand1
    imul    rax, rcx            ; rax = Operand1 × Operand2 (signed multiply)
    jmp     print_result

do_div:
    mov     rax, rbx            ; rax = Operand1 (dividend ตัวตั้ง)
    xor     rdx, rdx            ; ต้องเคลียร์ rdx = 0 ก่อนเสมอ
                                ; เพราะ div ใช้ rdx:rax (128-bit) ÷ rcx
                                ; ถ้า rdx มีขยะ → divide overflow crash ทันที
    div     rcx                 ; rax = quotient (ผลหารจำนวนเต็ม)
                                ; rdx = remainder (เศษ) ← ไม่ได้ใช้
    jmp     print_result

print_result:
    lea     rsi, [outbuf + 7]   ; ชี้ rsi ไปท้าย outbuf
                                ; จะค่อยๆ ถอยหน้ามาทีละ digit (เขียนจากหลังไปหน้า)
    xor     r9, r9              ; r9 = 0 นับจำนวน digit ที่เขียนแล้ว

.convert_loop:
    xor     rdx, rdx            ; เคลียร์ rdx ก่อนหารทุกครั้ง
    mov     r10, 10             ; ตัวหาร = 10
    div     r10                 ; rax ÷ 10 → quotient→rax, เศษ(digit)→rdx

    add     dl, '0'             ; แปลง digit → ASCII: 5 + 48 = '5'
    dec     rsi                 ; เลื่อน pointer ถอยหลัง 1 ตำแหน่ง
    mov     [rsi], dl           ; เขียน ASCII character ลง buffer

    inc     r9                  ; digit count++

    test    rax, rax            ; ตรวจว่า rax = 0 ไหม (หมดตัวเลขแล้ว)
    jnz     .convert_loop       ; ยังไม่ 0 → วนต่อ

    mov     rax, 1              ; sys_write
    mov     rdi, 1              ; stdout

    mov     rdx, r9             ; ความยาว = จำนวน digit ที่นับ
    syscall

    mov     rax, 1
    mov     rdi, 1
    mov     rsi, newline        ; ชี้ไปที่ newline byte (ASCII 10)
    mov     rdx, 1              ; พิมพ์ 1 byte
    syscall

    ; ── จบโปรแกรม ───────────────────────────
    mov     rax, 60             ; syscall number 60 = sys_exit
    xor     rdi, rdi            ; exit code = 0 (สำเร็จ)
    syscall
