;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Mall för lab1 i TSEA28 Datorteknik Y
;;
;; 210105 KPa: Modified for distance version
;;

	;; Ange att koden är för thumb mode
	.thumb
	.text
	.align 2

	;; Ange att labbkoden startar här efter initiering
	.global	main
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Ange vem som skrivit koden
;;               student LiU-ID: jakre732
;; + ev samarbetspartner LiU-ID: axenc178
;;
;; Placera programmet här

; Korrekt kod: 4 3 2 1

main:				; Start av programmet
	bl inituart
	bl initGPIOE
	bl initGPIOF

	; Set correct code: 1 2 3 4
	mov r0, #(0x20001010 & 0xffff)
	movt r0, #(0x20001010 >> 16)
	mov r1, #4
	str r1, [r0]

	mov r0, #(0x20001011 & 0xffff)
	movt r0, #(0x20001011 >> 16)
	mov r1, #3
	str r1, [r0]

	mov r0, #(0x20001012 & 0xffff)
	movt r0, #(0x20001012 >> 16)
	mov r1, #2
	str r1, [r0]

	mov r0, #(0x20001013 & 0xffff)
	movt r0, #(0x20001013 >> 16)
	mov r1, #1
	str r1, [r0]

	mov r7, #0		; r7 är reserverad för att hålla koll på blink

activate:
	bl activatealarm

clear_buffer:
	bl clearinput

input:
	bl getkey			; Kalla på getkey som loopar tills en knapt tryckt in
	cmp r4, #0xF
	beq check_code		; Hopp om
	cmp r4, #9
	bgt clear_buffer
	bl addkey			; Om ja, anropa addkey med tangent sparad i r4
	b input

check_code:
	bl checkcode
	cmp r4, #1
	beq deactivate		; If code is correct, go to deactivate_alarm
	adr r4, str_wrong			; else, print "Felaktig kod!" and go to clear_buffer
	mov r5, #13
	bl printstring
	b clear_buffer


deactivate:
	bl deactivatealarm

get_a_key:
	bl getkey
	cmp r4, #0xA
	beq activate
	b get_a_key

str_wrong:
	.align 4
	.string "Felaktig kod!", 10, 13

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Pekare till strängen i r4
; Längd på strängen i r5
; Utargument: Inga
;
; Funktion: Skriver ut strängen mha subrutinen printchar

printstring:
	; Loopa igenom hela strängen
	push {lr}

loop:

	ldrb r0, [r4]	; Läs en byte från minne r4 och öka pekaren med 1
	bl printchar		; Kalla på printchar som skriver ut bokstaven i r0
	add r4, r4, #1
	subs r5, r5, #1		; Subtrahera 1 från r5 och sätter Z flaggan
	bne loop			; Kollar på Z flaggan: resultatet på subtraktionen är 0 hoppar programmet till stop
	mov r0, #0x0d
	bl printchar
	mov r0, #0x0a
	bl printchar
	pop {lr}
	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Inga
;
; Funktion: Tänder grön lysdiod (bit 3 = 1, bit 2 = 0, bit 1 = 0)
; Förstör r1 och r2
deactivatealarm:
	mov r1, #(GPIOF_GPIODATA & 0xffff)	; Hämta serieport
	movt r1,#(GPIOF_GPIODATA >> 16)		; Justera de 16 MSB

	ldr r2, [r1]			; Ladda in värdet (r1 är en pekare till GPIOF_GPOIFDATA-värdet) från r1 till r2
	orr r2, r2, #0x08		; Se till att bit 3 i r2 är 1 (xxxx xxxx | 0000 1000 = xxxx 1xxx) och lagra det i r2
	and r2, r2, #0x08		; Se till att alla andra värden i r2 är 0 (xxxx 1xxx & 0000 1000 = 0000 1000)
	str r2, [r1]			; Lägg värdet i r2 i adressen till r1

	bx lr


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Inga
;
; Funktion: Tänder röd lysdiod (bit 3 = 0, bit 2 = 0, bit 1 = 1)
; Förstör r1 och r2
activatealarm:
	mov r1, #(GPIOF_GPIODATA & 0xffff)	; Hämta serieport
	movt r1,#(GPIOF_GPIODATA >> 16)		; Justera de 16 MSB
	ldr r2, [r1]			; Ladda in värdet (r1 är en pekare till GPOIF_GPOIFDATA-värdet) från r1 till r2
	orr r2, r2, #0x02		; Samma princip som deactivatealarm, fast med bit 3 = 0 och bit 1 = 1
	and r2, r2, #0x02
	str r2, [r1]

	bx lr



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Tryckt knappt returneras i r4
;
; Funktion: Hämtar vilken knapp som tryckts och lägger den i r4
getkey:
	push {lr}

