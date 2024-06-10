.section .data
filename:
    .ascii               # Nome del file di testo da leggere
fd:
    .int 0               # File descriptor

buffer: .string ""       # Spazio per il buffer di input
newline: .byte 10        # Valore del simbolo di nuova linea
lines: .int 0            # Numero di linee
error_char: "❌ Errore - Letto char invalido dal file di input ❌ \n"
error_char_lenght: .long . - error_char

.section .bss

.section .text
    .globl _start

# Apre il file
_open:
    mov $5, %eax        # syscall open
    mov $filename, %ebx # Nome del file
    mov $0, %ecx        # Modalità di apertura (O_RDONLY)
    int $0x80           # Interruzione del kernel

    # Se c'è un errore, esce
    cmp $0, %eax
    jl _exit

    mov %eax, fd      # Salva il file descriptor in ebx

# Legge il file riga per riga
_read_loop:
    mov $3, %eax        # syscall read
    mov fd, %ebx        # File descriptor
    mov $buffer, %ecx   # Buffer di input
    mov $1, %edx        # Lunghezza massima
    int $0x80           # Interruzione del kernel

    cmp $0, %eax        # Controllo se ci sono errori o EOF
    jle _close_file     # Se ci sono errori o EOF, chiudo il file
    
    # Controllo se ho una nuova linea
    movb buffer, %al    # copio il carattere dal buffer ad AL
    cmpb newline, %al   # confronto AL con il carattere \n
    jne _check_char     # se sono diversi stampo la controllo il char
    incw lines          # altrimenti, incremento il contatore

_check_char:
    # Controlla se il carattere è un numero (0-9) o una virgola (,)
    cmpb $48, %al       # Controlla se il carattere è >= '0' (ASCII 48)
    jl _invalid_char    # Se è minore di '0', è un carattere non valido
    cmpb $57, %al       # Controlla se il carattere è <= '9' (ASCII 57)
    jle _save_line      # Se è un numero, salvalo
    cmpb $44, %al       # Controlla se il carattere è ','
    je _virgola_trovata # Se è una virgola, gestiscila

_invalid_char:
    # Gestione del carattere non valido
    
    jmp _close_file     # Salta alla gestione degli errori per il carattere non valido


_print_line:
    # Stampa il contenuto della riga
    mov $4, %eax        # syscall write
    mov $1, %ebx        # File descriptor standard output (stdout)
    mov $buffer, %ecx   # Buffer di output
    int $0x80           # Interruzione del kernel

    jmp _read_loop      # Torna alla lettura del file

# Chiude il file
_close_file:
    mov $6, %eax        # syscall close
    mov %ebx, %ecx      # File descriptor
    int $0x80           # Interruzione del kernel

_exit:
    mov $1, %eax        # syscall exit
    xor %ebx, %ebx      # Codice di uscita 0
    int $0x80           # Interruzione del kernel

_start:
    # Prende il parametro contenuto in %eax
    mov %eax, filename
    jmp _open          # Chiama la funzione per aprire il file

    # Fine programma
    jmp _exit
