;-------------------------------------------------
;microcontroller : MSP430G2231
;assembler       : naken430asm
;-------------------------------------------------
.include "msp430g2x31.inc"
 
;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
#define TASK_INDEX 0x27e           ;task index in 0x27e
#define TASK_BASE 0x27             ;base address of SP backup array
#define MAX_TASK 3                 ;maximun tasks
#define TASK1_TOS 0x278            ;top of the stack of task1
#define TASK2_TOS 0x252
#define TASK3_TOS 0x22a
;;;;;;;;;;;;SETTING TIMER INTERRUPT AND SOME INITIAL VALUES;;;;;; 
org 0xf800
start: 
  mov.w #(WDTPW|WDTHOLD), &WDTCTL           ;disable watchdog
  mov.b #255,&P1DIR                         ;set PORT1 as output
  mov.b #0, &P1OUT                          ;clear PORT1
  mov.w #(TASSEL_2|MC_1|ID_3), &TACTL       ;set timer control register
  mov.w #(CCIE), &TACCTL0                   ;enable CC interrupt
  mov.w #50, &TACCR0                        ;set CC interrupt threshold
  mov.w #0,&TASK_INDEX                      ;set task index to 0
  mov.w #TASK2, &(TASK2_TOS-2);             ;push task2 start address for 1st pop
  mov.w #TASK3, &(TASK3_TOS-2);             ;push task3 start address for 1st po
  mov.w #(TASK2_TOS - 14), &(TASK_BASE +2)  ;backup task2 SP for 1st pop
  mov.w #(TASK3_TOS - 14), &(TASK_BASE +4)  ;backup task3 SP for 1st pop
  mov.w #TASK1_TOS, SP                      ;set SP before task1 
  eint                                      ;global interrupt enable
  mov SR, &(TASK2_TOS - 4)                  ;set initial SR for task2 for 1st pop
  mov SR, &(TASK3_TOS - 4)                  ;set initial SR for task3 for 1st pop
  mov #TASK1,PC                             ;begin task 1
 
;;;;;;;;;;;;TASK SWITCHING ROUTINE (ON TIMER INTERRUPT);;;;;;;;;;   
isr:                                       ;reach here on interrupt
 push r4                                   ;push register to stack
 push r5                                                        
 push r6
 push r7
 push r8
 mov.w &TASK_INDEX, r4          ;mov current task index to r4
 mov.w SP,TASK_BASE(r4)         ;mov current paused task SP to backup array  
 incd r4                        ;double increment the index
 cmp #(MAX_TASK * 2), r4        ;check index reached maximum value
 jne notequal                                                
 clr r4                         ;if yes, clear index
notequal:           
 mov.w TASK_BASE(r4),SP         ;now restore SP of next task (going to switch now]
 mov.w r4, &TASK_INDEX          ;now save the current task index
 pop r8                         ;pop registers 
 pop r7
 pop r6
 pop r5
 pop r4
 pop SR                         ;pop status register  
 pop PC                         ;pop program counter [task swithing]
 
;;;;;;;;;;;;;TASK 1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
TASK1:                                                                     
 xor.b #(1<<0), &P1OUT
 mov #60000, R4
loop1:
 dec R4
 jnz loop1
 jmp TASK1
  
 
;;;;;;;;;;;;;TASK 2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
TASK2: 
 xor.b #(1<<6), &P1OUT
 mov #10000,R4
loop2: 
 dec R4
 jnz loop2
 jmp TASK2
 
 
;;;;;;;;;;;;TASK 3;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
TASK3:
 xor.b #(1<<1),&P1OUT
 call #delay3
 jmp TASK3
;delay subroutine
delay3:
 mov #0xffff, R4
loop3: dec R4
 nop
 nop
 jnz loop3
  ret
 
;;;;;;;;;;;;;;;;;VECTORS;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
org 0xfffe                  ;reset vector
       dw start             ;to write start address to 0xfffe on programming
org 0xfff2                  ;timer interrupt vector (CC)
       dw isr               ;to write isr address to 0xfff2 on programming