; Loopar medans bit 4 är 0 (ej tryckt knapp)
loop_not_pressed:
	bl blink
	mov r1, #(GPIOE_GPIODATA & 0xffff)	; Hämta serieport
	movt r1, #(GPIOE_GPIODATA >> 16)		; Justera de 16 MSB
	ldr r4, [r1]		; Ladda in värdet (r1 är pekare till GPOIE_GPOIEDATA-värdet) från r1 till r2
	ands r2, r4, #0x10		; Testar bit 4, #0x10 eftersom 10 hex = 0001 0000 (4:e biten)
	beq loop_not_pressed	 		; Om bit 4 är 0, hoppa till loop_pressed

; Loopar medans bit 4 är 1 (tryckt knapp)
loop_pressed:
	bl blink
	ldrb r4, [r1]		; Ladda in värdet från r1 till r4
	ands r2, r4, #0x10		; Testar bit 4 igen
	bne loop_pressed			; Om bit 4 är 0, hoppa till exit
	and r4, #0xF		; Justera ifall bit 5 lyser
	pop {lr}
	bx lr				; Annars, gå tillbaka till huvudfunktionen

; Adderar 1 till register r7. Om r7 > 8 miljoner,
blink:
	push {lr}
	mov r6, #(GPIOF_GPIODATA & 0xffff)
	movt r6, #(GPIOF_GPIODATA >> 16)
	ldrb r5, [r6]
	ands r2, r5, #0x08	; Testar bit 3
	bne return		; Hopp om bit 3 är 1 (lyser grönt), avsluta

	; Nu vet vi att larmet är aktiverat
	add r7, #1		; Addera 1 till r7
	cmp r7, #0x80000		; Jämför r7 med ca 800'000
	blt return		; Hopp om r7 < 8'000'000

	; Nu vet vi att vi ska ändra färgen på LED:n, men inte vilken färg
	mov r7, #0
	ldrb r5, [r6]
	ands r2, r5, #0x02	; Testar bit 1
	bne set_blank		; Hopp om bit 1 är 1 (lyser rött, måste sätta LED: till svart

	; Nu vet vi att vi måste sätta på röd färg
	orr r5, r5, #0x02		; Samma princip som deactivatealarm
	and r5, r5, #0x02
	str r5, [r6]

	bl return

set_blank:
	mov r5, #0x0
	str r5, [r6]
	bl return

return:
	pop {lr}
	bx lr



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Vald tangent i r4
; Utargument: Inga
;
; Funktion: Flyttar innehållet på 0x20001000-0x20001002 framåt en byte
; till 0x20001001-0x20001003. Lagrar sedan innehållet i r4 på
; adress 0x20001000.
addkey:
	mov r0, #(GUESS_FOUR & 0xffff)		; Peka på 4:e platsen vi kommer lagra data på
	movt r0, #(GUESS_FOUR >> 16)

	mov r1, #(GUESS_THREE & 0xffff)		; Peka på 3:e platsen vi kommer lagra data på
	movt r1, #(GUESS_THREE >> 16)

	ldrb r2, [r1]			; Ladda in värdet i r1 till r2
	strb r2, [r0]			; Lagra värdet i r2 hos r0's minnescell


	mov r0, #(GUESS_THREE & 0xffff)	; Samma princip, olika adresser
	movt r0, #(GUESS_THREE >> 16)

	mov r1, #(GUESS_TWO & 0xffff)
	movt r1, #(GUESS_TWO >> 16)

	ldrb r2, [r1]
	strb r2, [r0]


	mov r0, #(GUESS_TWO & 0xffff)
	movt r0, #(GUESS_TWO >> 16)

	mov r1, #(GUESS_ONE & 0xffff)
	movt r1, #(GUESS_ONE >> 16)

	ldrb r2, [r1]
	strb r2, [r0]

	strb r4, [r1]			; Lagra nya datan från r4 i r1

	bx lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Inga
;
; Funktion: Sätter innehållet på 0x20001000-0x20001003 till 0xFF
clearinput:

	mov r1, #0xFF			; Sätt r1 till 0xFF

	mov r0, #(GUESS_FOUR & 0xffff)
	movt r0, #(GUESS_FOUR >> 16)
	strb r1, [r0]			; Lagra 0xFF i värdet hos r0

	mov r0, #(GUESS_THREE & 0xffff)
	movt r0, #(GUESS_THREE >> 16)
	strb r1, [r0]

	mov r0, #(GUESS_TWO & 0xffff)
	movt r0, #(GUESS_TWO >> 16)
	strb r1, [r0]

	mov r0, #(GUESS_ONE & 0xffff)
	movt r0, #(GUESS_ONE >> 16)
	strb r1, [r0]

	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Returnerar 1 i r4 om koden var korrekt, annars 0 i r4
checkcode:
    mov r0, #(0x20001010 & 0xffff)
    movt r0, #(0x20001010 >> 16)
    ldr r1, [r0]

    mov r0, #(0x20001000 & 0xffff)
    movt r0, #(0x20001000 >> 16)
    ldr r2, [r0]

    cmp r1, r2
    bne code_not_equal

    mov r4, #1            ; Om allt passerat, lägg in värde 1 i register 4
    bx lr

code_not_equal:
    mov r4, #0            ; If any checks failed, set r4 to 0
    bx lr                 ; Quit


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Definitioner för minneslagring
GUESS_ONE	.equ	0x20001000
GUESS_TWO	.equ	0x20001001
GUESS_THREE	.equ	0x20001002
GUESS_FOUR	.equ	0x20001003
CORRECT_ONE	.equ	0x20001010
CORRECT_TWO	.equ	0x20001011
CORRECT_THREE	.equ	0x20001012
CORRECT_FOUR	.equ	0x20001013


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,
;;;
;;; Allt här efter ska inte ändras
;;;
;;; Rutiner för initiering
;;; Se labmanual för vilka namn som ska användas
;;;
	
	.align 4

;; 	Initiering av seriekommunikation
;;	Förstör r0, r1 
	
inituart:
	mov r1,#(RCGCUART & 0xffff)		; Koppla in serieport
	movt r1,#(RCGCUART >> 16)
	mov r0,#0x01
	str r0,[r1]

	mov r1,#(RCGCGPIO & 0xffff)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x01
	str r0,[r1]		; Koppla in GPIO port A

	nop			; vänta lite
	nop
	nop

	mov r1,#(GPIOA_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOA_GPIOAFSEL >> 16)
	mov r0,#0x03
	str r0,[r1]		; pinnar PA0 och PA1 som serieport

	mov r1,#(GPIOA_GPIODEN & 0xffff)
	movt r1,#(GPIOA_GPIODEN >> 16)
	mov r0,#0x03
	str r0,[r1]		; Digital I/O på PA0 och PA1

	mov r1,#(UART0_UARTIBRD & 0xffff)
	movt r1,#(UART0_UARTIBRD >> 16)
	mov r0,#0x08
	str r0,[r1]		; Sätt hastighet till 115200 baud
	mov r1,#(UART0_UARTFBRD & 0xffff)
	movt r1,#(UART0_UARTFBRD >> 16)
	mov r0,#44
	str r0,[r1]		; Andra värdet för att få 115200 baud

	mov r1,#(UART0_UARTLCRH & 0xffff)
	movt r1,#(UART0_UARTLCRH >> 16)
	mov r0,#0x60
	str r0,[r1]		; 8 bit, 1 stop bit, ingen paritet, ingen FIFO
	
	mov r1,#(UART0_UARTCTL & 0xffff)
	movt r1,#(UART0_UARTCTL >> 16)
	mov r0,#0x0301
	str r0,[r1]		; Börja använda serieport

	bx  lr

; Definitioner för registeradresser (32-bitars konstanter) 
GPIOHBCTL	.equ	0x400FE06C
RCGCUART	.equ	0x400FE618
RCGCGPIO	.equ	0x400fe608
UART0_UARTIBRD	.equ	0x4000c024
UART0_UARTFBRD	.equ	0x4000c028
UART0_UARTLCRH	.equ	0x4000c02c
UART0_UARTCTL	.equ	0x4000c030
UART0_UARTFR	.equ	0x4000c018
UART0_UARTDR	.equ	0x4000c000
GPIOA_GPIOAFSEL	.equ	0x40004420
GPIOA_GPIODEN	.equ	0x4000451c
GPIOE_GPIODATA	.equ	0x400240fc
GPIOE_GPIODIR	.equ	0x40024400
GPIOE_GPIOAFSEL	.equ	0x40024420
GPIOE_GPIOPUR	.equ	0x40024510
GPIOE_GPIODEN	.equ	0x4002451c
GPIOE_GPIOAMSEL	.equ	0x40024528
GPIOE_GPIOPCTL	.equ	0x4002452c
GPIOF_GPIODATA	.equ	0x4002507c
GPIOF_GPIODIR	.equ	0x40025400
GPIOF_GPIOAFSEL	.equ	0x40025420
GPIOF_GPIODEN	.equ	0x4002551c
GPIOF_GPIOLOCK	.equ	0x40025520
GPIOKEY		.equ	0x4c4f434b
GPIOF_GPIOPUR	.equ	0x40025510
GPIOF_GPIOCR	.equ	0x40025524
GPIOF_GPIOAMSEL	.equ	0x40025528
GPIOF_GPIOPCTL	.equ	0x4002552c

;; Initiering av port F
;; Förstör r0, r1, r2
initGPIOF:
	mov r1,#(RCGCGPIO & 0xffff)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x20		; Koppla in GPIO port F
	str r0,[r1]
	nop 			; Vänta lite
	nop
	nop

	mov r1,#(GPIOHBCTL & 0xffff)	; Använd apb för GPIO
	movt r1,#(GPIOHBCTL >> 16)
	ldr r0,[r1]
	mvn r2,#0x2f		; bit 5-0 = 0, övriga = 1
	and r0,r0,r2
	str r0,[r1]

	mov r1,#(GPIOF_GPIOLOCK & 0xffff)
	movt r1,#(GPIOF_GPIOLOCK >> 16)
	mov r0,#(GPIOKEY & 0xffff)
	movt r0,#(GPIOKEY >> 16)
	str r0,[r1]		; Lås upp port F konfigurationsregister

	mov r1,#(GPIOF_GPIOCR & 0xffff)
	movt r1,#(GPIOF_GPIOCR >> 16)
	mov r0,#0x1f		; tillåt konfigurering av alla bitar i porten
	str r0,[r1]

	mov r1,#(GPIOF_GPIOAMSEL & 0xffff)
	movt r1,#(GPIOF_GPIOAMSEL >> 16)
	mov r0,#0x00		; Koppla bort analog funktion
	str r0,[r1]

	mov r1,#(GPIOF_GPIOPCTL & 0xffff)
	movt r1,#(GPIOF_GPIOPCTL >> 16)
	mov r0,#0x00		; använd port F som GPIO
	str r0,[r1]

	mov r1,#(GPIOF_GPIODIR & 0xffff)
	movt r1,#(GPIOF_GPIODIR >> 16)
	mov r0,#0x0e		; styr LED (3 bits), andra bitar är ingångar
	str r0,[r1]

	mov r1,#(GPIOF_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOF_GPIOAFSEL >> 16)
	mov r0,#0		; alla portens bitar är GPIO
	str r0,[r1]

	mov r1,#(GPIOF_GPIOPUR & 0xffff)
	movt r1,#(GPIOF_GPIOPUR >> 16)
	mov r0,#0x11		; svag pull-up för tryckknapparna
	str r0,[r1]

	mov r1,#(GPIOF_GPIODEN & 0xffff)
	movt r1,#(GPIOF_GPIODEN >> 16)
	mov r0,#0xff		; alla pinnar som digital I/O
	str r0,[r1]

	bx lr


;; Initiering av port E
;; Förstör r0, r1
initGPIOE:
	mov r1,#(RCGCGPIO & 0xffff)    ; Clock gating port (slå på I/O-enheter)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x10		; koppla in GPIO port B
	str r0,[r1]
	nop			; vänta lite
	nop
	nop

	mov r1,#(GPIOE_GPIODIR & 0xffff)
	movt r1,#(GPIOE_GPIODIR >> 16)
	mov r0,#0x0		; alla bitar är ingångar
	str r0,[r1]

	mov r1,#(GPIOE_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOE_GPIOAFSEL >> 16)
	mov r0,#0		; alla portens bitar är GPIO
	str r0,[r1]

	mov r1,#(GPIOE_GPIOAMSEL & 0xffff)
	movt r1,#(GPIOE_GPIOAMSEL >> 16)
	mov r0,#0x00		; använd inte analoga funktioner
	str r0,[r1]

	mov r1,#(GPIOE_GPIOPCTL & 0xffff)
	movt r1,#(GPIOE_GPIOPCTL >> 16)
	mov r0,#0x00		; använd inga specialfunktioner på port B	
	str r0,[r1]

	mov r1,#(GPIOE_GPIOPUR & 0xffff)
	movt r1,#(GPIOE_GPIOPUR >> 16)
	mov r0,#0x00		; ingen pullup på port B
	str r0,[r1]

	mov r1,#(GPIOE_GPIODEN & 0xffff)
	movt r1,#(GPIOE_GPIODEN >> 16)
	mov r0,#0xff		; alla pinnar är digital I/O
	str r0,[r1]

	bx lr


;; Utskrift av ett tecken på serieport
;; r0 innehåller tecken att skriva ut (1 byte)
;; returnerar först när tecken skickats
;; förstör r0, r1 och r2 
printchar:
	mov r1,#(UART0_UARTFR & 0xffff)	; peka på serieportens statusregister
	movt r1,#(UART0_UARTFR >> 16)
loop1:
	ldr r2,[r1]			; hämta statusflaggor
	ands r2,r2,#0x20		; kan ytterligare tecken skickas?
	bne loop1			; nej, försök igen
	mov r1,#(UART0_UARTDR & 0xffff)	; ja, peka på serieportens dataregister
	movt r1,#(UART0_UARTDR >> 16)
	str r0,[r1]			; skicka tecken
	bx lr




