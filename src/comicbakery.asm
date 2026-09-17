; ==========================================================================
; COMIC BAKERY - Konami - MSX1 - cartucho RC-714 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x40C7);
;   STATEMENT, DEVICE y TEXT a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,040c7h,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4010..0x4040  (48 bytes)
DATA_4010:
	defb 000h,000h,000h,000h,05ah,05bh,000h,000h,000h,000h,073h,074h,000h,075h,076h,000h	; 4010  ....Z[....st.uv.
	defb 077h,078h,000h,079h,07ah,000h,07bh,07ch,001h,002h,002h,001h,001h,001h,001h,000h	; 4020  wx.yz.{|........
	defb 000h,001h,001h,001h,000h,000h,000h,000h,002h,003h,002h,001h,002h,002h,001h,000h	; 4030  ................

; ======================================================================
; CODIGO 0x4040..0x4119  (217 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESCRIBIR Y LEER LA VRAM. Las dos rutinas que usa todo el cartucho en vez de la BIOS: preparan el puerto una vez y luego mueven los bytes con el registro C ya cargado en el juego alternativo.
; ----------------------------------------------------------------------
escribe_en_vram:
	call prepara_escritura_vram		;4040   ; pone el puntero de escritura y deja 0x98 en C'
	exx			;4043   ; al juego alternativo, donde C es el puerto de datos del VDP
	out (c),a		;4044   ; y ahi va el byte
	exx			;4046
	ei			;4047
	ret			;4048
lee_de_vram:
	call prepara_lectura_vram		;4049   ; lo mismo para leer
	exx			;404c
	in a,(c)		;404d   ; el byte leido vuelve en A
	exx			;404f
	ei			;4050
	ret			;4051

; ----------------------------------------------------------------------
; SUMAR UN INDICE DE OCHO BITS A UN PUNTERO, con el acarreo propagado a mano. Dos gemelas, una para HL y otra para DE.
; ----------------------------------------------------------------------
suma_a_a_hl:
	add a,l			;4052   ; HL += A
	ld l,a			;4053
	ret nc			;4054
	inc h			;4055   ; y el byte alto si hubo acarreo
	ret			;4056
suma_a_a_de:
	add a,e			;4057   ; DE += A, la gemela
	ld e,a			;4058
	ret nc			;4059
	inc d			;405a
	ret			;405b

; ----------------------------------------------------------------------
; EL GANCHO DE LA INTERRUPCION. Y aqui hay una diferencia con sus dos hermanos de tanda: este cartucho GUARDA LOS DOCE REGISTROS -los dos juegos completos, IX e IY incluidos- antes de hacer nada, en vez de fiarse de que el hilo principal este parado en un `jr $`. Cuesta veinticuatro bytes de pila por cuadro.
; ----------------------------------------------------------------------
gancho_de_interrupcion:
	di			;405c
	push af			;405d   ; los seis del juego normal
	push bc			;405e
	push de			;405f
	push hl			;4060
	push ix		;4061
	push iy		;4063
	exx			;4065   ; y los cuatro del alternativo
	ex af,af'			;4066
	push af			;4067
	push bc			;4068
	push de			;4069
	push hl			;406a
	call 0013eh		;406b   ; BIOS RDVDP - Reads VDP status register | lee el estado del VDP para que baje su bandera
	call L_7A18		;406e   ; el sonido, lo primero
	ld hl,0e005h		;4071   ; el cerrojo de reentrada, de un bit
	bit 0,(hl)		;4074
	jr nz,L_4085		;4076   ; si ya hay una dentro, no se entra otra vez
	inc (hl)			;4078
	ei			;4079   ; se abren las interrupciones ESTANDO dentro
	call lee_los_mandos		;407a   ; lee los mandos y el teclado
	call reparte_la_escena		;407d   ; y aqui se despacha la escena
	di			;4080
	xor a			;4081
	ld (0e005h),a		;4082   ; se suelta el cerrojo
L_4085:
	pop hl			;4085   ; y se devuelven los doce registros
	pop de			;4086
	pop bc			;4087
	pop af			;4088
	ex af,af'			;4089
	exx			;408a
	pop iy		;408b
	pop ix		;408d
	pop hl			;408f
	pop de			;4090
	pop bc			;4091
	pop af			;4092
	ei			;4093
	reti		;4094

; ----------------------------------------------------------------------
; EL DESPACHADOR DE ESCENAS: la tabla va PEGADA detras del `call`, y el `pop hl` recupera su propia direccion de retorno, que es justo donde empieza.
; ----------------------------------------------------------------------
despacha_por_tabla:
	pop hl			;4096   ; la direccion de retorno ES la tabla
	add a,a			;4097   ; el numero de escena, por dos
L_4098:
	call suma_a_a_hl		;4098   ; la entrada que toca
	ld e,(hl)			;409b   ; y de ahi el destino
	inc hl			;409c
	ld d,(hl)			;409d
	ex de,hl			;409e
	jp (hl)			;409f   ; se salta sin dejar retorno

; ----------------------------------------------------------------------
; INTERCAMBIAR DOS BLOQUES DE B BYTES sin memoria auxiliar.
; ----------------------------------------------------------------------
intercambia_bloques:
	ld c,(hl)			;40a0   ; el de (HL)
	ld a,(de)			;40a1   ; y el de (DE)
	ld (hl),a			;40a2   ; cada uno al sitio del otro
	ld a,c			;40a3
	ld (de),a			;40a4
	inc hl			;40a5
	inc de			;40a6
	djnz intercambia_bloques		;40a7
	ret			;40a9

; ----------------------------------------------------------------------
; EL INTERPRETE DE ROTULOS, con dos puertas que solo cambian la mascara: con 0x00 se escriben ceros y el MISMO guion borra el rotulo.
; ----------------------------------------------------------------------
borra_rotulo:
	ld c,000h		;40aa   ; mascara 0x00: BORRA
	jr L_40B0		;40ac
pinta_rotulo:
	ld c,0ffh		;40ae   ; mascara 0xFF: pinta
L_40B0:
	ld e,(hl)			;40b0   ; de la cabecera sale el destino en la VRAM
	inc hl			;40b1
	ld d,(hl)			;40b2
	inc hl			;40b3
L_40B4:
	ld a,(hl)			;40b4   ; el siguiente byte del guion
	inc hl			;40b5
	ld b,a			;40b6
	inc b			;40b7   ; 0xFF es el fin del rotulo
	ret z			;40b8
	inc b			;40b9   ; 0xFE es "sigue en otro sitio"
	jr z,L_40B0		;40ba
	and c			;40bc   ; aqui muerde la mascara
	jr nz,L_40C1		;40bd
	ld a,001h		;40bf   ; y al BORRAR se escribe el patron 1, no el cero: en este cartucho la celda vacia es la 1, al reves que en sus dos hermanos
L_40C1:
	call escribe_en_vram		;40c1   ; y a la VRAM
	inc de			;40c4   ; la siguiente celda
	jr L_40B4		;40c5

; ----------------------------------------------------------------------
; INIT, la direccion que trae la cabecera. Modo 1 de interrupcion, gancho en H.KEYI, pila en 0xE400 y un kilobyte de RAM a cero. Desde el `ei` final, el juego entero corre dentro de la interrupcion.
; ----------------------------------------------------------------------
init:
	di			;40c7
	im 1		;40c8
	ld a,0c3h		;40ca   ; un `jp` en 0xFD9A y la direccion detras: asi se engancha H.KEYI
	ld (0fd9ah),a		;40cc
	ld hl,gancho_de_interrupcion		;40cf   ; el gancho es el de 0x405C
	ld (0fd9bh),hl		;40d2
	ld sp,0e400h		;40d5   ; la pila, por encima de las variables
	ld hl,0e000h		;40d8   ; y las variables, a cero de 0xE000 a 0xE3FF
	ld de,0e001h		;40db
	ld bc,003ffh		;40de
	ld (hl),000h		;40e1
	ldir		;40e3
	ld a,001h		;40e5   ; el cerrojo, tomado durante el arranque
	ld (0e005h),a		;40e7
	call arranca_el_hardware		;40ea   ; prepara el VDP y la pantalla
	xor a			;40ed
	ld (0e005h),a		;40ee   ; y ahora si, se suelta
	call 0013eh		;40f1   ; BIOS RDVDP - Reads VDP status register
	ei			;40f4
espera_para_siempre:
	jr espera_para_siempre		;40f5   ; aqui se queda el hilo principal

; ----------------------------------------------------------------------
; EL REPARTO DE ESCENAS. Ademas del contador de cuadros, este cartucho guarda aparte sus tres bits de abajo en (0xE00B), que es el compas que usan las cosas que van a ritmo. Y como sus hermanos, APILA a mano el remate -0x46A3 o 0x4831 segun el bit 6 de (0xE002)-, salvo en la escena 8.
; ----------------------------------------------------------------------
reparte_la_escena:
	ld hl,0e003h		;40f7   ; el contador de cuadros
	inc (hl)			;40fa
	ld a,(hl)			;40fb
	and 007h		;40fc   ; tres bits: el compas de ocho
	ld (0e00bh),a		;40fe   ; guardado aparte
	ld a,(0e002h)		;4101
	and 040h		;4104   ; el bit 6 decide cual de los dos remates se apila
	ld hl,046a3h		;4106
	jr nz,L_410E		;4109
	ld hl,04831h		;410b
L_410E:
	ld a,(0e000h)		;410e
	cp 008h		;4111   ; la escena 8 no lleva remate
	jr z,L_4116		;4113
	push hl			;4115   ; aqui se fabrica el retorno
L_4116:
	call despacha_por_tabla		;4116   ; y la tabla de dieciseis va pegada detras

; ----------------------------------------------------------------------
; DATOS tabla_de_escenas: 16 entradas; la primera apunta a 0x4139, justo
;   detras de la tabla
;   0x4119..0x4139  (32 bytes)
DATA_tabla_de_escenas:
	defw 04139h,04151h,04164h,04173h,04176h,0417eh,04188h,041a6h	; 4119
	defw 04368h,041b2h,041d9h,04240h,0427ch,042d4h,042e8h,04314h	; 4129

; ======================================================================
; CODIGO 0x4139..0x4282  (329 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESCENA 0: el arranque frio, que monta la pantalla del titulo.
; ----------------------------------------------------------------------
L_4139:
	call baja_el_contador_y_barre		;4139
	ret p			;413c
	call L_4733		;413d
	call L_6051		;4140
	ld a,011h		;4143   ; el plazo de la cortinilla
	ld (0e00ah),a		;4145
	ld hl,00000h		;4148
	ld (0e00eh),hl		;414b
	jp pasa_a_la_escena_siguiente		;414e

; ----------------------------------------------------------------------
; ESCENA 1: el letrero de "VIDEO CARTRIDGE" parpadeando, uno de cada dos cuadros.
; ----------------------------------------------------------------------
L_4151:
	ld a,(0e003h)		;4151
	rra			;4154   ; su bit 0 al acarreo
	ret nc			;4155
	call baja_la_cortinilla		;4156
	ret nz			;4159
	ld hl,05e42h		;415a   ; el rotulo
	call pinta_rotulo		;415d
	xor a			;4160
	jp L_4235		;4161

; ----------------------------------------------------------------------
; ESCENA 2: la cuenta atras que lo apaga, borrandolo con el mismo guion.
; ----------------------------------------------------------------------
L_4164:
	ld hl,0e004h		;4164
	dec (hl)			;4167
	ret nz			;4168
	ld hl,05e42h		;4169
	call borra_rotulo		;416c   ; por la puerta que escribe el patron 1
	xor a			;416f
	ld (0e00ah),a		;4170
L_4173:
	jp pasa_a_la_escena_siguiente		;4173

; ----------------------------------------------------------------------
; ESCENA 3: espera a que el jugador se decida.
; ----------------------------------------------------------------------
L_4176:
	call barre_una_franja		;4176
	ret c			;4179
	xor a			;417a
	jp L_4235		;417b

; ----------------------------------------------------------------------
; ESCENA 4: el plazo de la pantalla de seleccion.
; ----------------------------------------------------------------------
L_417E:
	ld hl,0e004h		;417e
	dec (hl)			;4181
	jp nz,parpadea_el_cursor		;4182
	jp plazo_de_32		;4185

; ----------------------------------------------------------------------
; ESCENA 5: empieza partida. Pone el contador de fase a cero, la senal de (0xE053) a uno y monta la pantalla entera.
; ----------------------------------------------------------------------
L_4188:
	call baja_el_contador_y_barre		;4188
	ret p			;418b
	call limpia_el_estado_de_la_fase		;418c
	xor a			;418f
	ld (0e12eh),a		;4190   ; el contador de la fase
	ld (0e051h),a		;4193
	inc a			;4196
	ld (0e053h),a		;4197   ; la senal de partida en marcha
	call pinta_el_marcador		;419a   ; el marcador
	call prepara_la_fase		;419d
	call L_7061		;41a0
	jp plazo_de_32		;41a3

; ----------------------------------------------------------------------
; ESCENA 6: espera a que (0xE053) se apague.
; ----------------------------------------------------------------------
L_41A6:
	call L_4240		;41a6
	ld a,(0e053h)		;41a9
	or a			;41ac
	ret nz			;41ad
L_41AE:
	xor a			;41ae
	jp L_4308		;41af

; ----------------------------------------------------------------------
; ESCENA 7: arranca la vida. Baja el contador de vidas y, con dos jugadores, pinta "PLAYER 1" la primera vez -la segunda ya no, porque (0xE11B) se queda a cero-.
; ----------------------------------------------------------------------
L_41B2:
	call baja_el_contador_y_barre		;41b2
	ret p			;41b5
	ld hl,0e050h		;41b6   ; el contador de vidas
	dec (hl)			;41b9   ; una menos: esta se va a jugar
	call pinta_el_marcador		;41ba   ; repinta el marcador
	ld a,(0e002h)		;41bd   ; el bit 5 dice si hay dos jugadores
	and 020h		;41c0
	jr z,L_41D6		;41c2
	ld hl,0e11bh		;41c4   ; la marca de "ya se enseno"
	ld a,(hl)			;41c7
	or a			;41c8
	ld a,000h		;41c9
	ld (hl),a			;41cb
	jr nz,L_41D6		;41cc
	ld hl,05e37h		;41ce   ; el rotulo "PLAYER 1"
	call pinta_rotulo_con_marca		;41d1
	ld a,02fh		;41d4   ; el plazo, 47 cuadros
L_41D6:
	inc a			;41d6   ; y 48 si no hay rotulo
	jr L_4235		;41d7

; ----------------------------------------------------------------------
; ESCENA 8: el arranque de verdad, la que NO lleva remate apilado. (0xE001) elige entre tres caminos, y el sonido del final depende del bit 0 de (0xE051): el 0x89 o el 0x8B.
; ----------------------------------------------------------------------
escena_8_arranca:
	ld a,(0e001h)		;41d9   ; el sub-estado
	dec a			;41dc
	jr z,L_41FC		;41dd
	dec a			;41df
	jr z,L_4211		;41e0
	ld hl,0e004h		;41e2   ; el plazo del rotulo
	dec (hl)			;41e5
	ret nz			;41e6
	ld hl,05e37h		;41e7   ; el mismo guion de "PLAYER 1"
	call borra_rotulo		;41ea   ; por la puerta que lo borra
	call prepara_la_fase		;41ed
	ld a,(0e11ah)		;41f0   ; la bandera de 0xE11A
	or a			;41f3
	jr z,L_41F9		;41f4
	call pone_en_pie_al_panadero		;41f6
L_41F9:
	jp L_4381		;41f9
L_41FC:
	ld a,(0e11ah)		;41fc
	or a			;41ff
	jr z,L_4206		;4200
	call el_panadero_alcanzado		;4202
	ret nc			;4205
L_4206:
	call L_7061		;4206
	ld a,018h		;4209
	ld (0e105h),a		;420b
	jp L_4381		;420e
L_4211:
	ld a,(0e11ah)		;4211
	or a			;4214
	jr z,L_4221		;4215
	ld a,(0e012h)		;4217   ; espera a que pare el 0x8D
	cp 08dh		;421a
	ret z			;421c
	xor a			;421d
	ld (0e11ah),a		;421e   ; y se apaga la bandera
L_4221:
	ld hl,0e053h		;4221
	ld (hl),001h		;4224   ; la senal de partida en marcha
	ld a,(0e051h)		;4226   ; el contador de fase
	rra			;4229   ; su bit 0
	ld a,089h		;422a   ; un sonido
	jr c,L_4230		;422c
	ld a,08bh		;422e   ; o el otro
L_4230:
	call L_799C		;4230
plazo_de_32:
	ld a,020h		;4233   ; 32 cuadros de plazo
L_4235:
	ld (0e004h),a		;4235
pasa_a_la_escena_siguiente:
	ld hl,0e000h		;4238   ; el numero de escena
	inc (hl)			;423b   ; la siguiente
	inc hl			;423c
	ld (hl),000h		;423d   ; y el sub-estado, a cero
	ret			;423f

; ----------------------------------------------------------------------
; ESCENA 9: el compas de la partida. Si (0xE00D) esta a cero se espera; si no, se pasa a la escena 15 preparando el fin de fase.
; ----------------------------------------------------------------------
L_4240:
	call el_cuadro_de_la_partida		;4240
	ld a,(0e00dh)		;4243   ; la senal de fin
	or a			;4246
	jr nz,L_4250		;4247
	ld a,(0e053h)		;4249
	or a			;424c
	ret nz			;424d
	jr pasa_a_la_escena_siguiente		;424e
L_4250:
	ld hl,0000fh		;4250   ; escena 15
	ld (0e000h),hl		;4253
	xor a			;4256
	ld (0e057h),a		;4257
	ld (0e097h),a		;425a
	ld a,01ch		;425d   ; el plazo largo
	ld (0e11eh),a		;425f
	ld a,(0e101h)		;4262   ; la posicion, guardada
	ld (0e102h),a		;4265
	call L_5897		;4268
	call L_4940		;426b
	ld hl,04e63h		;426e
	call L_4E51		;4271
	ld a,096h		;4274   ; y el sonido del fin de fase
	call L_799C		;4276
	jp escena_15_fin_de_fase		;4279

; ----------------------------------------------------------------------
; EL REPARTO POR SUB-ESTADO: (0xE001) elige, y la tabla de cuatro va pegada detras del `call`, igual que la de escenas.
; ----------------------------------------------------------------------
despacha_el_sub_estado:
	ld a,(0e001h)		;427c   ; el sub-estado
	call despacha_por_tabla		;427f   ; y su tabla de cuatro, pegada detras

; ----------------------------------------------------------------------
; DATOS tabla_4282: 4 entradas; cierra en 0x428A
;   0x4282..0x428a  (8 bytes)
DATA_tabla_4282:
	defw 0428ah,04290h,0429ch,042a9h	; 4282  -> L_428A L_4290 L_429C L_42A9

; ======================================================================
; CODIGO 0x428a..0x432b  (161 bytes)
; ======================================================================


L_428A:
	call L_5952		;428a
	jp L_4381		;428d

; ----------------------------------------------------------------------
; SUB-ESTADO 1: espera a que 0x59C2 diga que si, y deja 40 cuadros de plazo.
; ----------------------------------------------------------------------
L_4290:
	call L_59C2		;4290
	ret nc			;4293
	ld a,028h		;4294   ; cuarenta cuadros
L_4296:
	ld (0e004h),a		;4296
	jp L_4381		;4299

; ----------------------------------------------------------------------
; SUB-ESTADO 2: el plazo, y luego 160 cuadros mas.
; ----------------------------------------------------------------------
L_429C:
	ld hl,0e004h		;429c
	dec (hl)			;429f
	ret nz			;42a0
	ld a,0a0h		;42a1   ; ciento sesenta cuadros
	ld (0e004h),a		;42a3
	jp L_4381		;42a6

; ----------------------------------------------------------------------
; SUB-ESTADO 3: si no quedan vidas, suena el 0x93, se pinta el cartel y se pasa a la escena 13; si quedan, se mira si el otro jugador tiene partida.
; ----------------------------------------------------------------------
L_42A9:
	ld a,(0e050h)		;42a9   ; las vidas
	or a			;42ac
	jp nz,L_42C9		;42ad
	call baja_el_contador_y_barre		;42b0
	ret p			;42b3
	ld a,093h		;42b4   ; el sonido del final
	call L_799C		;42b6
	ld hl,05e2ah		;42b9   ; el cartel
	call pinta_rotulo_con_marca		;42bc
	ld a,00dh		;42bf   ; escena 13
	ld (0e000h),a		;42c1
	ld a,080h		;42c4
	jp L_4235		;42c6
L_42C9:
	ld a,(0e0c0h)		;42c9   ; el estado del otro jugador
	or a			;42cc
	jp nz,pasa_a_la_escena_siguiente		;42cd
L_42D0:
	ld a,009h		;42d0
	jr L_4304		;42d2

; ----------------------------------------------------------------------
; EL CAMBIO DE JUGADOR, otra vez en una sola instruccion, pero aqui el bloque es de CUARENTA Y OCHO bytes -0x30-, no de treinta y dos como en sus dos hermanos: este cartucho lleva mas estado por jugador.
; ----------------------------------------------------------------------
cambia_de_jugador:
	ld hl,0e050h		;42d4   ; el estado del que juega
	ld de,0e0c0h		;42d7   ; y el del que espera
	ld b,030h		;42da   ; cuarenta y ocho bytes cada uno
	call intercambia_bloques		;42dc   ; y se cambian de sitio
	ld hl,0e002h		;42df
	ld a,(hl)			;42e2
	xor 080h		;42e3   ; el bit 7 dice de quien es el turno
	ld (hl),a			;42e5
	jr L_42D0		;42e6
el_relevo:
	ld a,(0e012h)		;42e8   ; espera a que pare el sonido
	or a			;42eb
	ret nz			;42ec
	ld a,(0e0c0h)		;42ed   ; el estado del otro jugador
	or a			;42f0
	jr nz,L_4302		;42f1
	ld hl,0e002h		;42f3
	ld a,(hl)			;42f6
	and 0bfh		;42f7   ; apaga el bit 6 de (0xE002)
	ld (hl),a			;42f9
	ld a,002h		;42fa   ; dos vidas para el que entra
	ld (0e050h),a		;42fc
	jp L_41AE		;42ff
L_4302:
	ld a,00dh		;4302
L_4304:
	ld b,080h		;4304
	jr L_430A		;4306
L_4308:
	ld b,000h		;4308
L_430A:
	ld (0e000h),a		;430a
	ld a,020h		;430d   ; 32 cuadros de plazo
	or b			;430f
	ld (0e004h),a		;4310
	ret			;4313

; ----------------------------------------------------------------------
; ESCENA 15: el fin de fase. Si (0xE01B) vale uno -o sea, si no queda nada sonando salvo una voz- sube dos contadores; luego despacha por el sub-estado con su tabla de ocho pegada detras.
; ----------------------------------------------------------------------
escena_15_fin_de_fase:
	ld hl,0e11dh		;4314   ; el contador de 0xE11D
	ld (hl),000h		;4317
	dec hl			;4319
	ld a,(0e01bh)		;431a   ; lo que queda sonando
	dec a			;431d
	jr nz,L_4324		;431e
	inc (hl)			;4320
	inc hl			;4321
	inc (hl)			;4322
	dec hl			;4323
L_4324:
	inc hl			;4324
	ld a,(0e001h)		;4325   ; el sub-estado
	call despacha_por_tabla		;4328   ; y su tabla de ocho

; ----------------------------------------------------------------------
; DATOS tabla_432B: 8 entradas; cierra en 0x433B
;   0x432b..0x433b  (16 bytes)
DATA_tabla_432B:
	defw 05a76h,05a96h,05ad6h,05ba6h,05c1fh,05c5ah,05c6fh,0433bh	; 432b

; ======================================================================
; CODIGO 0x433b..0x43dd  (162 bytes)
; ======================================================================


remata_la_fase:
	ld hl,0e004h		;433b
	dec (hl)			;433e   ; el plazo
	ret nz			;433f
	ld a,001h		;4340
	ld (0e11bh),a		;4342   ; la marca de "ya se enseno PLAYER 1"
	ld hl,0e050h		;4345
	inc (hl)			;4348   ; una vida mas
L_4349:
	ld hl,0e051h		;4349
	ld a,(hl)			;434c
	add a,001h		;434d   ; la fase siguiente, en BCD
	daa			;434f
	ld (hl),a			;4350
	call limpia_el_estado_de_la_fase		;4351   ; limpia el estado de la fase
	ld (0e00dh),a		;4354
	jp L_42D0		;4357

; ----------------------------------------------------------------------
; LIMPIAR EL ESTADO DE LA FASE: 30 bytes a cero desde 0xE05F, propagando el cero con `ldir` desde la propia celda. Dos instrucciones.
; ----------------------------------------------------------------------
limpia_el_estado_de_la_fase:
	xor a			;435a
	ld hl,0e05fh		;435b
	ld de,0e060h		;435e
	ld bc,0001dh		;4361
	ld (hl),a			;4364   ; un cero
	ldir		;4365   ; y el ldir lo arrastra
	ret			;4367

; ----------------------------------------------------------------------
; PERDER UNA VIDA: suena el 0x8D, se dan 64 cuadros de plazo y, mientras corren, el bit 2 del propio plazo hace parpadear la pantalla -o sea, cada cuatro cuadros-.
; ----------------------------------------------------------------------
pierde_una_vida:
	ld a,(0e001h)		;4368
	or a			;436b
	jr nz,L_4386		;436c
	ld a,08dh		;436e   ; el sonido de perder
	call L_799C		;4370
	ld a,040h		;4373   ; sesenta y cuatro cuadros
	ld (0e004h),a		;4375
L_4378:
	call limpia_la_pantalla		;4378
	call L_60A4		;437b
	call barre_la_pantalla_entera		;437e
L_4381:
	ld hl,0e001h		;4381
	inc (hl)			;4384
	ret			;4385
L_4386:
	ld hl,0e004h		;4386   ; el plazo
	dec (hl)			;4389
	jp z,L_439C		;438a
	bit 2,(hl)		;438d   ; el bit 2: parpadeo de cuatro en cuatro cuadros
	jp nz,barre_la_pantalla_entera		;438f
	call donde_va_el_cursor		;4392
	ld bc,0001bh		;4395   ; 27 celdas que borrar
	xor a			;4398
	jp rellena_vram		;4399
L_439C:
	call borra_el_tanteo		;439c
	ld a,001h		;439f
	ld (0e11ah),a		;43a1
	jp plazo_de_32		;43a4

; ----------------------------------------------------------------------
; PREPARAR EL PUERTO DE LA VRAM con SETWRT de la BIOS, y guardarse el puerto de datos en C' para que los bucles solo tengan que hacer `out (c),a`.
; ----------------------------------------------------------------------
prepara_escritura_vram:
	ex af,af'			;43a7
	ex de,hl			;43a8
	call 00053h		;43a9   ; BIOS SETWRT - Enables VDP to write
	di			;43ac
	ex de,hl			;43ad
	exx			;43ae
	ld a,(00006h)		;43af   ; el puerto de datos, de la tabla de la BIOS
	ld c,a			;43b2   ; a C', donde lo esperan los bucles
	exx			;43b3
	ex af,af'			;43b4
	ret			;43b5
prepara_lectura_vram:
	ex de,hl			;43b6
	call 00050h		;43b7   ; BIOS SETRD - Enables VDP to read
	di			;43ba
	ex de,hl			;43bb
	exx			;43bc
	ld a,(00007h)		;43bd   ; el puerto de lectura
	ld c,a			;43c0
	exx			;43c1
	ret			;43c2
limpia_la_pantalla:
	call L_44E8		;43c3
	ld de,07800h		;43c6   ; la tabla de nombres
	ld bc,00300h		;43c9   ; sus 768 celdas
	xor a			;43cc
rellena_vram:
	call prepara_escritura_vram		;43cd
	ex af,af'			;43d0
L_43D1:
	ex af,af'			;43d1
L_43D2:
	exx			;43d2
	out (c),a		;43d3   ; el byte, tal cual
	exx			;43d5
	ex af,af'			;43d6
	dec bc			;43d7
	ld a,b			;43d8
	or c			;43d9
	jr nz,L_43D1		;43da
	ret			;43dc

; ----------------------------------------------------------------------
; DATOS sin identificar  0x43dd..0x43df  (2 bytes)
DATA_43DD:
	defb 006h,000h	; 43dd

; ======================================================================
; CODIGO 0x43df..0x44ae  (207 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; VOLCAR BC BYTES DE MEMORIA A LA VRAM, tal cual.
; ----------------------------------------------------------------------
vuelca_bloque:
	call prepara_escritura_vram		;43df
L_43E2:
	ld a,(hl)			;43e2   ; un byte
	exx			;43e3
	out (c),a		;43e4   ; y al puerto de datos
	exx			;43e6
	inc hl			;43e7
	dec bc			;43e8
	ld a,b			;43e9
	or c			;43ea
	jr nz,L_43E2		;43eb
	ret			;43ed

; ----------------------------------------------------------------------
; EL DESCOMPRESOR DE ESTE CARTUCHO. La firma de sus rutinas NO coincide con la de Circus Charlie ni con la de Magical Tree -por eso costo encontrarlo-, pero el LENGUAJE es el mismo de los tres: los siete bits de abajo del byte de control son la cuenta, el bit 7 dice si se copia tal cual o se repite un solo byte, un 0x80 cambia de destino de VRAM y un 0x00 cierra el bloque.
; ----------------------------------------------------------------------
descomprime:
	ld e,(hl)			;43ee   ; el destino de VRAM, que va delante del bloque
	inc hl			;43ef
	ld d,(hl)			;43f0
	inc hl			;43f1
L_43F2:
	call prepara_escritura_vram		;43f2   ; aqui entran los que ya lo traen en DE
L_43F5:
	ld a,(hl)			;43f5   ; el byte de control
	and 07fh		;43f6   ; los siete bits de abajo son la cuenta
	ld b,a			;43f8
	ld a,(hl)			;43f9   ; y el byte entero, para mirarle el bit 7
	inc hl			;43fa
	jr z,L_4418		;43fb   ; cuenta cero: fin o cambio de destino
	cp b			;43fd   ; si el byte es igual a su cuenta, el bit 7 esta a cero
	jr z,L_440B		;43fe
L_4400:
	call lee_byte_y_avanza		;4400   ; bit 7 puesto: n bytes tal cual
	exx			;4403
	out (c),a		;4404
	exx			;4406
	djnz L_4400		;4407
	jr L_43F5		;4409
L_440B:
	call lee_byte_y_avanza		;440b   ; bit 7 a cero: UN byte repetido n veces
L_440E:
	exx			;440e
	out (c),a		;440f
	exx			;4411
	push hl			;4412   ; la espera que el VDP necesita entre byte y byte
	pop hl			;4413
	djnz L_440E		;4414
	jr L_43F5		;4416
L_4418:
	cp b			;4418   ; cuenta cero y byte 0x80: detras viene otro destino
	jr nz,descomprime		;4419
	ei			;441b
	ret			;441c
copia_c_franjas:
	call refleja_una_franja		;441d
	ld a,020h		;4420   ; la fila de abajo, 32 celdas
	call suma_a_a_de		;4422
	dec c			;4425
	jr nz,copia_c_franjas		;4426
	ret			;4428
copia_c_franjas_alternas:
	call refleja_una_franja		;4429
	ld a,0e0h		;442c   ; 0xE0 hacia atras
	add a,e			;442e
	ld e,a			;442f
	jr c,L_4433		;4430
	dec d			;4432
L_4433:
	call refleja_una_franja		;4433
	ld a,060h		;4436   ; y noventa y seis adelante
	call suma_a_a_de		;4438
	dec c			;443b
	jr nz,copia_c_franjas_alternas		;443c
	ret			;443e

; ----------------------------------------------------------------------
; REFLEJAR UNA FRANJA DE LA PANTALLA sobre si misma: lee cada byte de la VRAM, LE DA LA VUELTA A SUS OCHO BITS y lo escribe. Asi el dibujo de un lado sirve para el otro sin guardarlo dos veces.
; ----------------------------------------------------------------------
refleja_una_franja:
	push de			;443f
L_4440:
	ld b,010h		;4440   ; dieciseis bytes
L_4442:
	ex de,hl			;4442
	call lee_de_vram		;4443   ; lee de la VRAM
	ex de,hl			;4446
	call da_la_vuelta_a_los_bits		;4447   ; con los bits al reves
	call escribe_en_vram		;444a   ; y de vuelta a la VRAM
	inc e			;444d
	inc hl			;444e
	djnz L_4442		;444f
	ld a,e			;4451
	sub 020h		;4452   ; treinta y dos atras
	ld e,a			;4454
	bit 4,e		;4455   ; el bit 4 marca el final de la vuelta
	jr z,L_4440		;4457
	pop de			;4459
	ret			;445a
lee_byte_y_avanza:
	ld a,(hl)			;445b   ; el byte del bloque
	inc hl			;445c
	ret			;445d

; ----------------------------------------------------------------------
; DAR LA VUELTA A LOS OCHO BITS de un byte: `rr c` saca el de abajo y `rla` lo mete por arriba, ocho veces. Es el espejo de un patron de 8 pixeles.
; ----------------------------------------------------------------------
da_la_vuelta_a_los_bits:
	push bc			;445e
	ld c,a			;445f
	ld b,008h		;4460   ; ocho bits
L_4462:
	rr c		;4462   ; sale por abajo
	rla			;4464   ; y entra por arriba
	djnz L_4462		;4465
	pop bc			;4467
	ret			;4468

; ----------------------------------------------------------------------
; VOLCAR A LA VRAM Y GUARDAR COPIA EN RAM a la vez, con el mismo byte: la copia va 0xA8 paginas mas alla. Asi el cartucho puede consultar despues lo que hay escrito sin volver a leer del VDP.
; ----------------------------------------------------------------------
vuelca_y_guarda_copia:
	call prepara_escritura_vram		;4469
	ld a,0a8h		;446c   ; la copia va a la pagina +0xA8
	add a,d			;446e
	ld d,a			;446f
L_4470:
	ld a,(hl)			;4470
	exx			;4471
	out (c),a		;4472   ; al VDP
	exx			;4474
	ld (de),a			;4475   ; y a la copia en RAM
	inc de			;4476
	inc hl			;4477
	djnz L_4470		;4478
	ret			;447a

; ----------------------------------------------------------------------
; BORRAR EL TANTEO del jugador que toque -0xE049 o 0xE046-, propagando un cero con `ldir` por 694 bytes, y volver a poner los ocho valores iniciales. Con dos jugadores, el bloque se duplica en el hueco del segundo.
; ----------------------------------------------------------------------
borra_el_tanteo:
	ld hl,0e049h		;447b   ; el tanteo de un jugador
	ld bc,002b6h		;447e   ; 694 bytes por delante
	ld a,(0e002h)		;4481
	and 020h		;4484   ; el bit 5: hay dos jugadores
	push af			;4486
	jr z,L_448E		;4487
	ld l,046h		;4489   ; entonces el otro tanteo
	inc bc			;448b
	inc bc			;448c
	inc bc			;448d
L_448E:
	ld d,h			;448e
	ld e,l			;448f
	inc e			;4490
	ld (hl),000h		;4491   ; un cero
	ldir		;4493   ; y el ldir lo arrastra
	ld hl,044aeh		;4495   ; los ocho valores iniciales
	ld de,0e050h		;4498
	ld bc,00008h		;449b
	ldir		;449e
	pop af			;44a0
	ret z			;44a1   ; con un jugador, aqui se acaba
	ld hl,0e050h		;44a2
	ld de,0e0c0h		;44a5   ; y con dos, el estado se duplica
	ld bc,00020h		;44a8
	ldir		;44ab
	ret			;44ad

; ----------------------------------------------------------------------
; DATOS sin identificar  0x44ae..0x44b6  (8 bytes)
DATA_44AE:
	defb 003h,001h,000h,002h,000h,000h,001h,000h	; 44ae  ........

; ======================================================================
; CODIGO 0x44b6..0x4688  (466 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL BARRIDO DE LA PANTALLA con VAIVEN, que es un detalle bonito: `srl a / jr c / xor 01fh` hace que el indice de la fila vaya al derecho en media vuelta y al reves en la otra, de modo que la cortina barre en zigzag. Y el bit 7 del contador cambia el tramo: dos filas menos y 0x40 de desplazamiento.
; ----------------------------------------------------------------------
baja_el_contador_y_barre:
	ld hl,0e11fh		;44b6
	ld a,(hl)			;44b9   ; la bandera de 0xE11F
	or a			;44ba
	jp nz,prepara_la_pantalla_de_fin		;44bb
	ld hl,0e003h		;44be
	dec (hl)			;44c1   ; el contador de cuadros
	inc hl			;44c2
	ld a,(hl)			;44c3
	and 07fh		;44c4   ; siete bits del segundo contador
	dec (hl)			;44c6
	dec a			;44c7
	ret m			;44c8   ; si se paso de cero, se sale con el signo
	ld b,018h		;44c9   ; veinticuatro filas
	ld d,038h		;44cb
	srl a		;44cd   ; el bit de abajo al acarreo
	jr c,L_44D3		;44cf
	xor 01fh		;44d1   ; y en media vuelta, al reves
L_44D3:
	bit 7,(hl)		;44d3   ; el bit 7 cambia de tramo
	jr z,L_44DB		;44d5
	dec b			;44d7   ; dos filas menos
	dec b			;44d8
	add a,040h		;44d9
L_44DB:
	ld e,a			;44db
L_44DC:
	ld a,001h		;44dc   ; el patron 1, que aqui es la celda vacia
	call escribe_en_vram		;44de
	ld a,020h		;44e1   ; la fila de abajo, 32 celdas
	call suma_a_a_de		;44e3
	djnz L_44DC		;44e6
L_44E8:
	ld b,010h		;44e8   ; dieciseis sprites
	ld hl,0e080h		;44ea
L_44ED:
	ld (hl),0e0h		;44ed   ; la fila 0xE0: fuera de la pantalla
	ld a,004h		;44ef
	call suma_a_a_hl		;44f1   ; cuatro bytes por sprite
	djnz L_44ED		;44f4
	call L_707A		;44f6
	xor a			;44f9
	ret			;44fa
prepara_la_pantalla_de_fin:
	ld (hl),000h		;44fb
	ld a,0d0h		;44fd   ; 0xD0 en los atributos de sprites
	ld de,03b00h		;44ff
	call escribe_en_vram		;4502
	ld a,0e0h		;4505
	call codigo_huerfano_4757		;4507
	ld de,03840h		;450a
	ld bc,002c0h		;450d   ; 704 celdas
	ld a,001h		;4510   ; con el patron 1
	call rellena_vram		;4512
	call L_44E8		;4515
	dec a			;4518
	ret			;4519
parpadea_el_cursor:
	ld bc,03e3fh		;451a   ; el par de patrones del cursor
	bit 3,(hl)		;451d   ; el bit 3 del plazo: parpadea de ocho en ocho cuadros
	jr nz,L_4524		;451f
L_4521:
	ld bc,00000h		;4521   ; y en la otra mitad, celdas vacias
L_4524:
	call donde_va_el_cursor		;4524
	ld a,b			;4527
	call escribe_en_vram		;4528
	ld a,c			;452b
	inc de			;452c
	call escribe_en_vram		;452d
	ret			;4530

; ----------------------------------------------------------------------
; DONDE CAE EL CURSOR DEL MENU: la opcion de (0xE042), mas 0x14 y dos giros a la derecha, da el byte bajo de la celda, con la fila 0x7A fija en D.
; ----------------------------------------------------------------------
donde_va_el_cursor:
	ld a,(0e042h)		;4531   ; la opcion elegida
	add a,014h		;4534   ; el desplazamiento a la primera fila
	rrca			;4536   ; dos giros: cuatro filas por opcion
	rrca			;4537
	ld e,a			;4538
	ld d,07ah		;4539   ; la pagina, fija
	ret			;453b
pinta_rotulo_con_marca:
	call pinta_rotulo		;453c
	ld a,(0e002h)		;453f
	or a			;4542
	ret p			;4543
	ld a,012h		;4544   ; la marca del segundo jugador
	dec de			;4546
	call escribe_en_vram		;4547
	ret			;454a

; ----------------------------------------------------------------------
; SUMAR PUNTOS, en BCD y a seis digitos. El tanteo es el de 0xE049 o el de 0xE046 segun el turno, y con el bit 6 puesto no se suma nada.
; ----------------------------------------------------------------------
suma_puntos:
	ld a,(0e002h)		;454b   ; el turno y las banderas
	add a,a			;454e   ; el bit 7 al acarreo, el 6 al signo
	ret p			;454f   ; con el bit 6 puesto no se suman puntos
	ld hl,0e049h		;4550
	jr nc,L_4557		;4553
	ld l,046h		;4555
L_4557:
	ld a,(hl)			;4557
	add a,e			;4558   ; los dos digitos de abajo
	daa			;4559   ; en BCD
	ld (hl),a			;455a
	ld e,a			;455b
	inc l			;455c
	ld a,(hl)			;455d
	adc a,d			;455e   ; los del medio, con acarreo
	daa			;455f
	ld (hl),a			;4560
	ld d,a			;4561
	inc hl			;4562
	jr nc,mira_si_es_record		;4563
	ld a,(hl)			;4565
	add a,001h		;4566   ; y el tercer par
	daa			;4568
	ld (hl),a			;4569
	jr nc,mira_la_vida_extra		;456a
	ld bc,09999h		;456c   ; si desborda los seis digitos, el record se clava en 999999
	ld (0e043h),bc		;456f
	ld (0e044h),bc		;4573
	jr L_45D4		;4577

; ----------------------------------------------------------------------
; LA VIDA EXTRA, y aqui hay un numero distinto: el umbral sube de TRES en tres, no de dos como en Circus Charlie y Magical Tree. Lo demas es igual, incluido el clavarse en 0xFF cuando desbordaria.
; ----------------------------------------------------------------------
mira_la_vida_extra:
	ld a,(0e052h)		;4579   ; el umbral
	cp (hl)			;457c   ; contra los digitos altos del tanteo
	jr nc,mira_si_es_record		;457d
	push de			;457f
	push hl			;4580
	add a,003h		;4581   ; el siguiente umbral, TRES mas
	daa			;4583
	jr nc,L_4588		;4584
	ld a,0ffh		;4586   ; si se paso, 0xFF: no habra mas
L_4588:
	ld (0e052h),a		;4588
	ld hl,0e050h		;458b
	inc (hl)			;458e   ; una vida mas
	call pinta_las_vidas		;458f   ; repinta el contador
	ld a,008h		;4592   ; y suena el aviso
	call L_799C		;4594
	pop hl			;4597
	pop de			;4598
mira_si_es_record:
	ld a,(0e045h)		;4599   ; el par alto del record
	ld b,(hl)			;459c
	sub b			;459d   ; contra el del tanteo
	jr c,L_45A9		;459e
	jr nz,pinta_el_tanteo		;45a0
	ld hl,(0e043h)		;45a2   ; empatan arriba: se miran los de abajo
	sbc hl,de		;45a5
	jr nc,pinta_el_tanteo		;45a7
L_45A9:
	ld (0e043h),de		;45a9
	ld a,b			;45ad
	ld (0e045h),a		;45ae
	jr L_45D4		;45b1
pinta_el_marcador:
	ld hl,05d8eh		;45b3   ; los rotulos del marcador
	call pinta_rotulo		;45b6
	ld a,(0e002h)		;45b9
	bit 5,a		;45bc   ; el bit 5: hay dos jugadores?
	jr z,L_45CE		;45be
	ld hl,05dabh		;45c0   ; entonces tambien el "2P"
	call pinta_rotulo		;45c3
	ld a,(0e002h)		;45c6
	xor 080h		;45c9   ; se finge el otro turno
	call L_45E0		;45cb
L_45CE:
	call pinta_las_vidas		;45ce   ; el contador de vidas
	call pinta_la_fase		;45d1
L_45D4:
	ld hl,0e045h		;45d4   ; el record
	ld de,0380fh		;45d7   ; en la fila de arriba, columna 15
	call L_45EE		;45da
pinta_el_tanteo:
	ld a,(0e002h)		;45dd
L_45E0:
	ld de,03805h		;45e0   ; la celda del primer tanteo
	ld hl,0e04bh		;45e3
	add a,a			;45e6   ; el bit 7 al acarreo
	jr nc,L_45EE		;45e7
	ld e,025h		;45e9   ; la columna del segundo
	ld hl,0e048h		;45eb
L_45EE:
	ld b,003h		;45ee
	jr imprime_bcd		;45f0
pinta_la_fase:
	ld de,0381ch		;45f2   ; la celda de la fase
	ld hl,0e051h		;45f5
	ld b,001h		;45f8

; ----------------------------------------------------------------------
; EL IMPRESOR DE BCD: parte cada byte en sus dos digitos y les suma 0x10, que es donde empieza el "0" en la fuente. El alto va primero y el puntero de la variable retrocede mientras el de la VRAM avanza, porque el BCD esta guardado del reves.
; ----------------------------------------------------------------------
imprime_bcd:
	ld c,010h		;45fa   ; +0x10: el "0" de la fuente
L_45FC:
	ld a,(hl)			;45fc
	and 0f0h		;45fd   ; el digito de arriba
	rra			;45ff   ; cuatro veces a la derecha
	rra			;4600
	rra			;4601
	rra			;4602
	or c			;4603
	call escribe_en_vram		;4604
	inc de			;4607
	ld a,(hl)			;4608   ; y el de abajo
	and 00fh		;4609
	or c			;460b
	call escribe_en_vram		;460c
	inc de			;460f
	dec hl			;4610   ; la variable va hacia atras
	djnz L_45FC		;4611
	ret			;4613

; ----------------------------------------------------------------------
; EL RELOJ DE LA JORNADA, que es el corazon de este juego y no lo tiene ninguno de sus dos hermanos. Cuenta segundos en BCD hasta 60, y cada sesenta sube un minuto; al llegar al minuto OCHO levanta la senal de fin (0xE00D). O sea que una fase dura ocho minutos de reloj.
; ----------------------------------------------------------------------
el_reloj_de_la_jornada:
	ld a,(0e000h)		;4614   ; la escena en curso
	cp 00bh		;4617   ; solo la escena 11 mueve el reloj
	ret nz			;4619
	ld hl,0e199h		;461a   ; el plazo entre tic y tic
	dec (hl)			;461d   ; uno menos
	ret nz			;461e
	ld de,0e07ah		;461f
	ld c,020h		;4622   ; el plazo normal
	ld a,(de)			;4624
	ld b,a			;4625
	dec de			;4626
	or a			;4627
	jr nz,L_4631		;4628
	ld a,(de)			;462a
	cp 011h		;462b   ; por debajo de 0x11
	jr c,L_463C		;462d
	jr L_463A		;462f
L_4631:
	cp 007h		;4631   ; el estado 7
	jr nz,L_463A		;4633
	ld a,(de)			;4635
	cp 045h		;4636   ; y por debajo de 0x45
	jr nc,L_463C		;4638
L_463A:
	ld c,00ah		;463a   ; el plazo corto: el reloj corre el triple
L_463C:
	ld (hl),c			;463c
	ex de,hl			;463d
	ld a,(hl)			;463e
	add a,001h		;463f   ; un segundo mas, en BCD
	daa			;4641
	ld (hl),a			;4642
	cp 060h		;4643   ; a los sesenta
	jr c,pinta_el_reloj		;4645
	ld (hl),000h		;4647   ; se reinicia
	inc hl			;4649
	inc (hl)			;464a   ; y sube un minuto
	ld a,(hl)			;464b
	cp 008h		;464c   ; al minuto ocho
	jr nz,pinta_el_reloj		;464e
	ld a,001h		;4650
	ld (0e00dh),a		;4652   ; se acaba la jornada
pinta_el_reloj:
	ld hl,0e079h		;4655
	ld de,0e198h		;4658
	ld a,(hl)			;465b
	and 00fh		;465c   ; el nibble bajo
	add a,080h		;465e   ; +0x80: los digitos del reloj
	ld (de),a			;4660
	dec de			;4661
	ld a,(hl)			;4662
	rra			;4663   ; y el nibble alto
	rra			;4664
	rra			;4665
	rra			;4666
	and 00fh		;4667
	add a,090h		;4669   ; +0x90: los de la otra mitad
	ld (de),a			;466b
	dec de			;466c
	inc hl			;466d
	ld a,(hl)			;466e
	add a,a			;466f
	add a,(hl)			;4670
	ld hl,0468ah		;4671   ; la tabla de indices del reloj
	call suma_a_a_hl		;4674
	ld bc,00003h		;4677   ; tres bytes
	lddr		;467a   ; copiados hacia atras
	ex de,hl			;467c
	inc hl			;467d
	ld de,038edh		;467e   ; la celda del reloj en la pantalla
	ld bc,00005h		;4681   ; cinco celdas
	call vuelca_bloque		;4684
	ret			;4687

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4688..0x46a3  (27 bytes)
DATA_4688:
	defb 08ch,08bh,089h,08ch,08ah,080h,08ch,08ah,081h,08eh,08fh,082h,08eh,08dh,081h,08eh	; 4688  ................
	defb 08dh,082h,08eh,08dh,083h,08eh,08dh,084h,08eh,08dh,085h	; 4698  ...........

; ======================================================================
; CODIGO 0x46a3..0x474f  (172 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL PARPADEO DEL "1P" / "2P", cada 32 cuadros. Con dos jugadores se descuenta uno para que no parpadeen a la vez. Es ademas el REMATE que 0x40F7 apila cuando el bit 6 de (0xE002) esta a uno.
; ----------------------------------------------------------------------
parpadea_el_turno:
	ld hl,(0e002h)		;46a3   ; de un tiron: (0xE002) y el contador de cuadros
	ld a,01fh		;46a6   ; los cinco bits de abajo
	and h			;46a8
	ret nz			;46a9   ; uno de cada 32 cuadros
	ld c,a			;46aa
	bit 5,h		;46ab
	jr z,L_46B0		;46ad
	dec c			;46af   ; con dos jugadores, se desfasa
L_46B0:
	bit 7,l		;46b0   ; el bit 7 dice de quien es el turno
	ld hl,05da5h		;46b2
	jr z,L_46BA		;46b5
	ld hl,05dabh		;46b7
L_46BA:
	jp L_40B0		;46ba

; ----------------------------------------------------------------------
; EL CONTADOR DE VIDAS, cinco marcas de izquierda a derecha: mientras queden se escribe el patron 0x3B y, en cuanto se acaban, el 1, que es la celda vacia de este cartucho.
; ----------------------------------------------------------------------
pinta_las_vidas:
	ld de,03836h		;46bd   ; la primera celda
	ld a,(0e050h)		;46c0   ; las vidas que quedan
	ld c,a			;46c3
	ld a,03bh		;46c4   ; la marca
L_46C6:
	ld b,005h		;46c6   ; cinco como maximo
L_46C8:
	dec c			;46c8   ; una menos
	jp p,L_46CE		;46c9
	ld a,001h		;46cc   ; agotadas: celda vacia
L_46CE:
	call escribe_en_vram		;46ce
	inc de			;46d1
	djnz L_46C8		;46d2
	ret			;46d4
pinta_los_panes:
	ld de,03831h		;46d5   ; su celda
	ld hl,0e120h		;46d8
	ld c,(hl)			;46db
	inc hl			;46dc
	inc hl			;46dd
	ld a,(hl)			;46de
	add a,0bbh		;46df   ; el patron, corrido 0xBB
	jr L_46C6		;46e1
barre_la_pantalla_entera:
	xor a			;46e3
	ld (0e00ah),a		;46e4   ; se empieza por la fila 0
L_46E7:
	call barre_una_franja		;46e7
	jr c,L_46E7		;46ea
	ret			;46ec

; ----------------------------------------------------------------------
; EL BARRIDO, tres filas por llamada. (0xE00A) dice por donde va; devuelve acarreo mientras quede trabajo, y al pasar de 19 saca la pantalla de seleccion.
; ----------------------------------------------------------------------
barre_una_franja:
	ld hl,0e00ah		;46ed   ; por donde iba
	ld a,(hl)			;46f0
	inc (hl)			;46f1   ; y se deja avanzada
	cp 013h		;46f2   ; diecinueve pasadas
	jr nc,L_4712		;46f4
	ld de,03888h		;46f6   ; la esquina de arriba
	ld c,a			;46f9
	add a,e			;46fa
	ld e,a			;46fb
	ld a,c			;46fc
	add a,a			;46fd   ; el paso por dos
	add a,0dah		;46fe   ; +0xDA: de ahi sale el patron de la cortina
	ld c,a			;4700
	ld b,003h		;4701   ; tres filas de golpe
	xor a			;4703
L_4704:
	call escribe_en_vram		;4704
	ld a,020h		;4707   ; la de abajo
	call suma_a_a_de		;4709
	ld a,c			;470c
	inc c			;470d
	djnz L_4704		;470e
	scf			;4710   ; acarreo: todavia queda
	ret			;4711
L_4712:
	push af			;4712
	ld hl,05db1h		;4713   ; "PLAY SELECT" con sus cuatro opciones
	call z,pinta_rotulo		;4716
	pop af			;4719
	cp 034h		;471a
	ret			;471c
arranca_el_hardware:
	ld a,007h		;471d
	ld e,0b8h		;471f
	call 00093h		;4721   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,09ah		;4724   ; el sonido de arranque
	call L_79AC		;4726
	ld de,04000h		;4729   ; la VRAM entera
	ld bc,04000h		;472c   ; los dieciseis kilobytes
	xor a			;472f
	call rellena_vram		;4730
L_4733:
	ld hl,0474fh		;4733   ; los ocho registros del VDP
	ld de,0e038h		;4736
	ld bc,00008h		;4739   ; ocho bytes
	ldir		;473c
L_473E:
	ld hl,0e038h		;473e   ; la copia en RAM de los registros
	ld d,008h		;4741   ; ocho escrituras
	ld c,000h		;4743
L_4745:
	ld b,(hl)			;4745   ; el valor
	call 00047h		;4746   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP: C lleva el numero de registro
	inc hl			;4749
	inc c			;474a
	dec d			;474b
	jr nz,L_4745		;474c
	ret			;474e

; ----------------------------------------------------------------------
; DATOS sin identificar  0x474f..0x4757  (8 bytes)
DATA_474F:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 474f  .....v..

; ======================================================================
; CODIGO 0x4757..0x488e  (311 bytes)
; ======================================================================


codigo_huerfano_4757:
	ld (0e03fh),a		;4757   ; pegado detras de los registros del VDP
	jr $-28		;475a

; ----------------------------------------------------------------------
; LEER EL MANDO. El bit 6 del registro 15 del PSG elige el puerto y lo decide el bit 7 de (0xE002): cada jugador el suyo. Los bits se invierten con `cpl` porque pulsado se lee como cero.
; ----------------------------------------------------------------------
lee_el_mando:
	ld e,08fh		;475c   ; la seleccion de puerto
	ld hl,0e002h		;475e
	bit 7,(hl)		;4761   ; el turno
	jr z,L_4767		;4763
	set 6,e		;4765   ; el segundo jugador usa el otro puerto
L_4767:
	ld a,00fh		;4767   ; registro 15 del PSG
	call 00093h		;4769   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;476c   ; y el 14, que es donde se lee
	call 00096h		;476e   ; BIOS RDPSG - Reads value from PSG-register
	cpl			;4771   ; pulsado es cero, se invierte
	and 03fh		;4772
	ret			;4774

; ----------------------------------------------------------------------
; LA LECTURA DE CADA CUADRO, y aqui esta lo bueno: si el bit 6 de (0xE002) esta a CERO -o sea, mientras estamos en el menu- la entrada no viene del mando sino de un GUION grabado en 0x6001. El cartucho se juega solo en la pantalla de atraccion, leyendo movimientos de una lista en vez de del jugador.
; ----------------------------------------------------------------------
lee_los_mandos:
	call lee_el_mando		;4775   ; el mando
	bit 4,(hl)		;4778   ; el bit 4: se juega con teclado
	call nz,lee_el_teclado		;477a
	ld hl,0e002h		;477d
	bit 6,(hl)		;4780   ; el bit 6: si esta a cero, manda la demostracion
	call z,lee_el_guion_de_la_demostracion		;4782
	ld hl,0e009h		;4785   ; la lectura de este cuadro
	ld c,(hl)			;4788   ; y la de antes se guarda al lado
	ld (hl),a			;4789
	dec hl			;478a
	ld (hl),c			;478b
	call filtra_la_direccion		;478c
	xor a			;478f
	dec e			;4790
	jp p,L_47A5		;4791
	ld a,(hl)			;4794
	rrca			;4795   ; dos bits de la lectura
	rrca			;4796
	and 003h		;4797
	jr nz,L_47A5		;4799
	ld a,(0e105h)		;479b   ; el estado de 0xE105
	or a			;479e
	ld a,001h		;479f
	jr z,L_47A5		;47a1
	ld a,002h		;47a3
L_47A5:
	ld (0e122h),a		;47a5
	ret			;47a8

; ----------------------------------------------------------------------
; EL GUION DE LA DEMOSTRACION: (0xE12E) avanza un paso cada vez que el compas de ocho da la vuelta, y ese paso indexa la lista de 0x6001, de donde sale lo que "pulsa" el jugador de mentira. Al llegar al paso 0x4F se apaga la senal de partida.
; ----------------------------------------------------------------------
lee_el_guion_de_la_demostracion:
	ld hl,0e12eh		;47a9   ; el paso de la demostracion
	ld a,(0e00bh)		;47ac   ; el compas de ocho
	or a			;47af
	jr nz,L_47B3		;47b0
	inc (hl)			;47b2   ; y solo entonces avanza
L_47B3:
	ld a,(hl)			;47b3
	cp 04fh		;47b4   ; el paso 79
	jr nz,L_47BD		;47b6
	ld hl,0e053h		;47b8
	ld (hl),000h		;47bb   ; apaga la senal de partida
L_47BD:
	ld hl,06001h		;47bd   ; la lista de movimientos grabados
	call suma_a_a_hl		;47c0
	ld a,(hl)			;47c3   ; y de ahi sale lo que se "pulsa"
	ret			;47c4

; ----------------------------------------------------------------------
; FILTRAR LA DIRECCION: las dos a la vez (0x0C) no valen, y si se estaba yendo a un lado y se pide el contrario, el `xor 08Ch` le da la vuelta al sentido de golpe.
; ----------------------------------------------------------------------
filtra_la_direccion:
	ld hl,0e101h		;47c5
	ld c,a			;47c8
	ld a,(0e104h)		;47c9   ; el estado de 0xE104
	ld e,a			;47cc
	or a			;47cd
	ret nz			;47ce
	ld a,c			;47cf
	and 00ch		;47d0   ; los dos bits de direccion
	jr z,L_47D8		;47d2
	cp 00ch		;47d4   ; las dos a la vez
	jr z,L_47DA		;47d6
L_47D8:
	ld (hl),a			;47d8
	ret			;47d9
L_47DA:
	ld a,(hl)			;47da
	bit 7,a		;47db   ; el bit 7: ya esta girando
	ret nz			;47dd
	ld b,088h		;47de
	or a			;47e0
	jr z,L_47E6		;47e1
	xor 08ch		;47e3   ; y el xor le da la vuelta al sentido
	ld b,a			;47e5
L_47E6:
	ld (hl),b			;47e6
	ret			;47e7
lee_el_teclado:
	ld a,007h		;47e8   ; una fila del teclado
	call 00141h		;47ea   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;47ed   ; pulsado es cero, se invierte
	rrca			;47ee
	and 020h		;47ef
	ld e,a			;47f1
	ld a,008h		;47f2   ; y otra fila
	call 00141h		;47f4   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;47f7
	rrca			;47f8
	rrca			;47f9
	ld b,a			;47fa
	and 004h		;47fb   ; las dos teclas de esta fila
	or e			;47fd
	ld c,a			;47fe
	ld a,b			;47ff
	rrca			;4800
	rrca			;4801
	ld b,a			;4802
	and 018h		;4803   ; y las dos que quedan
	or c			;4805
	ld c,a			;4806
	ld a,b			;4807
	rrca			;4808
	and 003h		;4809
	or c			;480b
	ret			;480c

; ----------------------------------------------------------------------
; EL FLANCO DE UN BOTON, con la mascara en C -0x10 para uno solo, 0x21 para los dos-. Invierte la lectura anterior y la cruza con la de ahora: solo queda a uno lo que estaba suelto y ahora esta pulsado. Y si estamos en el menu -bit 6 a cero- solo responde la escena 11.
; ----------------------------------------------------------------------
flanco_del_boton_10:
	ld c,010h		;480d
	jr L_4813		;480f
flanco_de_los_dos_botones:
	ld c,021h		;4811
L_4813:
	ld a,(0e002h)		;4813
	bit 6,a		;4816   ; el bit 6: en el menu no se atiende
	jr z,L_4821		;4818
	ld a,(0e000h)		;481a
	cp 00bh		;481d   ; solo la escena 11
	jr nz,L_482F		;481f
L_4821:
	ld a,(0e009h)		;4821   ; la lectura de ahora
	ld b,a			;4824
	ld a,(0e008h)		;4825   ; y la de antes
	and c			;4828
	cpl			;4829   ; invertida
	ld e,a			;482a
	ld a,b			;482b
	and c			;482c
	and e			;482d   ; cruzadas: el flanco
	ret			;482e
L_482F:
	xor a			;482f
	ret			;4830

; ----------------------------------------------------------------------
; EL MENU DE SELECCION, que es el remate que 0x40F7 apila cuando el bit 6 de (0xE002) esta a cero. Junta las TRES entradas -los dos puertos y el teclado- con un `or`, de modo que vale cualquiera, y se queda con el FLANCO.
; ----------------------------------------------------------------------
atiende_el_menu:
	ld e,08fh		;4831   ; el primer puerto de mando
	call L_4767		;4833
	ld d,a			;4836
	ld e,0cfh		;4837   ; y el segundo
	call L_4767		;4839
	or d			;483c   ; se juntan
	ld d,a			;483d
	call lee_el_teclado		;483e   ; mas el teclado
	or d			;4841
	ld hl,0e040h		;4842   ; lo de ahora en (0xE040)
	ld c,(hl)			;4845
	ld (hl),a			;4846
	inc hl			;4847
	ld (hl),c			;4848   ; y lo de antes justo detras
	ld b,a			;4849
	xor c			;484a   ; los bits que han cambiado
	and b			;484b   ; y de esos, los que ahora estan pulsados
	ret z			;484c   ; nada nuevo, nada que hacer
	ld b,a			;484d
	ld a,000h		;484e
	ld (0e004h),a		;4850   ; se reinicia el plazo de la pantalla
	ld a,005h		;4853   ; solo la escena 5 responde al menu
	ld hl,0e000h		;4855
	cp (hl)			;4858
	jr nz,L_4874		;4859
	ld a,b			;485b
	cp 010h		;485c   ; de 0x10 para arriba son botones
	jr c,mueve_el_cursor		;485e
	ld hl,0488eh		;4860   ; los cuatro modos de juego
	ld a,(0e042h)		;4863   ; indexados por la opcion elegida
	call suma_a_a_hl		;4866
	ld a,(hl)			;4869
	ld (0e002h),a		;486a   ; y el modo queda en (0xE002)
	ld hl,00008h		;486d   ; a la escena 8, la que arranca sin remate apilado
	ld (0e000h),hl		;4870
	ret			;4873
L_4874:
	ld (hl),a			;4874
	jp L_4378		;4875
mueve_el_cursor:
	push bc			;4878
	call L_4521		;4879   ; borra el cursor de donde estaba
	pop af			;487c
	ld hl,0e042h		;487d   ; la opcion elegida
	ld b,(hl)			;4880
	rra			;4881   ; el bit 0: arriba
	jr nc,L_4885		;4882
	dec b			;4884   ; una menos
L_4885:
	rra			;4885   ; el bit 1: abajo
	jr nc,L_4889		;4886
	inc b			;4888   ; una mas
L_4889:
	ld a,b			;4889
	and 003h		;488a
	ld (hl),a			;488c
	ret			;488d

; ----------------------------------------------------------------------
; DATOS sin identificar  0x488e..0x4892  (4 bytes)
DATA_488E:
	defb 040h,060h,050h,070h	; 488e

; ======================================================================
; CODIGO 0x4892..0x4a1f  (397 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; UN PASO DE CORTINILLA. Avanza 32 celdas -una fila- y pinta la franja en DOS sitios a la vez: en la posicion que toca y en su reflejo respecto de 0x3AAA, con `sbc hl,de`. Se cierra desde arriba y desde abajo al mismo tiempo.
; ----------------------------------------------------------------------
baja_la_cortinilla:
	ld hl,(0e00eh)		;4892   ; por donde va
	ld de,00020h		;4895   ; una fila, 32 celdas
	add hl,de			;4898
	ld (0e00eh),hl		;4899
	ex de,hl			;489c
	or a			;489d
	ld hl,03aaah		;489e   ; el punto de reflejo
	sbc hl,de		;48a1   ; restando sale la franja de abajo
	ex de,hl			;48a3
	ld a,040h		;48a4   ; el primer patron
	ld bc,00303h		;48a6   ; tres por tres
L_48A9:
	push de			;48a9
L_48AA:
	call escribe_en_vram		;48aa   ; el patron
	inc de			;48ad
	inc a			;48ae   ; el siguiente, uno mas
	djnz L_48AA		;48af
	pop de			;48b1
	ld hl,00020h		;48b2   ; la fila de abajo
	add hl,de			;48b5
	ex de,hl			;48b6
	ld h,a			;48b7
	ld a,00eh		;48b8   ; catorce menos lo que se lleva pintado
	sub c			;48ba
	ld b,a			;48bb
	ld a,h			;48bc
	dec c			;48bd
	jr nz,L_48A9		;48be
	ld bc,0000ch		;48c0   ; doce celdas de relleno
	xor a			;48c3
	set 6,d		;48c4
	call rellena_vram		;48c6
	ld hl,0e00ah		;48c9
	dec (hl)			;48cc   ; un paso menos
	ret			;48cd

; ----------------------------------------------------------------------
; EL CUADRO DE LA PARTIDA, y es el indice del cartucho: VEINTISIETE llamadas seguidas, una por cada cosa que se mueve o se pinta, y al final el reloj. Lo que va primero se pinta antes, asi que el orden ES la profundidad.
; ----------------------------------------------------------------------
el_cuadro_de_la_partida:
	call guarda_la_columna_de_los_carros		;48ce
	call L_56DC		;48d1
	call L_5735		;48d4
	call pinta_los_panes		;48d7   ; el contador de panes
	call sube_el_contador_de_panes		;48da
	call mueve_al_panadero		;48dd
	call mira_si_salta		;48e0
	call coloca_el_indicador		;48e3
	call L_5824		;48e6
	call mueve_los_tres_carros		;48e9
	call mira_el_disparo_contra_el_carro		;48ec
	call mira_el_carro_contra_la_cinta		;48ef
	call arranca_un_carro_por_el_reloj		;48f2
	call mira_los_dos_carros_contra_algo		;48f5
	call mira_si_el_sonido_va_por_c3		;48f8
	call L_576B		;48fb
	call L_57DA		;48fe
	call mueve_los_ocho_bichos		;4901
	call pinta_la_fila_de_marcas		;4904
	call parpadea_el_aviso		;4907
	call mueve_las_tres_cosas		;490a
	call mueve_el_gato		;490d
	call mira_si_dispara		;4910
	call L_53FF		;4913
	call retira_el_carro_que_se_sale		;4916
	call L_58FC		;4919
	call busca_el_carro_en_el_estado_10		;491c
	call el_reloj_de_la_jornada		;491f   ; y el reloj, lo ultimo
	ld a,(0e00bh)		;4922   ; el compas de ocho
	cp 007h		;4925   ; solo cuando vale 7
	jr nz,L_4931		;4927
	ld hl,0e103h		;4929
	ld a,(hl)			;492c   ; dos bytes de estado, intercambiados
	ld (hl),000h		;492d
	dec hl			;492f
	ld (hl),a			;4930
L_4931:
	call avanza_el_estado_del_disparo		;4931
	call L_707A		;4934
	ld a,(0e00bh)		;4937   ; otra vez el compas
	cp 007h		;493a
	ret nz			;493c
	call pinta_los_panes_en_la_cinta		;493d
L_4940:
	ld hl,0e1a0h		;4940
	ld de,079a0h		;4943   ; el destino en la VRAM
	ld bc,00140h		;4946   ; 320 bytes de un tiron
	jp vuelca_bloque		;4949

; ----------------------------------------------------------------------
; PREPARAR LA FASE: copia los nueve valores iniciales a 0xE110 y pone a cero siete variables sueltas, una por una.
; ----------------------------------------------------------------------
prepara_la_fase:
	ld hl,04a1fh		;494c   ; los nueve valores iniciales
	ld de,0e110h		;494f
	ld bc,00009h		;4952   ; nueve bytes
	ldir		;4955
	ld a,000h		;4957
	ld (0e104h),a		;4959   ; y siete variables a cero
	ld (0e121h),a		;495c
	ld (0e103h),a		;495f
	ld (0e102h),a		;4962
	ld (0e109h),a		;4965
	ld (0e12ah),a		;4968
	ld (0e05bh),a		;496b
	ld a,001h		;496e
	ld (0e056h),a		;4970
	ld (0e10ah),a		;4973
	ld a,004h		;4976
	ld (0e120h),a		;4978
	ld a,008h		;497b
	ld (0e101h),a		;497d
	ld a,014h		;4980
	ld (0e199h),a		;4982
	ld a,0aeh		;4985
	ld (0e125h),a		;4987

; ----------------------------------------------------------------------
; Y AQUI TAMBIEN SALE EL AZAR DEL REGISTRO R, como en Magical Tree: dos bits del contador de refresco se suman al numero de fase, se dobla el resultado y se recorta a 0x17. Si sale cero se fuerza a uno. De ahi sale la variante con la que arranca la fase, sin semilla ni tabla.
; ----------------------------------------------------------------------
	ld a,(0e051h)		;498a   ; el numero de fase
	ld c,a			;498d
	ld a,r		;498e   ; el contador de refresco del Z80: el azar
	and 003h		;4990   ; dos bits
	add a,c			;4992   ; sumados a la fase
	add a,a			;4993
	and 017h		;4994   ; y recortado
	jr nz,L_499A		;4996
	ld a,001h		;4998   ; si sale cero, se fuerza uno
L_499A:
	ld (0e19ah),a		;499a
	ld a,c			;499d
	dec a			;499e   ; la fase 1 no lleva desplazamiento
	jr z,monta_la_fase		;499f
	ld a,070h		;49a1
	ld (0e057h),a		;49a3

; ----------------------------------------------------------------------
; EL MONTAJE DE LA FASE. La lista de 0xE160 se rellena con `ldir` propagando un UNO -no un cero- desde la propia celda, y luego se cierra a mano con un 2 y un 3. Detras vienen ocho llamadas con parejas de coordenadas: es el decorado de la panaderia, montado por trozos.
; ----------------------------------------------------------------------
monta_la_fase:
	ld hl,0e160h		;49a6
	ld (hl),000h		;49a9   ; el primer hueco, a cero
	inc hl			;49ab
	ld de,0e162h		;49ac
	ld (hl),001h		;49af   ; un uno
	ld bc,0001eh		;49b1   ; treinta bytes
	ldir		;49b4   ; y el ldir lo arrastra
	ld (hl),002h		;49b6   ; los dos ultimos, a mano
	inc hl			;49b8
	ld (hl),003h		;49b9
	ld de,00b98h		;49bb
	call L_6138		;49be
	ld de,013e8h		;49c1
	call L_614B		;49c4
	ld de,00c00h		;49c7
	call L_619A		;49ca
	ld de,01400h		;49cd
	call L_619A		;49d0
	call L_61AD		;49d3
	ld a,0f1h		;49d6
	call L_60A6		;49d8
	call L_6184		;49db
	ld de,02b98h		;49de
	call L_615E		;49e1
	ld de,033e8h		;49e4
	call L_6171		;49e7
	call L_5897		;49ea   ; el marcador
	call pinta_los_panes		;49ed   ; el contador de panes
	xor a			;49f0
	ld (0e055h),a		;49f1
	ld c,a			;49f4
	ld b,020h		;49f5   ; treinta y dos huecos
	ld de,0e1a0h		;49f7   ; el bufer de 0xE1A0
L_49FA:
	push bc			;49fa
	push de			;49fb
	ld a,c			;49fc
	call pinta_una_columna_de_la_cinta		;49fd
	pop de			;4a00
	inc de			;4a01
	pop bc			;4a02
	inc c			;4a03   ; el numero de hueco
	djnz L_49FA		;4a04
	call L_4940		;4a06
	call pinta_los_panes_del_otro_lado		;4a09
	call pinta_los_panes_en_la_cinta		;4a0c
	ld hl,05e68h		;4a0f   ; el bloque comprimido del decorado
	call descomprime		;4a12
	call pinta_la_barra_de_progreso		;4a15
	call pinta_el_reloj		;4a18   ; y el reloj a cero
	call L_70D6		;4a1b
	ret			;4a1e

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4a1f..0x4a28  (9 bytes)
DATA_4A1F:
	defb 001h,037h,000h,007h,001h,057h,0f0h,000h,0f0h	; 4a1f  .7...W...

; ======================================================================
; CODIGO 0x4a28..0x4bb3  (395 bytes)
; ======================================================================


mira_si_dispara:
	ld hl,0e121h		;4a28
	ld a,(hl)			;4a2b   ; la bandera de 0xE121
	or a			;4a2c
	jr nz,L_4A41		;4a2d
	dec hl			;4a2f
	ld a,(hl)			;4a30
	or a			;4a31
	ret z			;4a32
	ld a,(0e124h)		;4a33   ; el plazo de recarga
	or a			;4a36
	ret nz			;4a37
	call flanco_del_boton_10		;4a38   ; y que se acabe de pulsar el boton
	ret z			;4a3b
	dec (hl)			;4a3c   ; la recarga, uno menos
	inc hl			;4a3d
	call arranca_el_disparo		;4a3e
L_4A41:
	ld a,(0e00bh)		;4a41   ; el compas de ocho
	rra			;4a44   ; uno de cada dos
	ret c			;4a45
	call avanza_el_disparo		;4a46
	ret			;4a49

; ----------------------------------------------------------------------
; ARRANCAR EL DISPARO. Su duracion depende de la fase -14 cuadros hasta la cuarta, 18 desde ella-, y la direccion elige uno de tres juegos de desplazamientos: (0x18, 0xF2), (0x18, 0x0E) o ninguno. Los tres sprites se colocan a partir de la posicion del panadero.
; ----------------------------------------------------------------------
arranca_el_disparo:
	ld a,(0e051h)		;4a4a   ; el numero de fase
	ld (hl),00eh		;4a4d   ; catorce cuadros
	cp 004h		;4a4f   ; de la cuarta en adelante
	jr c,L_4A55		;4a51
	ld (hl),012h		;4a53   ; dieciocho
L_4A55:
	inc hl			;4a55
	ld a,(hl)			;4a56
	inc hl			;4a57
	ld (hl),a			;4a58   ; la direccion, guardada
	or a			;4a59
	jr z,L_4A6D		;4a5a
	dec a			;4a5c
	jr nz,L_4A66		;4a5d
	ld a,00ch		;4a5f   ; un juego de desplazamientos
	ld bc,018f2h		;4a61
	jr L_4A72		;4a64
L_4A66:
	ld a,010h		;4a66   ; otro
	ld bc,0180eh		;4a68
	jr L_4A72		;4a6b
L_4A6D:
	ld a,008h		;4a6d   ; y el tercero, sin desplazar
	ld bc,00000h		;4a6f
L_4A72:
	ld de,0e092h		;4a72   ; el hueco del sprite
	ld hl,0e081h		;4a75   ; y la posicion del panadero
	ld (de),a			;4a78
	dec de			;4a79
	ld a,(hl)			;4a7a
	add a,c			;4a7b
	ld (de),a			;4a7c
	dec de			;4a7d
	dec hl			;4a7e
	ld a,(hl)			;4a7f
	add a,b			;4a80
	ld (de),a			;4a81
	ld a,(0e123h)		;4a82   ; la variante de 0xE123
	ld c,a			;4a85
	ld b,010h		;4a86   ; dieciseis
	or a			;4a88
	jr nz,L_4A8D		;4a89
	ld b,014h		;4a8b   ; o veinte
L_4A8D:
	ld hl,0e105h		;4a8d
	ld a,(0e101h)		;4a90
	and 00ch		;4a93   ; los dos bits de direccion
	jr z,L_4A9E		;4a95
	sub 004h		;4a97
	jr z,L_4A9D		;4a99
	ld a,018h		;4a9b
L_4A9D:
	ld (hl),a			;4a9d
L_4A9E:
	ld a,(hl)			;4a9e
	add a,b			;4a9f
	call pinta_la_pose_del_panadero		;4aa0
	ld a,002h		;4aa3   ; el sonido del disparo
	call L_799C		;4aa5
	ld a,(0e123h)		;4aa8
	ld b,a			;4aab
	or a			;4aac
	jr z,mueve_el_disparo_recto		;4aad
L_4AAF:
	dec a			;4aaf
	ld a,003h		;4ab0   ; tres pixeles
	jr z,L_4AB6		;4ab2
	ld a,0fdh		;4ab4   ; o tres hacia atras
L_4AB6:
	call corre_los_cuatro_sprites		;4ab6
	ret			;4ab9
mueve_el_disparo_recto:
	ld a,(0e105h)		;4aba
	or a			;4abd
	ld c,001h		;4abe   ; un pixel hacia delante
	jr z,L_4AC4		;4ac0
	ld c,0ffh		;4ac2   ; o uno hacia atras
L_4AC4:
	ld hl,0e085h		;4ac4
	ld a,(hl)			;4ac7
	add a,c			;4ac8   ; la posicion, corrida
	ld (hl),a			;4ac9
	add a,c			;4aca
	ld (0e081h),a		;4acb   ; y los otros dos sprites, uno mas alla
	ld (0e089h),a		;4ace
	ret			;4ad1
avanza_el_disparo:
	ld hl,0e121h		;4ad2
	dec (hl)			;4ad5   ; la recarga, uno menos
	jr z,L_4B04		;4ad6
	inc hl			;4ad8
	inc hl			;4ad9
	ld a,(hl)			;4ada
	or a			;4adb

; ----------------------------------------------------------------------
; EL VUELO DEL DISPARO. Cuatro pixeles por cuadro en la direccion que lleve, y se acaba por los BORDES: por debajo de 0x28, por encima de 0xE0 o cuando la resta desborda. Es lo que evita llevar una cuenta de alcance.
; ----------------------------------------------------------------------
	ld hl,0e091h		;4adc
	jr z,L_4AF4		;4adf
	dec a			;4ae1
	jr nz,L_4AEB		;4ae2
	ld a,(hl)			;4ae4
	sub 004h		;4ae5   ; cuatro pixeles hacia atras
	ld (hl),a			;4ae7
	jr c,L_4AFC		;4ae8   ; si desborda, se acabo
	ret			;4aea
L_4AEB:
	ld a,(hl)			;4aeb
	add a,004h		;4aec   ; cuatro hacia delante
	ld (hl),a			;4aee
	cp 0e0h		;4aef   ; el borde de la pantalla
	jr nc,L_4AFC		;4af1
	ret			;4af3
L_4AF4:
	dec hl			;4af4
	ld a,(hl)			;4af5
	sub 004h		;4af6   ; y en la otra coordenada
	ld (hl),a			;4af8
	cp 028h		;4af9   ; el borde de arriba
	ret nc			;4afb
L_4AFC:
	ld a,(0e121h)		;4afc
	cp 008h		;4aff   ; la recarga
	call nc,recoloca_los_cuatro_sprites		;4b01
L_4B04:
	xor a			;4b04
	ld (0e121h),a		;4b05
	ld a,0e0h		;4b08   ; 0xE0: el sprite sale de la pantalla
	ld (0e090h),a		;4b0a
	ret			;4b0d
sube_el_contador_de_panes:
	ld a,(0e003h)		;4b0e   ; el contador de cuadros
	and 0ffh		;4b11   ; solo cuando da la vuelta a cero
	ret nz			;4b13
	ld hl,0e120h		;4b14
	ld a,(hl)			;4b17
	cp 004h		;4b18   ; el tope son cuatro
	ret nc			;4b1a
	inc (hl)			;4b1b   ; uno mas
	ret			;4b1c
avanza_el_estado_del_disparo:
	ld hl,0e124h		;4b1d   ; el plazo de 0xE124
	ld a,(hl)			;4b20
	or a			;4b21
	jr z,L_4B2D		;4b22
	xor a			;4b24
	dec (hl)			;4b25   ; uno menos
	call z,pinta_la_pose_del_panadero		;4b26
	xor a			;4b29
	ld (0e102h),a		;4b2a
L_4B2D:
	ld a,(0e121h)		;4b2d
	cp 008h		;4b30   ; la recarga, contra ocho
	jr z,L_4B3A		;4b32
	ret c			;4b34
	xor a			;4b35
	ld (0e102h),a		;4b36
	ret			;4b39
L_4B3A:
	ld a,(0e00bh)		;4b3a
	rra			;4b3d   ; uno de cada dos cuadros
	ret c			;4b3e

; ----------------------------------------------------------------------
; RECOLOCAR LOS CUATRO SPRITES DEL PANADERO de una vez: se calcula la columna nueva y se escribe en los cuatro huecos -0xE085, 0xE081, 0xE089 y 0xE08D-, que estan separados cuatro bytes. La figura es de cuatro sprites y se mueve como uno.
; ----------------------------------------------------------------------
recoloca_los_cuatro_sprites:
	ld a,(0e105h)		;4b3f
	ld c,a			;4b42
	call pinta_la_pose_del_panadero		;4b43   ; el sonido
	ld a,(0e123h)		;4b46
	or a			;4b49
	jr z,L_4B50		;4b4a
	dec a			;4b4c
	jp L_4AAF		;4b4d
L_4B50:
	ld a,c			;4b50
	or a			;4b51
	ld a,0ffh		;4b52   ; un pixel hacia atras
	jr z,L_4B58		;4b54
	ld a,001h		;4b56   ; o uno hacia delante
L_4B58:
	ld hl,0e085h		;4b58
	add a,(hl)			;4b5b   ; la columna, corrida
	ld (hl),a			;4b5c
	ld (0e081h),a		;4b5d   ; y los otros tres sprites, igual
	ld (0e089h),a		;4b60
	ld (0e08dh),a		;4b63
	ret			;4b66

; ----------------------------------------------------------------------
; EL MARCADOR DE ARRIBA, con el dibujo alternando por el bit 4 del contador de cuadros -uno de cada dieciseis- entre los patrones 0x5D y 0x5F.
; ----------------------------------------------------------------------
pinta_el_marcador_de_arriba:
	ld a,(0e003h)		;4b67
	bit 4,a		;4b6a   ; el bit 4 del contador de cuadros
	ld c,05dh		;4b6c   ; un patron
	jr nz,L_4B72		;4b6e
	ld c,05fh		;4b70   ; o el otro
L_4B72:
	ld de,04bb3h		;4b72
	exx			;4b75
	ld de,020ffh		;4b76
	ld hl,0e055h		;4b79   ; la posicion
	exx			;4b7c
	call pinta_una_marca_del_marcador		;4b7d
	exx			;4b80
	ld a,(0e057h)		;4b81
	ld e,a			;4b84
	ld d,000h		;4b85
	exx			;4b87
	call pinta_una_marca_del_marcador		;4b88
	call pinta_una_marca_del_marcador		;4b8b

; ----------------------------------------------------------------------
; PINTAR UNA MARCA DEL MARCADOR, trabajando con los DOS juegos de registros a la vez: en el alternativo van la posicion y la mascara, y en el normal el puntero al bufer de 0xE200. El bit 3 decide si la marca se pinta o se salta.
; ----------------------------------------------------------------------
pinta_una_marca_del_marcador:
	exx			;4b8e
	rr e		;4b8f   ; el siguiente bit de la mascara
	bit 3,e		;4b91   ; el bit 3
	exx			;4b93
	jr z,L_4BB0		;4b94
	ld b,002h		;4b96   ; dos celdas
L_4B98:
	ld a,(de)			;4b98
	exx			;4b99
	sub (hl)			;4b9a
	exx			;4b9b
	cp 020h		;4b9c   ; treinta y dos de margen
	jr nc,L_4BAC		;4b9e
	exx			;4ba0
	add a,d			;4ba1
	exx			;4ba2
	ld l,a			;4ba3
	ld h,0e2h		;4ba4   ; el bufer de 0xE200
	ld (hl),c			;4ba6
	ld a,b			;4ba7
	dec a			;4ba8   ; la segunda celda va con el patron anterior
	jr nz,L_4BAC		;4ba9
	dec (hl)			;4bab
L_4BAC:
	inc de			;4bac
	djnz L_4B98		;4bad
	ret			;4baf
L_4BB0:
	inc de			;4bb0
	inc de			;4bb1
	ret			;4bb2

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4bb3..0x4bbb  (8 bytes)
DATA_4BB3:
	defb 003h,007h,011h,01ah,024h,033h,03ch,04ch	; 4bb3  ....$3<L

; ======================================================================
; CODIGO 0x4bbb..0x4cc3  (264 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MOVIMIENTO DEL PANADERO, y el ritmo lo da el compas de ocho: el paso 0 mueve en una direccion, el 4 en la otra y el 7 hace algo distinto. O sea que en cada vuelta de ocho cuadros solo tres hacen trabajo.
; ----------------------------------------------------------------------
mueve_al_panadero:
	ld hl,0e101h		;4bbb
	ld a,(hl)			;4bbe   ; lo que se pulsa
	and 00ch		;4bbf   ; los dos bits de direccion
	jr z,L_4BC6		;4bc1
	ld (0e103h),a		;4bc3   ; guardado para el cuadro
L_4BC6:
	inc hl			;4bc6
	ld a,(hl)			;4bc7
	and 00ch		;4bc8
	ret z			;4bca
	ld a,(0e00bh)		;4bcb   ; el compas de ocho
	or a			;4bce   ; el paso 0
	jr z,L_4C1E		;4bcf
	cp 004h		;4bd1   ; el paso 4
	jp z,L_4C1A		;4bd3
	cp 007h		;4bd6   ; y el paso 7
	jp z,mueve_el_horno		;4bd8
	ret			;4bdb

; ----------------------------------------------------------------------
; SUBIR O BAJAR DE PLANTA. La planta esta en (0xE056) y el bit 2 de (0xE102) dice hacia donde; cuando la posicion llega a 0x78 con la planta correcta, se completa el cambio. Los topes son 0x18 por arriba y 0xE8 por abajo.
; ----------------------------------------------------------------------
sube_o_baja_el_panadero:
	ld hl,0e081h		;4bdc
	ld a,(0e056h)		;4bdf   ; la planta
	sub 001h		;4be2
	ret c			;4be4
	ld c,a			;4be5
	ld a,(0e102h)		;4be6   ; la direccion guardada
	and 004h		;4be9   ; su bit 2
	rrca			;4beb   ; bajado a su sitio
	rrca			;4bec
	cp c			;4bed
	ld c,a			;4bee
	jr nz,L_4BFB		;4bef
	ld a,(hl)			;4bf1
	cp 078h		;4bf2   ; la posicion de enganche
	jr nz,L_4BFB		;4bf4
	xor a			;4bf6
	ld (0e056h),a		;4bf7   ; y la planta queda cambiada
	ret			;4bfa
L_4BFB:
	ld a,(hl)			;4bfb
	dec c			;4bfc
	jr z,L_4C06		;4bfd
	cp 0e8h		;4bff   ; el tope de abajo
	ret nc			;4c01
	ld a,004h		;4c02   ; cuatro pixeles
	jr nz,corre_los_cuatro_sprites		;4c04
L_4C06:
	cp 018h		;4c06   ; el tope de arriba
	ret c			;4c08
	ld a,0fch		;4c09   ; y cuatro hacia atras
corre_los_cuatro_sprites:
	ld hl,0e081h		;4c0b
	add a,(hl)			;4c0e   ; la fila, corrida
	ld (hl),a			;4c0f
	ld (0e085h),a		;4c10   ; y los otros tres sprites, igual
	ld (0e089h),a		;4c13
	ld (0e08dh),a		;4c16
	ret			;4c19
L_4C1A:
	ld b,000h		;4c1a
	jr L_4C40		;4c1c
L_4C1E:
	ld a,(0e102h)		;4c1e
	bit 3,a		;4c21
	ld a,000h		;4c23
	jr z,L_4C29		;4c25
	ld a,018h		;4c27
L_4C29:
	ld (0e105h),a		;4c29
	ld b,004h		;4c2c
	ld hl,(0e055h)		;4c2e
	ld a,l			;4c31
	dec h			;4c32
	jr c,L_4C3B		;4c33
	ld a,(0e081h)		;4c35
	rrca			;4c38
	rrca			;4c39   ; tres giros
	rrca			;4c3a
L_4C3B:
	rrca			;4c3b
	jr nc,L_4C40		;4c3c
	ld b,008h		;4c3e   ; ocho de desplazamiento
L_4C40:
	ld a,(0e104h)		;4c40
	or a			;4c43
	jr nz,L_4C4D		;4c44
	ld a,(0e105h)		;4c46
	add a,b			;4c49
	call pinta_la_pose_del_panadero		;4c4a
L_4C4D:
	call sube_o_baja_el_panadero		;4c4d
	ret			;4c50

; ----------------------------------------------------------------------
; LA POSE DEL PANADERO: cuatro patrones sacados de la tabla de 0x7124, escritos en los cuatro huecos de sprite separados cuatro bytes. Una sola tabla y un bucle de cuatro.
; ----------------------------------------------------------------------
pinta_la_pose_del_panadero:
	ld hl,07124h		;4c51   ; la tabla de poses
	call suma_a_a_hl		;4c54
	ld de,0e082h		;4c57   ; el primer hueco de sprite
	ld b,004h		;4c5a   ; cuatro sprites
L_4C5C:
	ld a,(hl)			;4c5c   ; el patron
	ld (de),a			;4c5d
	inc hl			;4c5e
	ld a,004h		;4c5f   ; cuatro bytes por sprite
	call suma_a_a_de		;4c61
	djnz L_4C5C		;4c64
	ret			;4c66

; ----------------------------------------------------------------------
; EL SALTO. Solo se puede si la recarga esta por debajo de 14 y se acaban de pulsar los dos botones; entonces el plazo se pone a 11 y el paso de la pose depende de la direccion. Mientras dura, avanza uno de cada cuatro cuadros.
; ----------------------------------------------------------------------
mira_si_salta:
	ld hl,0e104h		;4c67
	ld a,(hl)			;4c6a   ; el estado del salto
	or a			;4c6b
	jr nz,L_4C92		;4c6c
	ld a,(0e121h)		;4c6e   ; la recarga
	cp 00eh		;4c71   ; por encima de catorce no se puede
	ret nc			;4c73
	call flanco_de_los_dos_botones		;4c74   ; y que se acaben de pulsar los dos botones
	ret z			;4c77
	ld a,001h		;4c78   ; el sonido del salto
	call L_799C		;4c7a
	ld (hl),00bh		;4c7d   ; once cuadros de salto
	inc hl			;4c7f
	ld a,(0e101h)		;4c80
	and 00ch		;4c83   ; los dos bits de direccion
	jr z,L_4C8E		;4c85
	sub 004h		;4c87
	jr z,L_4C8D		;4c89
	ld a,018h		;4c8b
L_4C8D:
	ld (hl),a			;4c8d
L_4C8E:
	ld a,00ch		;4c8e
	jr L_4C9D		;4c90
L_4C92:
	ld a,(0e003h)		;4c92   ; el contador de cuadros
	and 003h		;4c95   ; uno de cada cuatro
	ret nz			;4c97
	dec (hl)			;4c98   ; el plazo, uno menos
	jr nz,avanza_el_salto		;4c99
	xor a			;4c9b
	inc hl			;4c9c
L_4C9D:
	add a,(hl)			;4c9d
	call pinta_la_pose_del_panadero		;4c9e

; ----------------------------------------------------------------------
; EL AVANCE DEL SALTO: la tabla de 0x4CC3 -indexada por el paso- da el desplazamiento, y se reparte entre los CUATRO sprites con desplazamientos fijos de +0x10, -8 y +0x18 entre ellos. La figura sube entera.
; ----------------------------------------------------------------------
avanza_el_salto:
	ld hl,04cc3h		;4ca1   ; la tabla de alturas del salto
	ld a,(0e104h)		;4ca4   ; el paso
	ld c,a			;4ca7
	call suma_a_a_hl		;4ca8
	ld a,(hl)			;4cab
	ld hl,0e080h		;4cac
	add a,(hl)			;4caf   ; aplicado al primer sprite
	ld (hl),a			;4cb0
	add a,010h		;4cb1   ; y los otros tres, desplazados
	ld (0e084h),a		;4cb3
	sub 008h		;4cb6
	ld (0e088h),a		;4cb8
	add a,018h		;4cbb
	ld (0e08ch),a		;4cbd
	jp L_4DF2		;4cc0

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4cc3..0x4ccf  (12 bytes)
DATA_4CC3:
	defb 008h,007h,005h,004h,001h,001h,0ffh,0ffh,0fch,0fbh,0f9h,0f8h	; 4cc3  ............

; ======================================================================
; CODIGO 0x4ccf..0x4ef6  (551 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL HORNO QUE SE LLENA. El bufer de 0xE1A0 se corre 320 bytes con `lddr` -hacia atras- o con `ldir` -hacia delante- segun suba o baje, que es como se anima la cinta sin recalcular nada.
; ----------------------------------------------------------------------
mueve_el_horno:
	ld a,(0e056h)		;4ccf   ; la planta
	or a			;4cd2
	ret nz			;4cd3
	ld a,(0e102h)		;4cd4   ; el estado del horno
	or a			;4cd7
	ret z			;4cd8
	cp 008h		;4cd9
	ld hl,0e055h		;4cdb
	ld a,(hl)			;4cde
	jr z,L_4CF6		;4cdf
	or a			;4ce1
	jr z,L_4D29		;4ce2
	dec (hl)			;4ce4   ; uno menos
	ld a,(hl)			;4ce5
	ld hl,0e2deh		;4ce6
	ld de,0e2dfh		;4ce9
	ld bc,00140h		;4cec   ; 320 bytes
	lddr		;4cef   ; corridos hacia atras
	ld de,0e1a0h		;4cf1
	jr pinta_una_columna_de_la_cinta		;4cf4
L_4CF6:
	sub 03ch		;4cf6   ; el tope
	jr z,L_4D28		;4cf8
	inc (hl)			;4cfa
	ld a,(hl)			;4cfb
	add a,01fh		;4cfc
	ld hl,0e1a1h		;4cfe   ; el bufer, una celda mas alla
	ld de,0e1a0h		;4d01
	ld bc,00140h		;4d04
	ldir		;4d07   ; y los 320 bytes se corren hacia delante
	ld de,0e1bfh		;4d09

; ----------------------------------------------------------------------
; PINTAR UNA COLUMNA DE LA CINTA. El indice se multiplica por DIEZ sin multiplicar: `add hl,hl` tres veces da ocho veces, y sumando el doble guardado antes salen los diez. Luego se copian diez indices, uno por fila, saltando 32 celdas entre ellos.
; ----------------------------------------------------------------------
pinta_una_columna_de_la_cinta:
	ld l,a			;4d0c
	ld h,000h		;4d0d
	add hl,hl			;4d0f   ; por dos
	ld b,h			;4d10   ; el doble, guardado
	ld c,l			;4d11
	add hl,hl			;4d12   ; por ocho
	add hl,hl			;4d13
	add hl,bc			;4d14   ; y ocho mas dos son DIEZ
	ld bc,07604h		;4d15   ; la tabla de columnas
	add hl,bc			;4d18
	ld b,00ah		;4d19   ; diez filas
L_4D1B:
	ld a,(hl)			;4d1b
	ld (de),a			;4d1c
	inc hl			;4d1d
	ld a,020h		;4d1e   ; la fila de abajo, 32 celdas
	call suma_a_a_de		;4d20
	djnz L_4D1B		;4d23
	jp L_5897		;4d25
L_4D28:
	inc a			;4d28
L_4D29:
	inc a			;4d29
	ld (0e056h),a		;4d2a
	ret			;4d2d

; ----------------------------------------------------------------------
; EL PANADERO ALCANZADO: la pose cambia cada cuatro cuadros con los bits 2 y 3 del contador -tres dibujos, 0, 4 y 8- y baja hasta 0x98, donde se para. Al llegar, el plazo se pone a 16 y suena.
; ----------------------------------------------------------------------
el_panadero_alcanzado:
	call mueve_las_tres_cosas		;4d2e
	ld hl,0e124h		;4d31   ; el plazo
	ld a,(hl)			;4d34
	or a			;4d35
	jr z,L_4D3A		;4d36
	dec (hl)			;4d38
	ret			;4d39
L_4D3A:
	ld hl,0e003h		;4d3a
	ld a,(hl)			;4d3d
	and 003h		;4d3e   ; uno de cada cuatro cuadros
	ret nz			;4d40
	xor a			;4d41
	bit 2,(hl)		;4d42   ; el bit 2 elige el segundo dibujo
	jr z,L_4D4E		;4d44
	ld a,004h		;4d46
	bit 3,(hl)		;4d48   ; y el bit 3 el tercero
	jr z,L_4D4E		;4d4a
	ld a,008h		;4d4c
L_4D4E:
	call pinta_la_pose_del_panadero		;4d4e
	ld c,001h		;4d51   ; un pixel hacia abajo
	ld hl,0e081h		;4d53
	call L_4BFB		;4d56
	cp 098h		;4d59   ; hasta llegar a 0x98
	jr z,L_4D65		;4d5b
	push af			;4d5d
	call L_707A		;4d5e
	pop af			;4d61
	cp 040h		;4d62
	ret			;4d64
L_4D65:
	ld a,010h		;4d65   ; dieciseis cuadros de plazo
	ld (0e124h),a		;4d67
	ld a,070h		;4d6a
	ld (0e057h),a		;4d6c
	ld (0e0c7h),a		;4d6f
	ld a,030h		;4d72
	call pinta_la_pose_del_panadero		;4d74   ; y la pose de estar tumbado
	call L_5897		;4d77
	call L_4940		;4d7a
L_4D7D:
	call L_707A		;4d7d
	or a			;4d80
	ret			;4d81

; ----------------------------------------------------------------------
; PONER EN PIE AL PANADERO: copia dieciseis bytes de sprites y doce mas, le pone la pose 0 y saca sus cuatro sprites de la pantalla con la fila 0xD0.
; ----------------------------------------------------------------------
pone_en_pie_al_panadero:
	ld hl,07096h		;4d82   ; los dieciseis bytes de sus sprites
	ld de,0e080h		;4d85
	ld bc,00010h		;4d88
	ldir		;4d8b
	ld hl,070cah		;4d8d   ; y los doce del resto
	ld de,0e0b4h		;4d90
	ld bc,0000ch		;4d93
	ldir		;4d96
	call L_7086		;4d98
	ld a,000h		;4d9b
	ld (0e105h),a		;4d9d
	call pinta_la_pose_del_panadero		;4da0
	ld b,004h		;4da3   ; cuatro sprites
	ld hl,0e081h		;4da5
L_4DA8:
	ld (hl),0d0h		;4da8   ; 0xD0: fuera de la pantalla
	ld a,l			;4daa
	add a,004h		;4dab   ; cuatro bytes por sprite
	ld l,a			;4dad
	djnz L_4DA8		;4dae
	ld a,008h		;4db0
	ld (0e0b7h),a		;4db2
	ld (0e0bbh),a		;4db5
	ld (0e0bfh),a		;4db8
	jp L_4D7D		;4dbb

; ----------------------------------------------------------------------
; EL INDICADOR QUE SIGUE AL PANADERO: su columna sale de dividir la del panadero entre CUATRO (`srl a` dos veces), redondear a par y sumarle un desplazamiento distinto por planta -0x2A, 0x0C o 0x84-. Y su patron alterna entre 0x0F y 0x09 con el compas de dieciseis.
; ----------------------------------------------------------------------
coloca_el_indicador:
	ld hl,0e095h		;4dbe
	ld a,(0e056h)		;4dc1   ; la planta
	or a			;4dc4
	jr nz,L_4DCF		;4dc5
	ld a,(0e055h)		;4dc7
	add a,a			;4dca
	ld e,02ah		;4dcb   ; el desplazamiento de la planta baja
	jr L_4DDF		;4dcd
L_4DCF:
	ld e,00ch		;4dcf   ; el de la primera
	dec a			;4dd1
	jr z,L_4DD6		;4dd2
	ld e,084h		;4dd4   ; y el de la segunda
L_4DD6:
	ld a,(0e081h)		;4dd6   ; la columna del panadero
	srl a		;4dd9   ; dividida entre cuatro
	srl a		;4ddb
	and 0feh		;4ddd   ; redondeada a par
L_4DDF:
	add a,e			;4ddf
	ld (hl),a			;4de0
	ld a,(0e003h)		;4de1   ; el contador de cuadros
	and 00fh		;4de4   ; el nibble bajo
	cp 008h		;4de6   ; medio ciclo
	ld a,00fh		;4de8   ; un patron
	jr nc,L_4DEE		;4dea
	ld a,009h		;4dec   ; o el otro
L_4DEE:
	inc hl			;4dee
	inc hl			;4def
	ld (hl),a			;4df0
	ret			;4df1
L_4DF2:
	ld a,c			;4df2
	ld hl,0e094h		;4df3
	dec (hl)			;4df6
	cp 006h		;4df7
	jr nc,L_4DFD		;4df9
	inc (hl)			;4dfb
	inc (hl)			;4dfc
L_4DFD:
	ret			;4dfd
repone_la_fila_de_marcas:
	ld hl,04efch		;4dfe   ; los dieciocho valores de partida
	ld de,0e181h		;4e01
	ld bc,00012h		;4e04   ; dieciocho bytes
	ldir		;4e07
	ret			;4e09

; ----------------------------------------------------------------------
; LA FILA DE MARCAS DE ARRIBA, repintada cuando el compas de ocho vale 7. Recorre ocho fichas de 0xE061 y, para las que tengan el bit 0 y el bit 7 puestos, calcula la celda -cinco bits del byte por cuatro, mas 0x80- y le pone el patron 0x6D mas dos bits. Al final vuelca los dieciocho bytes a la VRAM de un tiron.
; ----------------------------------------------------------------------
pinta_la_fila_de_marcas:
	ld a,(0e00bh)		;4e0a   ; el compas de ocho
	cp 007h		;4e0d   ; solo cuando vale 7
	ret nz			;4e0f
	call repone_la_fila_de_marcas		;4e10
	ld hl,0e061h		;4e13
	ld d,0e1h		;4e16
	ld b,008h		;4e18   ; ocho fichas
L_4E1A:
	ld a,(hl)			;4e1a
	inc hl			;4e1b
	ld e,(hl)			;4e1c
	inc hl			;4e1d
	bit 0,e		;4e1e   ; el bit 0
	jr z,L_4E26		;4e20
	or a			;4e22
	jr nz,L_4E3B		;4e23
	inc a			;4e25
L_4E26:
	or a			;4e26
	jr z,L_4E3B		;4e27
	bit 7,e		;4e29   ; y el bit 7
	jr z,L_4E3B		;4e2b
	ld a,(hl)			;4e2d
	rrca			;4e2e   ; dos giros
	rrca			;4e2f
	and 01fh		;4e30
	add a,080h		;4e32   ; +0x80: el bufer de la fila
	ld e,a			;4e34
	ld a,(hl)			;4e35
	and 003h		;4e36   ; dos bits del estado
	add a,06dh		;4e38   ; +0x6D: el patron que toca
	ld (de),a			;4e3a
L_4E3B:
	inc hl			;4e3b
	djnz L_4E1A		;4e3c
	ld hl,0e181h		;4e3e
	ld de,07883h		;4e41   ; el destino en la VRAM
	ld bc,00012h		;4e44   ; dieciocho bytes
	jp vuelca_bloque		;4e47
mueve_las_tres_cosas:
	ld hl,0e003h		;4e4a
	ld a,(hl)			;4e4d
	and 003h		;4e4e   ; uno de cada cuatro cuadros
	ret nz			;4e50
L_4E51:
	ld a,(0e057h)		;4e51
	ld c,a			;4e54
	ld de,0e0b7h		;4e55
	ld b,003h		;4e58   ; tres
L_4E5A:
	ld a,(de)			;4e5a
	ld a,004h		;4e5b   ; un color
	rr c		;4e5d   ; el siguiente bit de la mascara
	bit 3,c		;4e5f   ; el bit 3
	jr nz,L_4E6B		;4e61
	ld a,00fh		;4e63   ; otro color
	bit 2,(hl)		;4e65
	jr z,L_4E6B		;4e67
	ld a,008h		;4e69   ; y el tercero
L_4E6B:
	ld (de),a			;4e6b
	inc de			;4e6c   ; cuatro bytes por sprite
	inc de			;4e6d
	inc de			;4e6e
	inc de			;4e6f
	djnz L_4E5A		;4e70
	ld hl,0e0b7h		;4e72
	ld de,03b37h		;4e75   ; el destino en la VRAM
	ld bc,00009h		;4e78   ; nueve bytes
	call vuelca_bloque		;4e7b
	ret			;4e7e

; ----------------------------------------------------------------------
; EL AVISO QUE PARPADEA cuando el reloj llega a las siete y pasa de 0x30: la celda 0x38B9 alterna entre dos patrones dandole la vuelta al bit 0, y el ritmo es de 32 o de 16 cuadros segun lo apurado que vaya el reloj. Cuanto menos tiempo queda, mas deprisa parpadea.
; ----------------------------------------------------------------------
parpadea_el_aviso:
	ld hl,(0e079h)		;4e7f   ; el reloj
	ld a,h			;4e82
	cp 007h		;4e83   ; las siete
	ret nz			;4e85
	ld a,l			;4e86
	cp 030h		;4e87   ; y por debajo de 0x30 todavia no
	ret c			;4e89
	ld c,01fh		;4e8a   ; una de cada 32
	jr z,L_4E90		;4e8c
	ld c,00fh		;4e8e   ; o una de cada 16 si esta mas apurado
L_4E90:
	ld a,(0e003h)		;4e90
	and c			;4e93
	ret nz			;4e94
	ld hl,0e125h		;4e95
	ld a,(hl)			;4e98
	xor 001h		;4e99   ; le da la vuelta al bit 0
	ld (hl),a			;4e9b
	ld de,038b9h		;4e9c   ; la celda del aviso
	call escribe_en_vram		;4e9f
	ret			;4ea2

; ----------------------------------------------------------------------
; LA BARRA DE PROGRESO: ocho bytes copiados a 0xE158 y, encima, tantas celdas 0x55 como diga (0xE060) dividido entre cuatro, con el resto eligiendo el remate de la tabla de 0x4EF8. Es como se dibuja una barra a media celda.
; ----------------------------------------------------------------------
pinta_la_barra_de_progreso:
	ld hl,06975h		;4ea3   ; los ocho valores de partida
	ld de,0e158h		;4ea6
	ld bc,00008h		;4ea9
	ldir		;4eac
	ld a,(0e060h)		;4eae   ; el progreso
	dec a			;4eb1
	jp m,L_4ED1		;4eb2
	ld c,a			;4eb5
	rrca			;4eb6   ; dividido entre cuatro
	rrca			;4eb7
	and 007h		;4eb8
	ld b,a			;4eba
	ld a,c			;4ebb
	and 003h		;4ebc   ; y el resto, dos bits
	ld hl,04ef8h		;4ebe   ; la tabla de cuatro remates
	call suma_a_a_hl		;4ec1
	ld c,(hl)			;4ec4
	ld hl,0e160h		;4ec5
L_4EC8:
	dec hl			;4ec8
	dec hl			;4ec9
	ld (hl),055h		;4eca   ; el patron lleno
	dec b			;4ecc
	jp p,L_4EC8		;4ecd
	ld (hl),c			;4ed0   ; y el remate a medias
L_4ED1:
	ld hl,0e158h		;4ed1
	ld de,066b0h		;4ed4   ; el destino en la VRAM
	ld bc,00008h		;4ed7   ; ocho bytes
	call vuelca_bloque		;4eda
	ld de,0389bh		;4edd
	ld bc,001a0h		;4ee0   ; 416 celdas
	ld hl,0e07bh		;4ee3
	ld a,(hl)			;4ee6
	or a			;4ee7
	jr z,L_4EED		;4ee8
	jp L_45FC		;4eea
L_4EED:
	ld hl,04ef6h		;4eed
	ld bc,00002h		;4ef0
	jp vuelca_bloque		;4ef3

; ----------------------------------------------------------------------
; DATOS sin identificar  0x4ef6..0x4f0e  (24 bytes)
DATA_4EF6:
	defb 0ach,0adh,040h,050h,054h,055h,000h,0c5h,0c7h,000h,000h,000h,0cbh,0cdh,000h,000h	; 4ef6  ..@PTU..........
	defb 000h,000h,0cfh,0d1h,000h,000h,000h,000h	; 4f06  ........

; ======================================================================
; CODIGO 0x4f0e..0x5103  (501 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL BUCLE DE LOS OCHO BICHOS, atendido solo cuando el nibble bajo del contador de cuadros vale 15: una vez de cada dieciseis.
; ----------------------------------------------------------------------
mueve_los_ocho_bichos:
	ld a,(0e003h)		;4f0e   ; el contador de cuadros
	and 00fh		;4f11
	cp 00fh		;4f13   ; solo cuando el nibble bajo vale 15
	ret nz			;4f15
	ld b,008h		;4f16   ; ocho bichos
	ld hl,0e062h		;4f18
L_4F1B:
	push bc			;4f1b
	push hl			;4f1c
	call mueve_un_bicho		;4f1d
	pop hl			;4f20
	inc hl			;4f21   ; tres bytes por bicho
	inc hl			;4f22
	inc hl			;4f23
	pop bc			;4f24
	djnz L_4F1B		;4f25
	ld a,(0e109h)		;4f27
	or a			;4f2a
	jp nz,pinta_el_marcador_de_arriba		;4f2b
	ld hl,0e055h		;4f2e
	ld a,004h		;4f31   ; cuatro menos la planta
	sub (hl)			;4f33
	jp c,pinta_el_marcador_de_arriba		;4f34
	add a,0e0h		;4f37   ; +0xE0: el hueco que le toca
	ld l,a			;4f39
	ld h,0e1h		;4f3a
	ld (hl),0a0h		;4f3c   ; y el patron 0xA0
	jp pinta_el_marcador_de_arriba		;4f3e

; ----------------------------------------------------------------------
; LA MAQUINA DE UN BICHO, y el estado cabe en TRES bits: el valor 0 y el 7 tienen camino propio y los seis de en medio son los pasos. Encima, el bit 7 marca si esta activo y los bits de 0xE057 y 0xE05F llevan mapas de ocupacion -un bit por bicho- para que dos no ocupen el mismo sitio.
; ----------------------------------------------------------------------
mueve_un_bicho:
	ld a,(hl)			;4f41   ; el estado del bicho
	ld b,a			;4f42
	and 007h		;4f43   ; los tres bits de abajo
	jr z,baja_el_plazo_del_bicho		;4f45   ; el estado 0
	cp 007h		;4f47   ; y el 7
	jp z,el_bicho_completa_su_recorrido		;4f49
	ld a,b			;4f4c
	rla			;4f4d   ; el bit 7: esta activo?
	ret nc			;4f4e
	ld a,(hl)			;4f4f
	inc a			;4f50   ; uno mas
	rla			;4f51   ; tres rotaciones
	rla			;4f52
	rla			;4f53
	and 030h		;4f54   ; dos bits
	cp 030h		;4f56   ; el valor 0x30 se cambia por 0x40
	jr nz,L_4F5C		;4f58
	ld a,040h		;4f5a
L_4F5C:
	ld c,a			;4f5c
	exx			;4f5d
	ld hl,0e057h		;4f5e   ; el mapa de ocupacion
	and (hl)			;4f61   ; si su bit ya esta puesto, no cabe
	exx			;4f62
	jr nz,baja_el_plazo_del_bicho		;4f63
	ld a,(hl)			;4f65
	rra			;4f66   ; el bit 0 del estado
	jr nc,pinta_el_bicho		;4f67
	dec hl			;4f69
	ld a,(hl)			;4f6a
	inc hl			;4f6b
	cp 006h		;4f6c   ; por debajo de seis no
	jr c,pinta_el_bicho		;4f6e
	ld a,c			;4f70
	exx			;4f71
	ld hl,0e05fh		;4f72   ; el otro mapa de ocupacion
	and (hl)			;4f75
	exx			;4f76
	jr nz,borra_la_ficha_del_bicho		;4f77
	ld a,c			;4f79
	exx			;4f7a
	or (hl)			;4f7b   ; se marca su bit
	ld (hl),a			;4f7c
	exx			;4f7d
	inc hl			;4f7e
	inc (hl)			;4f7f   ; y se mueven los dos contadores en sentidos contrarios
	inc (hl)			;4f80
	dec hl			;4f81
	dec hl			;4f82
	dec (hl)			;4f83
	dec (hl)			;4f84
	inc hl			;4f85
	jr pinta_el_bicho		;4f86
borra_la_ficha_del_bicho:
	dec hl			;4f88
L_4F89:
	xor a			;4f89   ; los tres bytes, a cero
	ld (hl),a			;4f8a
	inc hl			;4f8b
	ld (hl),a			;4f8c
	inc hl			;4f8d
	ld (hl),a			;4f8e
	ret			;4f8f
baja_el_plazo_del_bicho:
	dec hl			;4f90
	dec (hl)			;4f91   ; su plazo, uno menos
	call m,avanza_el_paso_del_bicho		;4f92   ; y al pasar de cero, se atiende
	inc hl			;4f95
	inc hl			;4f96
	inc (hl)			;4f97
	dec hl			;4f98
pinta_el_bicho:
	dec hl			;4f99
	ld c,(hl)			;4f9a
	inc hl			;4f9b
	inc hl			;4f9c
	ld a,(hl)			;4f9d
	ld hl,0e055h		;4f9e   ; la posicion del decorado
	sub (hl)			;4fa1
	cp 021h		;4fa2   ; treinta y tres de margen
	ret nc			;4fa4
	ld d,a			;4fa5
	ld a,b			;4fa6
	inc a			;4fa7   ; el paso siguiente
	and 006h		;4fa8
	ld h,a			;4faa   ; el paso
	add a,a			;4fab   ; por tres
	add a,h			;4fac
	ld hl,04010h		;4fad   ; la tabla de indices
	add a,l			;4fb0
	ld l,a			;4fb1
	ld e,0c0h		;4fb2   ; una fila
	ld a,b			;4fb4
	and 007h		;4fb5   ; los tres bits de abajo
	jr nz,L_4FBB		;4fb7
	ld e,0e0h		;4fb9   ; o la otra
L_4FBB:
	ld a,d			;4fbb
	add a,e			;4fbc
	ld e,a			;4fbd
	bit 0,b		;4fbe   ; el bit 0 del estado
	jr nz,elige_cuantos_tiles_pinta		;4fc0
	ld a,d			;4fc2
	exx			;4fc3
	ld hl,0e160h		;4fc4   ; la lista de posiciones
	add a,l			;4fc7
	ld l,a			;4fc8
	ld a,(hl)			;4fc9
	exx			;4fca
	dec c			;4fcb
	jr z,L_4FD5		;4fcc
	ld c,008h		;4fce   ; ocho
	jp m,L_4FD5		;4fd0
	ld c,010h		;4fd3   ; o dieciseis de desplazamiento
L_4FD5:
	add a,c			;4fd5
	bit 6,b		;4fd6   ; el bit 6
	jr z,L_4FDF		;4fd8
	add a,004h		;4fda   ; cuatro mas
L_4FDC:
	inc hl			;4fdc
	jr L_4FE4		;4fdd
L_4FDF:
	dec d			;4fdf
	jp m,L_4FDC		;4fe0
	dec e			;4fe3
L_4FE4:
	exx			;4fe4
	ld hl,04028h		;4fe5   ; la otra tabla de indices
	add a,l			;4fe8
	ld l,a			;4fe9
	ld a,(hl)			;4fea
	exx			;4feb
	ld c,a			;4fec
	jr vuelca_las_dos_filas		;4fed
elige_cuantos_tiles_pinta:
	ld a,c			;4fef
	cp 002h		;4ff0   ; por encima de dos, no cabe
	ret nc			;4ff2
	ld a,d			;4ff3
	cp 01fh		;4ff4   ; el borde
	ld a,001h		;4ff6   ; una celda
	jr z,L_4FFF		;4ff8
	ld a,002h		;4ffa   ; o dos
	jr c,L_4FFF		;4ffc
	xor a			;4ffe   ; o ninguna
L_4FFF:
	dec c			;4fff
	jr nz,L_5007		;5000
	sub 001h		;5002
	ret c			;5004
	inc de			;5005
	inc hl			;5006
L_5007:
	inc hl			;5007
	ld c,a			;5008

; ----------------------------------------------------------------------
; VOLCAR LAS DOS FILAS DEL BICHO al bufer de 0xE1xx: C celdas arriba y otras C abajo, con el salto de 0x20 -una fila de pantalla- entre las dos, y ajustando los punteros con lo que se haya pintado.
; ----------------------------------------------------------------------
vuelca_las_dos_filas:
	ld a,c			;5009
	or a			;500a   ; nada que pintar
	ret z			;500b
	ld d,0e1h		;500c
	ld b,c			;500e
L_500F:
	ld a,(hl)			;500f   ; un indice
	ld (de),a			;5010
	inc hl			;5011
	inc de			;5012
	djnz L_500F		;5013
	ld a,003h		;5015   ; tres menos lo pintado
	sub c			;5017
	call suma_a_a_hl		;5018
	ld a,020h		;501b   ; y treinta y dos menos lo pintado: la fila de abajo
	sub c			;501d
	call suma_a_a_de		;501e
	ld b,c			;5021
L_5022:
	ld a,(hl)			;5022   ; la segunda fila
	ld (de),a			;5023
	inc hl			;5024
	inc de			;5025
	djnz L_5022		;5026
	ret			;5028
avanza_el_paso_del_bicho:
	inc hl			;5029
	inc (hl)			;502a   ; el paso, uno mas
	ld b,(hl)			;502b
	ld de,0510fh		;502c   ; la tabla de plazos
	ld a,(hl)			;502f
	and 007h		;5030   ; tres bits del paso
	call suma_a_a_de		;5032
	dec hl			;5035
	ld a,(de)			;5036
	ld (hl),a			;5037
	ret			;5038

; ----------------------------------------------------------------------
; UN BICHO COMPLETA SU RECORRIDO: se borra su ficha, sube el contador de progreso (0xE060) y se guarda su valor en BCD para pintarlo.
; ----------------------------------------------------------------------
el_bicho_completa_su_recorrido:
	dec hl			;5039
	dec (hl)			;503a   ; su plazo, uno menos
	ld a,(hl)			;503b
	sub 001h		;503c
	ret nz			;503e
	call L_4F89		;503f
	ld hl,0e060h		;5042
	inc (hl)			;5045   ; el progreso, uno mas
	ld a,(hl)			;5046
	dec a			;5047
	add a,001h		;5048   ; en BCD
	daa			;504a
	ld (0e07bh),a		;504b
	call pinta_la_barra_de_progreso		;504e   ; y se repinta la barra

; ----------------------------------------------------------------------
; PINTAR LOS PANES QUE HAY EN LA CINTA. Uno por cada punto de progreso, colocados a partir de 0xE280: la posicion sale de rotar el indice dos veces, quedarse con 0x70 y restarlo de 0x80 -o sea, se colocan de derecha a izquierda-. Solo se pintan los que caigan dentro de la ventana de 0x20.
; ----------------------------------------------------------------------
pinta_los_panes_en_la_cinta:
	ld hl,0e055h		;5051
	ld a,(hl)			;5054
	cp 036h		;5055   ; por debajo de 0x36 no se pinta
	ret c			;5057
	ld a,(0e060h)		;5058   ; el progreso
L_505B:
	ld b,a			;505b
	dec a			;505c
	ret m			;505d
L_505E:
	ld a,b			;505e
	dec a			;505f
	ld c,a			;5060
	rlca			;5061   ; dos rotaciones
	rlca			;5062
	and 070h		;5063
	add a,a			;5065
	ld e,a			;5066
	ld a,080h		;5067
	sub e			;5069   ; restado de 0x80: de derecha a izquierda
	ld e,a			;506a
	ld d,0e2h		;506b
	ld a,c			;506d
	and 003h		;506e   ; dos bits del indice
	add a,055h		;5070   ; +0x55: el ajuste fino
	sub (hl)			;5072
	jp m,L_507F		;5073
	cp 020h		;5076
	jr nc,L_507F		;5078
	add a,e			;507a
	ld e,a			;507b
	ld a,07dh		;507c   ; el patron del pan
	ld (de),a			;507e
L_507F:
	djnz L_505E		;507f
	ret			;5081
pinta_los_panes_del_otro_lado:
	ld c,062h		;5082   ; la otra base
	ld b,00ch		;5084   ; y doce
	jr L_505B		;5086

; ----------------------------------------------------------------------
; EL GATO, atendido cuando el compas de ocho vale 2. Su plazo de espera depende de la fase: 0x3C menos el doble del numero de fase, con un suelo de 0x28. O sea que cuanto mas avanzada la partida, antes vuelve.
; ----------------------------------------------------------------------
mueve_el_gato:
	ld a,(0e00bh)		;5088   ; el compas de ocho
	cp 002h		;508b   ; solo cuando vale 2
	ret nz			;508d
	ld hl,0e109h		;508e
	ld a,(hl)			;5091   ; su estado
	or a			;5092
	jr nz,L_50BF		;5093
	inc hl			;5095
	dec (hl)			;5096   ; su plazo
	ret nz			;5097
	inc hl			;5098
	ld a,(hl)			;5099
	add a,a			;509a   ; el bicho al que va, por tres
	add a,(hl)			;509b
	ex de,hl			;509c
	ld hl,0e062h		;509d
	call suma_a_a_hl		;50a0
	ld (0e126h),hl		;50a3   ; apuntado
	bit 7,(hl)		;50a6   ; el bit 7: ya esta en marcha
	ex de,hl			;50a8
	jr nz,L_5100		;50a9
	inc (hl)			;50ab
	res 3,(hl)		;50ac
	dec hl			;50ae
	ld a,(0e051h)		;50af   ; el numero de fase
	add a,a			;50b2   ; por dos
	ld c,a			;50b3
	ld a,03ch		;50b4   ; 0x3C menos eso
	sub c			;50b6
	cp 028h		;50b7   ; con suelo en 0x28
	jr nc,L_50BD		;50b9
	ld a,028h		;50bb
L_50BD:
	ld (hl),a			;50bd
	dec hl			;50be
L_50BF:
	inc (hl)			;50bf
	res 2,(hl)		;50c0
	ex de,hl			;50c2
	ld hl,0e055h		;50c3
	ld a,004h		;50c6
	sub (hl)			;50c8
	ex de,hl			;50c9
	jr c,L_50EE		;50ca
	add a,0e0h		;50cc
	ld e,a			;50ce
	add a,020h		;50cf
	ld c,a			;50d1
	ld a,(hl)			;50d2
	add a,a			;50d3   ; el paso por tres
	add a,(hl)			;50d4
	ld hl,05103h		;50d5   ; la tabla de patrones del gato
	call suma_a_a_hl		;50d8
	ld d,039h		;50db   ; la fila 0x39
	ld a,(hl)			;50dd
	call escribe_en_vram		;50de   ; el primer patron, a la VRAM
	ld d,0e1h		;50e1
	ld (de),a			;50e3   ; y a la copia en RAM
	ld d,039h		;50e4
	ld b,002h		;50e6   ; dos celdas mas
	ld e,c			;50e8
	inc d			;50e9
	inc hl			;50ea
	call vuelca_y_guarda_copia		;50eb   ; a la VRAM y a la copia a la vez
L_50EE:
	ld a,(0e109h)		;50ee
	or a			;50f1
	ret nz			;50f2
	ld hl,(0e126h)		;50f3
	dec hl			;50f6
	ld (hl),004h		;50f7   ; los tres bytes de su ficha
	inc hl			;50f9
	ld (hl),080h		;50fa
	inc hl			;50fc
	ld (hl),004h		;50fd
	ret			;50ff
L_5100:
	dec hl			;5100
	inc (hl)			;5101
	ret			;5102

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5103..0x5117  (20 bytes)
DATA_5103:
	defb 0a0h,05ah,05bh,0b5h,0b7h,000h,0b5h,0b6h,000h,0b5h,0b8h,05bh,003h,007h,00bh,007h	; 5103  .Z[........[....
	defb 00fh,007h,010h,004h	; 5113

; ======================================================================
; CODIGO 0x5117..0x5138  (33 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS TRES CARROS de 0xE098, cada uno con su estado en 0xE110 y ocho bytes de separacion. El estado se recorta con `and 03eh` -cinco bits, sin el 0 ni el 6- y eso indexa la tabla de despacho de 0x5138 por la puerta de 0x4098: el mismo despachador de escenas, reutilizado para las piezas del decorado.
; ----------------------------------------------------------------------
mueve_los_tres_carros:
	ld hl,0e098h		;5117   ; el primer carro
	ld de,0e110h		;511a   ; y su estado
	ld b,003h		;511d   ; tres
L_511F:
	push bc			;511f
	push hl			;5120
	push de			;5121
	ld a,(de)			;5122
	and 03eh		;5123   ; cinco bits del estado
	exx			;5125
	ld hl,05138h		;5126   ; la tabla de despacho de los carros
	call L_4098		;5129   ; y se salta al que toque
	pop de			;512c
	pop hl			;512d
	pop bc			;512e
	ld a,l			;512f
	add a,008h		;5130   ; ocho bytes por carro
	ld l,a			;5132
	inc de			;5133   ; y dos de estado
	inc de			;5134
	djnz L_511F		;5135
	ret			;5137

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5138..0x51d1  (153 bytes)
DATA_5138:
	defb 04ch,051h,0cah,051h,0d9h,051h,00eh,052h,017h,052h,05fh,052h,085h,052h,0ddh,052h	; 5138  LQ.Q.Q.R.R_R.R.R
	defb 0f0h,052h,08ch,053h,0d9h,0edh,04bh,079h,0e0h,078h,0feh,007h,020h,004h,079h,0feh	; 5148  .R.S..Ky.x.. .y.
	defb 040h,0d0h,0ebh,023h,035h,0c0h,02bh,07dh,0feh,010h,028h,018h,0d9h,05fh,0eeh,006h	; 5158  @..#5.+}..(.._..
	defb 06fh,026h,0e1h,03ah,051h,0e0h,0feh,004h,030h,008h,07eh,06bh,023h,036h,002h,0cbh	; 5168  o&.:Q...0.~k#6..
	defb 07fh,0c0h,07bh,0d9h,0d6h,010h,0cbh,03fh,0c6h,016h,04fh,006h,0e1h,00ah,007h,0e6h	; 5178  ..{....?..O.....
	defb 001h,0eeh,001h,0c6h,084h,077h,008h,07bh,0d6h,098h,021h,0b2h,051h,0cdh,052h,040h	; 5188  .....w.{..!.Q.R@
	defb 001h,008h,000h,0edh,0b0h,07bh,0d6h,007h,05fh,0ebh,008h,01fh,03eh,001h,00eh,0b4h	; 5198  .....{.._...>...
	defb 0dah,0ffh,051h,03eh,0eeh,00eh,078h,0c3h,0ffh,051h,09fh,000h,000h,00eh,09fh,000h	; 51a8  ..Q>..x..Q......
	defb 000h,00eh,047h,000h,000h,00ah,047h,000h,000h,00ah,047h,000h,000h,008h,047h,000h	; 51b8  ..G...G...G...G.
	defb 000h,008h,0d9h,0ebh,023h,035h,0c0h,00eh,004h	; 51c8  ....#5...

; ======================================================================
; CODIGO 0x51d1..0x51d9  (8 bytes)
; ======================================================================


marca_el_estado_del_carro:
	dec hl			;51d1
L_51D2:
	ld a,(hl)			;51d2
	and 0c1h		;51d3   ; se dejan los bits 0, 6 y 7
	or c			;51d5   ; y se mete el estado nuevo
	ld (hl),a			;51d6
	xor a			;51d7
	ret			;51d8

; ----------------------------------------------------------------------
; DATOS sin identificar  0x51d9..0x52ce  (245 bytes)
DATA_51D9:
	defb 0d9h,023h,07eh,0ebh,0cbh,046h,006h,001h,020h,002h,006h,0ffh,03ah,003h,0e0h,04fh	; 51d9  .#~..F.. ...:..O
	defb 017h,0e6h,00ch,0f6h,004h,0a1h,04fh,0e6h,007h,081h,0c6h,078h,0cbh,078h,020h,002h	; 51e9  ......O....x.x .
	defb 0c6h,03ch,04fh,0ebh,07eh,080h,077h,023h,071h,023h,023h,023h,0c6h,010h,077h,023h	; 51f9  .<O.~.w#q###..w#
	defb 079h,0c6h,004h,077h,0c9h,0cdh,0cah,051h,0c0h,07eh,0eeh,001h,077h,0c9h,0cdh,0cah	; 5209  y..w...Q.~..w...
	defb 051h,028h,012h,07eh,021h,041h,052h,0cdh,052h,040h,0ebh,01ah,086h,077h,04fh,07dh	; 5219  Q(.~!AR.R@...wO}
	defb 0c6h,004h,06fh,071h,0c9h,03ah,051h,0e0h,0feh,008h,0d0h,0feh,003h,038h,005h,03ah	; 5229  ..oq.:Q......8.:
	defb 060h,0e0h,00fh,0d8h,07eh,0eeh,001h,077h,0c9h,000h,003h,003h,002h,002h,002h,001h	; 5239  `...~..w........
	defb 001h,001h,001h,001h,001h,001h,001h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 5249  ................
	defb 0ffh,0feh,0feh,0feh,0fdh,0fdh,0cdh,0cah,051h,028h,01eh,02bh,03eh,002h,001h,0d4h	; 5259  ........Q(.+>...
	defb 008h,0cbh,046h,020h,005h,03eh,006h,001h,09ch,004h,083h,05fh,023h,07eh,0feh,030h	; 5269  ..F .>....._#~.0
	defb 0d0h,079h,0cbh,056h,028h,001h,080h,012h,0c9h,0cbh,0b6h,0c9h,0d9h,03ah,00bh,0e0h	; 5279  .y.V(........:..
	defb 0feh,007h,0c0h,0cdh,0cbh,051h,0c8h,07eh,03dh,028h,036h,0ebh,01ah,05fh,001h,0a8h	; 5289  .....Q.~=(6.._..
	defb 0a4h,03eh,0feh,0cbh,043h,028h,005h,001h,0e4h,0e0h,03eh,000h,023h,086h,077h,057h	; 5299  .>..C(....>.#.wW
	defb 02bh,07eh,0d6h,010h,023h,023h,070h,023h,023h,077h,023h,072h,023h,071h,07bh,0feh	; 52a9  +~..##p##w#r#q{.
	defb 002h,0c0h,021h,058h,0e0h,07eh,02bh,077h,0cdh,097h,058h,03eh,007h,0cdh,09ch,079h	; 52b9  ..!X.~+w..X>...y
	defb 0c9h,001h,094h,090h,0ebh	; 52c9

; ======================================================================
; CODIGO 0x52ce..0x52dd  (15 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; PONER EL SEGUNDO SPRITE DE UN CARRO, dieciseis pixeles mas alla: se copian la fila, la columna corrida y el color al hueco siguiente. Un carro son dos sprites.
; ----------------------------------------------------------------------
L_52CE:
	ld d,(hl)			;52ce
	inc hl			;52cf
	ld a,(hl)			;52d0
	add a,010h		;52d1   ; dieciseis pixeles mas alla
	inc hl			;52d3
	ld (hl),b			;52d4   ; el color
	inc hl			;52d5
	inc hl			;52d6
	ld (hl),d			;52d7   ; la fila
	inc hl			;52d8
	ld (hl),a			;52d9   ; la columna corrida
	inc hl			;52da
	ld (hl),c			;52db
	ret			;52dc

; ----------------------------------------------------------------------
; DATOS sin identificar  0x52dd..0x534f  (114 bytes)
DATA_52DD:
	defb 0d9h,01ah,00eh,0f8h,01fh,030h,002h,00eh,008h,023h,079h,086h,077h,0c6h,010h,032h	; 52dd  .....0...#y.w..2
	defb 09dh,0e0h,0c9h,0d9h,03ah,00bh,0e0h,0feh,007h,0c0h,013h,0ebh,035h,0ebh,0cah,06dh	; 52ed  ....:.......5..m
	defb 053h,07dh,0c6h,006h,06fh,0cdh,0cfh,056h,0e6h,03fh,020h,00fh,0e5h,02dh,03eh,008h	; 52fd  S}..o..V.? ..->.
	defb 086h,077h,07dh,0d6h,004h,06fh,03eh,008h,086h,077h,0e1h,021h,063h,0e0h,006h,008h	; 530d  .w}..o>..w.!c...
	defb 03ah,029h,0e1h,0beh,028h,006h,023h,023h,023h,010h,0f8h,0c9h,0ebh,021h,02ah,0e1h	; 531d  :)..(.###....!*.
	defb 01ah,036h,060h,023h,077h,01bh,01ah,0e6h,007h,03ch,0cbh,03fh,087h,04fh,087h,081h	; 532d  .6`#w....<.?.O..
	defb 021h,010h,040h,0cdh,052h,040h,023h,022h,02ch,0e1h,0afh,012h,013h,012h,01bh,01bh	; 533d  !.@.R@#",.......
	defb 012h,0c9h	; 534d

; ======================================================================
; CODIGO 0x534f..0x538c  (61 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; BUSCAR EL CARRO QUE ESTE EN EL ESTADO 0x10, entre los dos de 0xE0A1 y 0xE0A9. Si su fila esta fuera de la banda 0x30..0xE0 se le clava el patron 0x47.
; ----------------------------------------------------------------------
busca_el_carro_en_el_estado_10:
	ld hl,0e0a1h		;534f
	ld de,0e112h		;5352
	ld b,002h		;5355   ; dos carros
L_5357:
	ld a,(de)			;5357
	and 03eh		;5358   ; cinco bits del estado
	cp 010h		;535a   ; el estado 0x10
	jr z,L_5366		;535c
	inc de			;535e
	inc de			;535f
	ld hl,0e0a9h		;5360   ; el otro carro
	djnz L_5357		;5363
	ret			;5365
L_5366:
	ld a,(hl)			;5366
	sub 030h		;5367   ; la banda util empieza en 0x30
	cp 0b0h		;5369   ; y mide 0xB0
	ret c			;536b
	dec hl			;536c
	ld (hl),047h		;536d   ; el patron de fuera de sitio
	inc hl			;536f
	ld a,(hl)			;5370
	sub 004h		;5371
	ld (hl),a			;5373
	add a,010h		;5374
	ld c,a			;5376
	call L_53F2		;5377
	ld a,(de)			;537a
	and 0feh		;537b
	ld (de),a			;537d
	inc hl			;537e
	inc hl			;537f
	inc hl			;5380
	ld (hl),047h		;5381
	inc hl			;5383
	ld (hl),c			;5384
	dec hl			;5385
	dec hl			;5386
	dec hl			;5387
	call L_54CB		;5388
	ret			;538b

; ----------------------------------------------------------------------
; DATOS sin identificar  0x538c..0x53b6  (42 bytes)
DATA_538C:
	defb 0d9h,03ah,00bh,0e0h,0e6h,003h,0c0h,013h,0ebh,035h,0ebh,028h,031h,01ah,0d9h,021h	; 538c  .:.......5.(1..!
	defb 0cdh,053h,0cdh,052h,040h,07eh,0d9h,04fh,077h,023h,046h,01ah,0feh,002h,028h,00ah	; 539c  .S.R@~.Ow#F...(.
	defb 038h,00dh,023h,023h,023h,079h,0c6h,010h,077h,0c9h	; 53ac  8.###y..w.

; ======================================================================
; CODIGO 0x53b6..0x53ca  (20 bytes)
; ======================================================================


L_53B6:
	ld a,b			;53b6
	sub 010h		;53b7
	ld b,a			;53b9
	ld (hl),a			;53ba
	inc hl			;53bb
	ld (hl),098h		;53bc
	inc hl			;53be
	inc hl			;53bf
	ld (hl),c			;53c0
	inc hl			;53c1
	ld a,b			;53c2
	add a,010h		;53c3
	ld (hl),a			;53c5
	inc hl			;53c6
	ld (hl),09ch		;53c7
	ret			;53c9

; ----------------------------------------------------------------------
; DATOS sin identificar  0x53ca..0x53d4  (10 bytes)
DATA_53CA:
	defb 01bh,0c3h,0a4h,055h,047h,034h,038h,040h,04ah,056h	; 53ca  ...UG48@JV

; ======================================================================
; CODIGO 0x53d4..0x572d  (857 bytes)
; ======================================================================


L_53D4:
	ld de,0e112h		;53d4
	ld hl,0e0a0h		;53d7
L_53DA:
	ld a,(de)			;53da
	and 03eh		;53db
	cp 012h		;53dd
	jr nz,L_53EA		;53df
	ld c,047h		;53e1
	ld (hl),c			;53e3
	inc hl			;53e4
	ld b,(hl)			;53e5
	call L_53B6		;53e6
	ret			;53e9
L_53EA:
	inc de			;53ea
	inc de			;53eb
	ld hl,0e0a8h		;53ec
	djnz L_53DA		;53ef
	ret			;53f1
L_53F2:
	ld a,l			;53f2
	sub 098h		;53f3
	rrca			;53f5
	rrca			;53f6
	and 00eh		;53f7
	add a,010h		;53f9
	ld e,a			;53fb
	ld d,0e1h		;53fc
	ret			;53fe
L_53FF:
	ld a,(0e056h)		;53ff
	or a			;5402
	ret nz			;5403
	ld a,(0e102h)		;5404
	or a			;5407
	ret z			;5408
	ld hl,0e099h		;5409
	ld de,0e110h		;540c
	ld b,003h		;540f
L_5411:
	ld a,(de)			;5411
	bit 7,a		;5412
	jr z,L_543D		;5414
	and 03eh		;5416
	ld c,001h		;5418
	cp 004h		;541a
	jr z,L_5427		;541c
	ld a,(0e00bh)		;541e
	cp 007h		;5421
	jr nz,L_543D		;5423
	ld c,008h		;5425
L_5427:
	ld a,(0e102h)		;5427
	cp 008h		;542a
	ld a,c			;542c
	jr nz,L_5431		;542d
	neg		;542f
L_5431:
	push hl			;5431
	ld c,a			;5432
	add a,(hl)			;5433
	ld (hl),a			;5434
	ld a,l			;5435
	add a,004h		;5436
	ld l,a			;5438
	ld a,(hl)			;5439
	add a,c			;543a
	ld (hl),a			;543b
	pop hl			;543c
L_543D:
	inc de			;543d
	inc de			;543e
	ld a,l			;543f
	add a,008h		;5440
	ld l,a			;5442
	djnz L_5411		;5443
	ret			;5445

; ----------------------------------------------------------------------
; GUARDAR LA COLUMNA DE LOS TRES CARROS ACTIVOS -los que tengan el bit 7- en 0xE116, para poder consultarla sin recorrer sus fichas. Tres punteros a la vez: DE por los sprites, BC por la copia y HL por los estados.
; ----------------------------------------------------------------------
guarda_la_columna_de_los_carros:
	ld de,0e099h		;5446
	ld bc,0e116h		;5449
	ld hl,0e110h		;544c
	ld a,003h		;544f
L_5451:
	ex af,af'			;5451
	bit 7,(hl)		;5452   ; el bit 7: esta activo
	jr z,L_5458		;5454
	ld a,(de)			;5456
	ld (bc),a			;5457
L_5458:
	ld a,e			;5458
	add a,008h		;5459   ; ocho bytes por carro
	ld e,a			;545b
	inc bc			;545c
	inc hl			;545d   ; y dos de estado
	inc hl			;545e
	ex af,af'			;545f
	dec a			;5460
	jr nz,L_5451		;5461
	ret			;5463

; ----------------------------------------------------------------------
; RETIRAR EL CARRO QUE SE SALE: si al sumarle 0x10 a su columna desborda, se le ponen a sus DOS sprites la fila 0xE0 -fuera de la pantalla- y su estado pasa a (0x00, 0x80).
; ----------------------------------------------------------------------
retira_el_carro_que_se_sale:
	ld de,0e110h		;5464
	ld hl,0e099h		;5467
	ld b,003h		;546a
L_546C:
	ld a,(de)			;546c
	bit 7,a		;546d   ; el bit 7: esta activo
	jr z,L_5489		;546f
	ld a,(hl)			;5471
	add a,010h		;5472   ; dieciseis mas
	jr nc,L_5489		;5474   ; si no desborda, sigue dentro
	push hl			;5476
	dec hl			;5477
	ld (hl),0e0h		;5478   ; 0xE0: fuera de la pantalla
	ld a,l			;547a
	add a,004h		;547b   ; y el segundo sprite, cuatro bytes mas alla
	ld l,a			;547d
	ld (hl),0e0h		;547e
	ex de,hl			;5480
	ld (hl),000h		;5481
	inc hl			;5483
	ld (hl),080h		;5484   ; su estado nuevo
	dec hl			;5486
	ex de,hl			;5487
	pop hl			;5488
L_5489:
	ld a,l			;5489
	add a,008h		;548a   ; ocho bytes por carro
	ld l,a			;548c
	inc de			;548d
	inc de			;548e
	djnz L_546C		;548f
	ret			;5491

; ----------------------------------------------------------------------
; UNA COMPROBACION CURIOSA: de la fase 2 en adelante y solo en las impares, mira si la VOZ de 0xE010 esta en uno y si el byte al que apunta su partitura es 0xC3. O sea, el juego cambia el estado de los carros mirando POR DONDE VA LA MUSICA: lo que pasa en pantalla va a compas con lo que suena.
; ----------------------------------------------------------------------
mira_si_el_sonido_va_por_c3:
	ld a,(0e051h)		;5492   ; el numero de fase
	cp 002h		;5495   ; de la segunda en adelante
	ret c			;5497
	rra			;5498   ; y solo las impares
	ret nc			;5499
	ld a,(0e010h)		;549a   ; la voz de 0xE010
	dec a			;549d
	ret nz			;549e
	ld hl,(0e013h)		;549f   ; por donde va su partitura
	inc hl			;54a2
	ld a,(hl)			;54a3
	cp 0c3h		;54a4   ; el byte 0xC3 es la marca
	ret nz			;54a6
	ld hl,0e09ah		;54a7
	ld de,0e110h		;54aa
	ld b,003h		;54ad   ; tres carros
L_54AF:
	push bc			;54af
	push de			;54b0
	push hl			;54b1
	call arranca_un_carro		;54b2
	jr nz,L_54B9		;54b5
	ld (hl),020h		;54b7   ; y se les pone el estado 0x20
L_54B9:
	pop hl			;54b9
	ld a,l			;54ba
	add a,008h		;54bb
	ld l,a			;54bd
	pop de			;54be
	inc de			;54bf
	inc de			;54c0
	pop bc			;54c1
	djnz L_54AF		;54c2
	ret			;54c4
arranca_un_carro:
	ld a,(de)			;54c5
	and 03eh		;54c6   ; cinco bits del estado
	cp 004h		;54c8   ; el estado 4
	ret nz			;54ca
L_54CB:
	ex de,hl			;54cb
	ld c,002h		;54cc   ; el estado nuevo, 2
	call L_51D2		;54ce
	ex de,hl			;54d1
L_54D2:
	ld a,(de)			;54d2
	ld bc,09094h		;54d3   ; una pareja de patrones
	rra			;54d6
	jr nc,L_54DC		;54d7
	ld bc,0ccd0h		;54d9   ; o la otra
L_54DC:
	ld (hl),b			;54dc
	ld a,l			;54dd
	add a,004h		;54de   ; cuatro bytes: el segundo sprite
	ld l,a			;54e0
	ld (hl),c			;54e1
	ex de,hl			;54e2
	inc hl			;54e3
	ld (hl),012h		;54e4   ; y el plazo, a 18
	xor a			;54e6
	ret			;54e7

; ----------------------------------------------------------------------
; ARRANCAR UN CARRO SEGUN EL CONTADOR DE CUADROS, y aqui el reparto es por VALOR EXACTO: el carro 1 sale cuando el contador esta a cero, el 2 cuando vale 0x80 y el 3 cuando vale 0x40. O sea, uno cada 128 cuadros, escalonados.
; ----------------------------------------------------------------------
arranca_un_carro_por_el_reloj:
	ld a,(0e104h)		;54e8   ; el estado del salto
	or a			;54eb
	ret nz			;54ec
	ld a,(0e102h)		;54ed   ; la direccion guardada
	or a			;54f0
	ret z			;54f1
	ld de,0e09ah		;54f2
	ld hl,0e110h		;54f5
	ld a,(0e003h)		;54f8   ; el contador de cuadros
	or a			;54fb   ; el valor cero: el primer carro
	jr z,L_550F		;54fc
	inc hl			;54fe
	inc hl			;54ff
	ld de,0e0a2h		;5500
	cp 080h		;5503   ; el 0x80: el segundo
	jr z,L_550F		;5505
	inc hl			;5507
	inc hl			;5508
	ld de,0e0aah		;5509
	cp 040h		;550c   ; y el 0x40: el tercero
	ret nz			;550e
L_550F:
	bit 7,(hl)		;550f   ; el bit 7: esta activo
	ret z			;5511
	ld a,(hl)			;5512
	and 03eh		;5513   ; cinco bits del estado
	cp 004h		;5515   ; el estado 4
	ret nz			;5517
L_5518:
	ld c,006h		;5518   ; y pasa al 6
	call L_51D2		;551a
	ex de,hl			;551d
	jr L_54D2		;551e

; ----------------------------------------------------------------------
; EL DISPARO CONTRA UN CARRO, de la fase 2 en adelante. La caja no se compara con dos `cp`: se RESTA el margen dos veces -0x10 y luego 0x18- y basta con mirar el acarreo, que es mas corto. Si acierta, el carro pasa al estado 8 con un plazo de 30.
; ----------------------------------------------------------------------
mira_el_disparo_contra_el_carro:
	ld a,(0e051h)		;5520   ; el numero de fase
	cp 002h		;5523   ; de la segunda en adelante
	ret c			;5525
	ld hl,0e121h		;5526   ; la recarga
	ld a,(hl)			;5529
	or a			;552a
	ret z			;552b
	inc hl			;552c
	inc hl			;552d
	ld a,(hl)			;552e
	or a			;552f
	ret z			;5530
	ld hl,0e110h		;5531
	xor (hl)			;5534   ; cruzado con el estado del carro
	rra			;5535
	ret c			;5536
	ld a,(hl)			;5537
	and 03eh		;5538   ; cinco bits del estado
	cp 004h		;553a   ; el estado 4
	ret nz			;553c
	ld a,(0e091h)		;553d   ; la columna del disparo
	ld c,a			;5540
	ex de,hl			;5541
	ld hl,0e099h		;5542
	xor (hl)			;5545
	ex de,hl			;5546
	rla			;5547
	jr z,L_5550		;5548
	ld a,(de)			;554a
	sub 040h		;554b   ; sesenta y cuatro de margen
	cp 080h		;554d
	ret nc			;554f
L_5550:
	ld a,(de)			;5550
	add a,008h		;5551   ; ocho de desplazamiento
	bit 0,(hl)		;5553   ; el bit 0: por que lado se compara
	jr z,L_555A		;5555
	ld b,a			;5557
	ld a,c			;5558
	ld c,b			;5559
L_555A:
	sub c			;555a
	sub 010h		;555b   ; dieciseis
	sub 018h		;555d   ; y veinticuatro mas: la caja, en dos restas
	ret nc			;555f
	ld c,008h		;5560   ; el estado nuevo, 8
	call L_51D2		;5562
	ex de,hl			;5565
	inc hl			;5566
	call L_54D2		;5567
	ld (hl),01eh		;556a   ; y treinta cuadros de plazo
	ret			;556c

; ----------------------------------------------------------------------
; EL CARRO ALCANZADO: su estado 0x10 da 300 puntos y los demas 200 o 300 segun el valor, con el sonido 3. Y la espera que se le pone despues DEPENDE DE LA FASE: el numero de fase -con tope en 6- se rota cuatro veces y se niega, o sea que en las fases altas el carro vuelve mucho antes.
; ----------------------------------------------------------------------
L_556D:
	ld a,(de)			;556d
	and 03eh		;556e
	cp 010h		;5570
	jr z,el_carro_del_estado_10		;5572
	ld a,(de)			;5574
	ld bc,0989ch		;5575   ; una pareja de patrones
	rra			;5578
	jr nc,L_557E		;5579
	ld bc,0d4d8h		;557b   ; o la otra
L_557E:
	push de			;557e
	ld e,(hl)			;557f
	inc hl			;5580
	ld a,(hl)			;5581
	add a,010h		;5582   ; dieciseis pixeles mas alla: el segundo sprite
	inc hl			;5584
	ld (hl),b			;5585
	inc hl			;5586
	inc hl			;5587
	ld (hl),e			;5588
	inc hl			;5589
	ld (hl),a			;558a
	inc hl			;558b
	ld (hl),c			;558c
	pop de			;558d
	ld a,e			;558e
	push de			;558f
	push hl			;5590
	ld de,00200h		;5591   ; doscientos puntos
	cp 010h		;5594   ; y el estado 0x10 da trescientos
	jr z,L_559A		;5596
	ld d,003h		;5598
L_559A:
	call suma_puntos		;559a
	ld a,003h		;559d   ; el sonido del acierto
	call L_799C		;559f
	pop hl			;55a2
	pop de			;55a3
	ld a,(0e002h)		;55a4
	bit 6,a		;55a7   ; el bit 6: estamos en partida
	ld a,000h		;55a9
	jr z,L_55BD		;55ab
	ld a,(0e051h)		;55ad   ; el numero de fase
	cp 007h		;55b0   ; con tope en seis
	jr c,L_55B6		;55b2
	ld a,006h		;55b4
L_55B6:
	dec a			;55b6
	rlca			;55b7   ; cuatro rotaciones
	rlca			;55b8
	rlca			;55b9
	rlca			;55ba
	neg		;55bb   ; y en negativo: la espera
L_55BD:
	ex de,hl			;55bd
	set 6,(hl)		;55be   ; se marca el bit 6
	inc hl			;55c0
	ld (hl),a			;55c1
	ld c,00ah		;55c2   ; y el estado nuevo, 10
	call marca_el_estado_del_carro		;55c4
	ret			;55c7
el_carro_del_estado_10:
	ld a,(de)			;55c8
	and 0c0h		;55c9   ; se dejan los dos bits de arriba
	or 012h		;55cb   ; y el estado 0x12
	ld (de),a			;55cd
	inc de			;55ce
	ld a,007h		;55cf
	ld (de),a			;55d1
	ld de,00300h		;55d2   ; trescientos puntos
	call suma_puntos		;55d5
	ld a,003h		;55d8   ; y el sonido
	call L_799C		;55da
	ret			;55dd

; ----------------------------------------------------------------------
; EL CARRO CONTRA LA CINTA. La columna del carro se rota tres veces -o sea, se divide entre ocho- y con 0x3E de desplazamiento indexa el bufer de 0xE2xx: si ahi hay un 0xB0, es que en esa celda hay algo. Otra vez el juego consultando lo que HAY DIBUJADO en vez de un mapa aparte.
; ----------------------------------------------------------------------
mira_el_carro_contra_la_cinta:
	ld a,(0e05bh)		;55de   ; la bandera de 0xE05B
	or a			;55e1
	ret nz			;55e2
	ld hl,0e110h		;55e3
	ld de,0e099h		;55e6
	ld a,(de)			;55e9
	and 007h		;55ea   ; tres bits
	cp 004h		;55ec   ; por debajo de cuatro
	ret nc			;55ee
	ld a,(hl)			;55ef
	bit 0,a		;55f0   ; el bit 0 del estado
	ret nz			;55f2
	and 03eh		;55f3   ; cinco bits
	cp 004h		;55f5   ; el estado 4
	ret nz			;55f7
	ld a,(de)			;55f8
	rrca			;55f9   ; tres rotaciones: la celda
	rrca			;55fa
	rrca			;55fb
	and 01fh		;55fc
	add a,03eh		;55fe   ; +0x3E: el sitio en el bufer
	ld c,a			;5600
	ld b,0e2h		;5601
	ld a,(bc)			;5603
	cp 0b0h		;5604   ; el patron 0xB0 es lo que se busca
	ret nz			;5606
	ld a,(0e055h)		;5607   ; la posicion del decorado
	add a,c			;560a
	add a,0c5h		;560b   ; mas el ajuste
	and 070h		;560d   ; cuatro bits
	exx			;560f
	ld hl,0e057h		;5610
	cpl			;5613   ; invertido y cruzado con el mapa de ocupacion
	and (hl)			;5614
	ld (0e058h),a		;5615   ; guardado en 0xE058
	exx			;5618
	ex de,hl			;5619
	inc hl			;561a
	call L_54D2		;561b
	ld (hl),006h		;561e   ; el plazo, a seis
	ld c,00ch		;5620   ; y el estado nuevo, 12
	jp marca_el_estado_del_carro		;5622

; ----------------------------------------------------------------------
; EL CARRO QUE LLEGA AL FINAL: pasa al estado 14, deja el bit 0 puesto o no segun la direccion del panadero, y da 120 puntos con el sonido 3.
; ----------------------------------------------------------------------
el_carro_llega_al_final:
	ld a,(hl)			;5625
	and 03eh		;5626   ; cinco bits del estado
	ld c,00eh		;5628   ; el estado nuevo, 14
	cp c			;562a
	ret z			;562b
	call L_51D2		;562c
	ld a,(0e105h)		;562f   ; la direccion del panadero
	or a			;5632
	jr z,L_5637		;5633
	ld a,001h		;5635
L_5637:
	res 0,(hl)		;5637   ; se limpia el bit 0
	or (hl)			;5639
	ld (hl),a			;563a
	ld de,00120h		;563b   ; ciento veinte puntos
	call suma_puntos		;563e
	ld a,003h		;5641
	jp L_799C		;5643

; ----------------------------------------------------------------------
; LOS DOS CARROS CONTRA LO QUE HAY EN LA CINTA, con la misma idea de antes: la columna del carro se divide entre ocho (`srl a` tres veces), se le suma 0xC0 y eso apunta al bufer de 0xE2xx. Si ahi hay un 0x69 y las CUATRO celdas de al lado estan a cero, la cosa cuenta.
; ----------------------------------------------------------------------
mira_los_dos_carros_contra_algo:
	ld a,(0e00bh)		;5646   ; el compas de ocho
	cp 007h		;5649   ; en el paso 7 no
	ret z			;564b
	ld de,0e114h		;564c
	ld a,(de)			;564f
	and 03eh		;5650   ; cinco bits del estado
	cp 010h		;5652   ; el estado 0x10
	ret z			;5654
	dec de			;5655
	dec de			;5656
	ld a,(de)			;5657
	and 03eh		;5658
	cp 010h		;565a
	ret z			;565c
	ld b,002h		;565d   ; dos carros
	ld hl,0e0a1h		;565f
L_5662:
	push hl			;5662
	ld a,(de)			;5663
	and 03eh		;5664
	cp 004h		;5666   ; el estado 4
	jr nz,L_569B		;5668
	ld a,(hl)			;566a
	bit 2,a		;566b   ; el bit 2
	jr nz,L_569B		;566d
	sub 040h		;566f   ; sesenta y cuatro menos
	cp 088h		;5671   ; y la banda util
	jr nc,L_569B		;5673
	ld a,(de)			;5675
	rra			;5676   ; el bit 0: por que lado
	jr nc,L_567D		;5677
	ld a,l			;5679
	add a,004h		;567a   ; cuatro bytes: el segundo sprite
	ld l,a			;567c
L_567D:
	ld a,(hl)			;567d
	ld c,a			;567e
	srl a		;567f   ; tres rotaciones: la celda
	srl a		;5681
	srl a		;5683
	add a,0c0h		;5685   ; +0xC0: el sitio en el bufer
	ld l,a			;5687
	ld h,0e2h		;5688
	ld a,(hl)			;568a
	cp 069h		;568b   ; el patron 0x69 es lo que se busca
	jr nz,L_569B		;568d
	dec h			;568f
	dec l			;5690
	xor a			;5691
	or (hl)			;5692   ; y las cuatro celdas de al lado, a cero
	inc hl			;5693
	or (hl)			;5694
	inc hl			;5695
	or (hl)			;5696
	inc hl			;5697
	or (hl)			;5698
	jr z,L_56A4		;5699
L_569B:
	pop hl			;569b
	ld hl,0e0a9h		;569c   ; el segundo carro
	inc de			;569f   ; dos bytes de estado
	inc de			;56a0
	djnz L_5662		;56a1
	ret			;56a3
L_56A4:
	ld a,(de)			;56a4
	and 0c1h		;56a5
	or 010h		;56a7
	ld (de),a			;56a9
	inc de			;56aa
	ld a,(0e060h)		;56ab
	add a,010h		;56ae
	ld (de),a			;56b0
	ld a,c			;56b1
	rra			;56b2
	rra			;56b3
	rra			;56b4
	and 01fh		;56b5
	ld hl,0e055h		;56b7
	add a,(hl)			;56ba
	dec a			;56bb
	ld (0e129h),a		;56bc
	pop hl			;56bf
	dec hl			;56c0
	ld (hl),05bh		;56c1
	inc hl			;56c3
	ld (hl),c			;56c4
	inc hl			;56c5
	ld (hl),0b0h		;56c6
	inc hl			;56c8
	inc hl			;56c9
	ld (hl),06bh		;56ca
	inc hl			;56cc
	ld (hl),c			;56cd
	inc hl			;56ce
	ld a,(0e003h)		;56cf
	bit 3,a		;56d2
	ld c,0e8h		;56d4
	jr nz,L_56DA		;56d6
	ld c,0ach		;56d8
L_56DA:
	ld (hl),c			;56da
	ret			;56db
L_56DC:
	ld hl,0e098h		;56dc
	ld de,0e110h		;56df
	ld b,003h		;56e2
L_56E4:
	ld a,(de)			;56e4
	bit 7,a		;56e5
	jr z,L_5724		;56e7
	and 03eh		;56e9
	cp 00ah		;56eb
	jr z,L_5724		;56ed
	cp 008h		;56ef
	jr z,L_5724		;56f1
	cp 00eh		;56f3
	jr z,L_5724		;56f5
	cp 012h		;56f7
	jr z,L_5724		;56f9
	push bc			;56fb
	push de			;56fc
	push hl			;56fd
	ld bc,(0e090h)		;56fe
	ld e,(hl)			;5702
	inc hl			;5703
	ld d,(hl)			;5704
	ld hl,0572dh		;5705
	cp 010h		;5708
	jr nz,L_570F		;570a
	ld hl,05731h		;570c
L_570F:
	ld a,b			;570f
	xor d			;5710
	rla			;5711
	jr nc,L_571B		;5712
	ld a,b			;5714
	sub 040h		;5715
	cp 080h		;5717
	jr nc,L_571E		;5719
L_571B:
	call L_575E		;571b
L_571E:
	pop hl			;571e
	pop de			;571f
	pop bc			;5720
	jp c,L_556D		;5721
L_5724:
	ld a,l			;5724
	add a,008h		;5725
	ld l,a			;5727
	inc de			;5728
	inc de			;5729
	djnz L_56E4		;572a
	ret			;572c

; ----------------------------------------------------------------------
; DATOS sin identificar  0x572d..0x5735  (8 bytes)
DATA_572D:
	defb 008h,020h,00ah,014h,00bh,016h,000h,010h	; 572d  . ......

; ======================================================================
; CODIGO 0x5735..0x575a  (37 bytes)
; ======================================================================


L_5735:
	ld bc,(0e080h)		;5735
	ld de,(0e098h)		;5739
	ld hl,0575ah		;573d
	call L_575E		;5740
	ret nc			;5743
	ld hl,0e110h		;5744
	ld de,0e098h		;5747
	bit 6,(hl)		;574a
	jp nz,el_carro_llega_al_final		;574c
	ld hl,0e053h		;574f
	ld (hl),000h		;5752
	ld a,099h		;5754
	call L_799C		;5756
	ret			;5759

; ----------------------------------------------------------------------
; DATOS sin identificar  0x575a..0x575e  (4 bytes)
DATA_575A:
	defb 008h,020h,020h,025h	; 575a

; ======================================================================
; CODIGO 0x575e..0x57bc  (94 bytes)
; ======================================================================


L_575E:
	ld a,b			;575e
	sub d			;575f
	add a,(hl)			;5760
	inc hl			;5761
	sub (hl)			;5762
	ret nc			;5763
	ld a,c			;5764
	sub e			;5765
	inc hl			;5766
	add a,(hl)			;5767
	inc hl			;5768
	sub (hl)			;5769
	ret			;576a
L_576B:
	ld a,(0e003h)		;576b
	sub 085h		;576e
	ret nz			;5770
	ld hl,0e05bh		;5771
	or (hl)			;5774
	ret nz			;5775
	ld a,(0e110h)		;5776
	and 03eh		;5779
	cp 00ch		;577b
	ret z			;577d
	ld a,(0e051h)		;577e
	cp 005h		;5781
	ld a,(0e057h)		;5783
	ld b,a			;5786
	jr nc,L_578E		;5787
	cp 070h		;5789
	jr z,L_5791		;578b
	ret			;578d
L_578E:
	cp 030h		;578e
	ret c			;5790
L_5791:
	ld hl,0e19ah		;5791
	dec (hl)			;5794
	jr nz,L_5799		;5795
	ld (hl),017h		;5797
L_5799:
	ld a,(hl)			;5799
	ld hl,057c2h		;579a
	call suma_a_a_hl		;579d
	ld a,(hl)			;57a0
	ld hl,057bch		;57a1
	call suma_a_a_hl		;57a4
	ld c,(hl)			;57a7
	ld a,b			;57a8
	and c			;57a9
	ret z			;57aa
	inc hl			;57ab
	ld b,(hl)			;57ac
	ld (0e059h),bc		;57ad
	ld a,007h		;57b1
	ld (0e05bh),a		;57b3
	ld a,0f4h		;57b6
	ld (0e0b2h),a		;57b8
	ret			;57bb

; ----------------------------------------------------------------------
; DATOS sin identificar  0x57bc..0x57da  (30 bytes)
DATA_57BC:
	defb 010h,011h,020h,024h,040h,03dh,000h,004h,000h,004h,002h,000h,004h,002h,002h,004h	; 57bc  .. $@=..........
	defb 004h,000h,000h,004h,002h,002h,000h,002h,004h,000h,002h,004h,000h,002h	; 57cc  ..............

; ======================================================================
; CODIGO 0x57da..0x58f9  (287 bytes)
; ======================================================================


L_57DA:
	ld a,(0e00bh)		;57da
	sub 007h		;57dd
	ret nz			;57df
	ld hl,0e05bh		;57e0
	or (hl)			;57e3
	ret z			;57e4
	ex de,hl			;57e5
	ld hl,0e055h		;57e6
	dec de			;57e9
	ld a,(de)			;57ea
	inc de			;57eb
	sub (hl)			;57ec
	cp 01fh		;57ed
	ld hl,0e0b0h		;57ef
	ex de,hl			;57f2
	jr nc,L_581A		;57f3
	dec (hl)			;57f5
	ex de,hl			;57f6
	jr z,L_5821		;57f7
	ld (hl),08fh		;57f9
	inc hl			;57fb
	add a,a			;57fc
	add a,a			;57fd
	add a,a			;57fe
	ld (hl),a			;57ff
	inc hl			;5800
	ld a,(hl)			;5801
	xor 004h		;5802
	ld (hl),a			;5804
	ld a,(de)			;5805
	cp 003h		;5806
	ret nz			;5808
L_5809:
	ld hl,0e057h		;5809
	ld a,(0e059h)		;580c
	cpl			;580f
	and (hl)			;5810
	ld (hl),a			;5811
	ld a,007h		;5812
	call L_799C		;5814
	jp L_5897		;5817
L_581A:
	ld (hl),000h		;581a
	ld a,0e0h		;581c
	ld (de),a			;581e
	jr L_5809		;581f
L_5821:
	ld (hl),0e0h		;5821
	ret			;5823
L_5824:
	ld a,(0e00bh)		;5824
	cp 007h		;5827
	ret z			;5829
	ld a,(0e104h)		;582a
	or a			;582d
	ret nz			;582e
	ld a,(0e2c0h)		;582f
	cp 06ah		;5832
	ret nz			;5834
	ld a,(0e105h)		;5835
	or a			;5838
	ret nz			;5839
	ld hl,0e057h		;583a
	ld a,(0e055h)		;583d
	add a,010h		;5840
	and 070h		;5842
	ld c,a			;5844
	and (hl)			;5845
	ret nz			;5846
	ld a,c			;5847
	or (hl)			;5848
	ld (hl),a			;5849
	ld a,010h		;584a
	ld (0e124h),a		;584c
	ld hl,0e05fh		;584f
	ld a,c			;5852
	cpl			;5853
	and (hl)			;5854
	ld (hl),a			;5855
	ld a,030h		;5856
	call pinta_la_pose_del_panadero		;5858
	call L_5897		;585b
	ld hl,0e24ah		;585e
	ld de,03a4ah		;5861
	ld bc,00005h		;5864
	call vuelca_bloque		;5867
	ld l,08ah		;586a
	ld e,l			;586c
	ld bc,00005h		;586d
	call vuelca_bloque		;5870
	ld a,004h		;5873
	call L_799C		;5875
	ld de,00050h		;5878
	call suma_puntos		;587b
	ld hl,0e110h		;587e
	ld a,(hl)			;5881
	bit 0,a		;5882
	ret nz			;5884
	and 03eh		;5885
	cp 004h		;5887
	ret nz			;5889
	ld de,0e099h		;588a
	ld a,(de)			;588d
	sub 028h		;588e
	cp 050h		;5890
	ret c			;5892
	inc de			;5893
	jp L_5518		;5894
L_5897:
	ld de,058f9h		;5897
	ld hl,0e055h		;589a
	ld a,(0e057h)		;589d
	ld c,a			;58a0
	ld b,003h		;58a1
L_58A3:
	rr c		;58a3
	ld a,(de)			;58a5
	inc de			;58a6
	sub (hl)			;58a7
	cp 01fh		;58a8
	jr nc,L_58E4		;58aa
	bit 3,c		;58ac
	exx			;58ae
	ld bc,0b0adh		;58af
	ld de,00000h		;58b2
	ld hl,0a7c2h		;58b5
	jr nz,L_58C2		;58b8
	ld b,d			;58ba
	ld c,e			;58bb
	ld de,0b0adh		;58bc
	ld hl,0c2a6h		;58bf
L_58C2:
	push hl			;58c2
	ld hl,0e240h		;58c3
	add a,l			;58c6
	ld l,a			;58c7
	ld (hl),b			;58c8
	inc hl			;58c9
	ld (hl),c			;58ca
	ld a,l			;58cb
	add a,03fh		;58cc
	ld l,a			;58ce
	ld (hl),d			;58cf
	inc hl			;58d0
	ld (hl),e			;58d1
	pop de			;58d2
	ld a,l			;58d3
	sub 084h		;58d4
	jr c,L_58E0		;58d6
L_58D8:
	add a,080h		;58d8
	ld l,a			;58da
	ld (hl),e			;58db
	sub 040h		;58dc
	ld l,a			;58de
	ld (hl),d			;58df
L_58E0:
	exx			;58e0
L_58E1:
	djnz L_58A3		;58e1
	ret			;58e3
L_58E4:
	sub 003h		;58e4
	cp 020h		;58e6
	jr nc,L_58E1		;58e8
	bit 3,c		;58ea
	exx			;58ec
	ld de,0a7c2h		;58ed
	jr nz,L_58F5		;58f0
	ld de,0c2a6h		;58f2
L_58F5:
	ld h,0e2h		;58f5
	jr L_58D8		;58f7

; ----------------------------------------------------------------------
; DATOS sin identificar  0x58f9..0x58fc  (3 bytes)
DATA_58F9:
	defb 011h,024h,03dh	; 58f9

; ======================================================================
; CODIGO 0x58fc..0x5946  (74 bytes)
; ======================================================================


L_58FC:
	ld a,(0e00bh)		;58fc
	cp 007h		;58ff
	ret nz			;5901
	ld hl,0e12ah		;5902
	ld a,(hl)			;5905
	or a			;5906
	ret z			;5907
	ld a,(0e055h)		;5908
	ld c,a			;590b
	inc hl			;590c
	ld a,(hl)			;590d
	sub c			;590e
	dec hl			;590f
	add a,(hl)			;5910
	add a,060h		;5911
	cp 0a0h		;5913
	jr nc,L_5919		;5915
	add a,020h		;5917
L_5919:
	exx			;5919
	ld e,a			;591a
	ld hl,05946h		;591b
	ld c,003h		;591e
	call vuelca_las_dos_filas		;5920
	exx			;5923
	ld a,(hl)			;5924
	sub 020h		;5925
	ld (hl),a			;5927
	ret z			;5928
	inc hl			;5929
	dec (hl)			;592a
	exx			;592b
	ld hl,0594ch		;592c
	inc hl			;592f
	cp 020h		;5930
	jr z,L_593B		;5932
	ld a,e			;5934
	sub 020h		;5935
	ld e,a			;5937
	ld hl,(0e12ch)		;5938
L_593B:
	ld a,e			;593b
	sub 023h		;593c
	ld e,a			;593e
	ld c,002h		;593f
	call vuelca_las_dos_filas		;5941
	exx			;5944
	ret			;5945

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5946..0x5952  (12 bytes)
DATA_5946:
	defb 000h,000h,000h,000h,000h,000h,000h,0c8h,0c9h,000h,0cah,0cbh	; 5946  ............

; ======================================================================
; CODIGO 0x5952..0x5a50  (254 bytes)
; ======================================================================


L_5952:
	ld hl,04e63h		;5952
	call L_4E51		;5955
	ld hl,0e080h		;5958
	ld b,(hl)			;595b
	inc hl			;595c
	ld a,(0e099h)		;595d
	sub (hl)			;5960
	ld c,008h		;5961
	ld a,012h		;5963
	jr nc,L_596B		;5965
	ld c,0f8h		;5967
	ld a,092h		;5969
L_596B:
	ld (0e119h),a		;596b
	ld a,b			;596e
	call L_59B2		;596f
	push bc			;5972
	push hl			;5973
	ld a,034h		;5974
	call pinta_la_pose_del_panadero		;5976
	ld hl,0e080h		;5979
	ld de,0e090h		;597c
	ld bc,00004h		;597f
	ldir		;5982
	ld de,0e110h		;5984
	ld hl,0e09ah		;5987
	call L_54D2		;598a
	ld hl,0e098h		;598d
	call L_52CE		;5990
	pop hl			;5993
	pop bc			;5994
	ld de,0e080h		;5995
	ex de,hl			;5998
	ld a,b			;5999
	add a,018h		;599a
	ld (hl),a			;599c
	inc hl			;599d
	ld a,(de)			;599e
	add a,c			;599f
	ld (hl),a			;59a0
	inc hl			;59a1
	ld (hl),0fch		;59a2
	inc hl			;59a4
	ld (hl),00ah		;59a5
	call L_53D4		;59a7
L_59AA:
	ld bc,00040h		;59aa
	call L_707D		;59ad
	or a			;59b0
	ret			;59b1
L_59B2:
	add a,00fh		;59b2
	ld (0e084h),a		;59b4
	sub 006h		;59b7
	ld (0e088h),a		;59b9
	add a,016h		;59bc
	ld (0e08ch),a		;59be
	ret			;59c1
L_59C2:
	ld a,(0e00bh)		;59c2
	and 003h		;59c5
	ret nz			;59c7
	ld a,(0e119h)		;59c8
	and 07fh		;59cb
	call L_5A62		;59cd
	ld hl,0e119h		;59d0
	ld a,(hl)			;59d3
	and 07fh		;59d4
	cp 012h		;59d6
	jr nz,L_59E7		;59d8
	exx			;59da
	ld hl,0e090h		;59db
	ld de,0e080h		;59de
	ld bc,00004h		;59e1
	ldir		;59e4
	exx			;59e6
L_59E7:
	dec a			;59e7
	ld b,a			;59e8
	cp 0ffh		;59e9
	jp z,L_5A33		;59eb
	ld a,(hl)			;59ee
	and 080h		;59ef
	add a,b			;59f1
	ld (hl),a			;59f2
	ex de,hl			;59f3
	ld hl,0e081h		;59f4
	cpl			;59f7
	rlca			;59f8
	and 001h		;59f9
	ld c,a			;59fb
	call L_4BFB		;59fc
	dec hl			;59ff
	ld a,b			;5a00
	cp 00bh		;5a01
	jr z,L_5A1F		;5a03
	ex de,hl			;5a05
	cp 011h		;5a06
	jr nz,L_5A0F		;5a08
	ld hl,0e090h		;5a0a
	ld (hl),0e0h		;5a0d
L_5A0F:
	ld hl,05a50h		;5a0f
	call suma_a_a_hl		;5a12
	ex de,hl			;5a15
	ld a,(de)			;5a16
	add a,(hl)			;5a17
	ld (hl),a			;5a18
	call L_59B2		;5a19
	jp L_59AA		;5a1c
L_5A1F:
	ld (hl),089h		;5a1f
	ld a,098h		;5a21
	ld (0e084h),a		;5a23
	ld a,092h		;5a26
	ld (0e088h),a		;5a28
	ld a,0a8h		;5a2b
	ld (0e08ch),a		;5a2d
	jp L_59AA		;5a30
L_5A33:
	ld de,0e081h		;5a33
	ld a,(hl)			;5a36
	rla			;5a37
	ld c,00ah		;5a38
	jr nc,L_5A3E		;5a3a
	ld c,0fah		;5a3c
L_5A3E:
	ld a,(de)			;5a3e
	add a,c			;5a3f
	ld h,a			;5a40
	ld l,083h		;5a41
	ld (0e090h),hl		;5a43
	ld a,0fch		;5a46
	ld (0e092h),a		;5a48
	call L_59AA		;5a4b
	scf			;5a4e
	ret			;5a4f

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5a50..0x5a62  (18 bytes)
DATA_5A50:
	defb 009h,000h,0f7h,009h,000h,0f7h,00ch,008h,000h,0fah,0f2h,000h,00dh,004h,000h,0fch	; 5a50  ................
	defb 0f6h,0eah	; 5a60

; ======================================================================
; CODIGO 0x5a62..0x5b3e  (220 bytes)
; ======================================================================


L_5A62:
	cp 001h		;5a62
	jr z,L_5A71		;5a64
	cp 004h		;5a66
	jr z,L_5A71		;5a68
	cp 007h		;5a6a
	jr z,L_5A71		;5a6c
	cp 00ch		;5a6e
	ret nz			;5a70
L_5A71:
	ld a,005h		;5a71
	jp L_799C		;5a73
L_5A76:
	call mira_si_salta		;5a76
	ld hl,0e090h		;5a79
	ld (hl),0e0h		;5a7c
	ld de,0e091h		;5a7e
	ld bc,00020h		;5a81
	ldir		;5a84
	call L_707A		;5a86
	ld a,(0e012h)		;5a89
	or a			;5a8c
	ret nz			;5a8d
	ld a,090h		;5a8e
	call L_799C		;5a90
	jp L_4381		;5a93
L_5A96:
	ld a,(0e104h)		;5a96
	or a			;5a99
	ld a,003h		;5a9a
	jr nz,L_5AA5		;5a9c
	ld a,008h		;5a9e
	ld (0e102h),a		;5aa0
	ld a,002h		;5aa3
L_5AA5:
	ld (0e056h),a		;5aa5
	ld a,(0e00bh)		;5aa8
	or a			;5aab
	jr z,L_5AB6		;5aac
	cp 004h		;5aae
	ret nz			;5ab0
	call L_4C1A		;5ab1
	jr L_5AB9		;5ab4
L_5AB6:
	call L_4C1E		;5ab6
L_5AB9:
	call mira_si_salta		;5ab9
	call mira_si_dispara		;5abc
	call L_707A		;5abf
	ld a,(0e081h)		;5ac2
	cp 0e8h		;5ac5
	jr nc,L_5ACE		;5ac7
	ld hl,0e11eh		;5ac9
	dec (hl)			;5acc
	ret nz			;5acd
L_5ACE:
	ld a,0a0h		;5ace
	ld (0e004h),a		;5ad0
	jp L_4381		;5ad3
L_5AD6:
	call baja_el_contador_y_barre		;5ad6
	ret p			;5ad9
	call L_711B		;5ada
	call L_5B5E		;5add
	call L_61C3		;5ae0
	ld a,0eeh		;5ae3
	call codigo_huerfano_4757		;5ae5
	ld hl,05ef6h		;5ae8
	call descomprime		;5aeb
	ld a,(0e07bh)		;5aee
	ld hl,0e04fh		;5af1
	ld (hl),a			;5af4
	or a			;5af5
	jr z,L_5B1A		;5af6
	ld de,03ad2h		;5af8
	ld b,001h		;5afb
	call imprime_bcd		;5afd
	inc hl			;5b00
	inc de			;5b01
	ld a,(0e060h)		;5b02
	ld b,a			;5b05
	cp 009h		;5b06
	jr c,L_5B0C		;5b08
	ld a,009h		;5b0a
L_5B0C:
	ld (0e19bh),a		;5b0c
	xor a			;5b0f
L_5B10:
	add a,006h		;5b10
	daa			;5b12
	djnz L_5B10		;5b13
	inc b			;5b15
	ld (hl),a			;5b16
	call imprime_bcd		;5b17
L_5B1A:
	ld hl,05b3eh		;5b1a
	ld de,0e080h		;5b1d
	ld bc,00020h		;5b20
	ldir		;5b23
	call L_7086		;5b25
	set 7,(hl)		;5b28
	ld hl,0e090h		;5b2a
	ld de,03b10h		;5b2d
	ld bc,00010h		;5b30
	call vuelca_bloque		;5b33
	ld a,000h		;5b36
	ld (0e11eh),a		;5b38
	jp L_4381		;5b3b

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5b3e..0x5b5e  (32 bytes)
DATA_5B3E:
	defb 077h,0dbh,048h,08fh,07fh,0dbh,050h,08fh,07eh,0dbh,04ch,089h,08fh,0dbh,054h,087h	; 5b3e  w.H...P.~.L...T.
	defb 067h,0d0h,014h,006h,06fh,0b0h,010h,006h,06fh,090h,00ch,006h,06fh,070h,008h,008h	; 5b4e  g...o...o...op..

; ======================================================================
; CODIGO 0x5b5e..0x5d26  (456 bytes)
; ======================================================================


L_5B5E:
	ld hl,07982h		;5b5e
	ld de,0e130h		;5b61
	ld c,007h		;5b64
L_5B66:
	ld b,005h		;5b66
L_5B68:
	ld a,(hl)			;5b68
	ld (de),a			;5b69
	inc hl			;5b6a
	inc de			;5b6b
	djnz L_5B68		;5b6c
	ld a,c			;5b6e
	ld bc,0000fh		;5b6f
	sbc hl,bc		;5b72
	ld c,a			;5b74
	dec c			;5b75
	jr nz,L_5B66		;5b76
	xor a			;5b78
	ld (0e14eh),a		;5b79
	ld a,(0e060h)		;5b7c
	or a			;5b7f
	ret z			;5b80
	ld b,a			;5b81
L_5B82:
	ld a,b			;5b82
	dec a			;5b83
	and 003h		;5b84
	sub 003h		;5b86
	neg		;5b88
	ld c,a			;5b8a
	add a,a			;5b8b
	add a,a			;5b8c
	add a,c			;5b8d
	ld hl,0e135h		;5b8e
	call suma_a_a_hl		;5b91
	ld a,b			;5b94
	dec a			;5b95
	rra			;5b96
	rra			;5b97
	and 003h		;5b98
	sub 003h		;5b9a
	neg		;5b9c
	call suma_a_a_hl		;5b9e
	ld (hl),07dh		;5ba1
	djnz L_5B82		;5ba3
	ret			;5ba5
L_5BA6:
	ld hl,(0e01eh)		;5ba6
	ld a,(hl)			;5ba9
	cp 0d4h		;5baa
	jp z,L_5C18		;5bac
	ld a,(0e00bh)		;5baf
	cp 004h		;5bb2
	jr z,L_5BE1		;5bb4
	or a			;5bb6
	ret nz			;5bb7
	ld hl,0e11eh		;5bb8
	ld a,(hl)			;5bbb
	cp 00ch		;5bbc
	ret nc			;5bbe
	inc (hl)			;5bbf
	ld a,(hl)			;5bc0
	ld c,a			;5bc1
	cp 009h		;5bc2
	jr c,L_5BC8		;5bc4
	ld c,008h		;5bc6
L_5BC8:
	call L_5BF0		;5bc8
	ld a,008h		;5bcb
	call corre_los_cuatro_sprites		;5bcd
	ld a,018h		;5bd0
	ld c,006h		;5bd2
L_5BD4:
	call pinta_la_pose_del_panadero		;5bd4
	ld a,(0e11eh)		;5bd7
	sub 007h		;5bda
	cp c			;5bdc
	call c,L_707A		;5bdd
	ret			;5be0
L_5BE1:
	ld a,(0e003h)		;5be1
	bit 3,a		;5be4
	ld a,01ch		;5be6
	jr z,L_5BEC		;5be8
	ld a,020h		;5bea
L_5BEC:
	ld c,005h		;5bec
	jr L_5BD4		;5bee
L_5BF0:
	ld d,039h		;5bf0
	add a,0bfh		;5bf2
	ld e,a			;5bf4
	ld hl,0e130h		;5bf5
L_5BF8:
	ld b,005h		;5bf8
	push de			;5bfa
L_5BFB:
	ld a,(hl)			;5bfb
	call escribe_en_vram		;5bfc
	inc hl			;5bff
	ld a,020h		;5c00
	call suma_a_a_de		;5c02
	djnz L_5BFB		;5c05
	pop de			;5c07
	dec de			;5c08
	dec c			;5c09
	jr nz,L_5BF8		;5c0a
	ret			;5c0c
L_5C0D:
	ld a,00ch		;5c0d
	ld (0e11eh),a		;5c0f
	call L_707A		;5c12
	jp L_4381		;5c15
L_5C18:
	call L_5C0D		;5c18
	xor a			;5c1b
	ld (0e11ch),a		;5c1c
L_5C1F:
	call L_5D3E		;5c1f
	ld hl,0e11ch		;5c22
	ld c,008h		;5c25
	ld a,(hl)			;5c27
	cp 004h		;5c28
	jr z,L_5C57		;5c2a
L_5C2C:
	inc hl			;5c2c
	inc hl			;5c2d
	ld a,(hl)			;5c2e
	or a			;5c2f
	ret z			;5c30
	ld a,c			;5c31
	ld (0e102h),a		;5c32
	ld a,003h		;5c35
	ld (0e056h),a		;5c37
	ld a,(0e00bh)		;5c3a
	or a			;5c3d
	jr z,L_5C48		;5c3e
	cp 004h		;5c40
	ret nz			;5c42
	call L_4C1A		;5c43
	jr L_5C4B		;5c46
L_5C48:
	call L_4C1E		;5c48
L_5C4B:
	ld hl,0e11eh		;5c4b
	dec (hl)			;5c4e
	ld a,018h		;5c4f
	call z,pinta_la_pose_del_panadero		;5c51
	jp L_707A		;5c54
L_5C57:
	call L_5C0D		;5c57
L_5C5A:
	call L_5D3E		;5c5a
	ld hl,0e11ch		;5c5d
	ld c,004h		;5c60
	ld a,(hl)			;5c62
	cp 008h		;5c63
	jr nz,L_5C2C		;5c65
	ld a,001h		;5c67
	ld (0e11fh),a		;5c69
	call L_5C0D		;5c6c
L_5C6F:
	call L_5D3E		;5c6f
	ld hl,0e11dh		;5c72
	ld a,(hl)			;5c75
	or a			;5c76
	ret z			;5c77
	dec hl			;5c78
	ld a,(hl)			;5c79
	cp 00fh		;5c7a
	jr z,L_5CCF		;5c7c
	cp 00ch		;5c7e
	ret nc			;5c80
	sub 008h		;5c81
	add a,a			;5c83
	add a,a			;5c84
	add a,0f0h		;5c85
	ld e,a			;5c87
	ld d,039h		;5c88
	push de			;5c8a
	ld hl,0e060h		;5c8b
	ld a,(hl)			;5c8e
	dec (hl)			;5c8f
	ld c,0fch		;5c90
	jp m,L_5CA1		;5c92
	call L_5B5E		;5c95
	ld a,00ch		;5c98
	ld c,008h		;5c9a
	call L_5BF0		;5c9c
	ld c,07eh		;5c9f
L_5CA1:
	pop de			;5ca1
	ld a,c			;5ca2
	call escribe_en_vram		;5ca3
	ld a,020h		;5ca6
	call suma_a_a_de		;5ca8
	ld a,c			;5cab
	inc a			;5cac
	call escribe_en_vram		;5cad
	ret			;5cb0
L_5CB1:
	ld hl,05fefh		;5cb1
	call descomprime		;5cb4
	ld a,(0e19bh)		;5cb7
	ld hl,05d22h		;5cba
	call suma_a_a_hl		;5cbd
	ld a,(hl)			;5cc0
	ld de,03867h		;5cc1
	call escribe_en_vram		;5cc4
	inc de			;5cc7
	inc a			;5cc8
	call escribe_en_vram		;5cc9
	jp L_4381		;5ccc
L_5CCF:
	ld a,(0e04fh)		;5ccf
	ld d,a			;5cd2
	or a			;5cd3
	jr z,L_5CDB		;5cd4
	ld e,000h		;5cd6
	call suma_puntos		;5cd8
L_5CDB:
	ld a,006h		;5cdb
	call L_799C		;5cdd
	ld a,068h		;5ce0
	ld (0e004h),a		;5ce2
	ld a,(0e060h)		;5ce5
	rla			;5ce8
	jp nc,L_5CB1		;5ce9
	call L_5D17		;5cec
	ld hl,05d2ch		;5cef
	call pinta_rotulo		;5cf2
	ld hl,05fd3h		;5cf5
	call descomprime		;5cf8
	ld hl,0e07bh		;5cfb
	ld a,004h		;5cfe
	sub (hl)			;5d00
	add a,0a0h		;5d01
	ld de,0386dh		;5d03
	call escribe_en_vram		;5d06
	ld a,050h		;5d09
	call L_4349		;5d0b
	ld hl,0010ch		;5d0e
	ld (0e000h),hl		;5d11
	jp L_4296		;5d14
L_5D17:
	ld hl,03e0eh		;5d17
	ld (0e0a0h),hl		;5d1a
	ld hl,00ffch		;5d1d
	ld (0e0a2h),hl		;5d20
	jp L_707A		;5d23

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5d26..0x5d2c  (6 bytes)
DATA_5D26:
	defb 050h,052h,052h,054h,054h,056h	; 5d26

; ----------------------------------------------------------------------
; DATOS guion_0x5D2C: 10 bytes, 2 tramos, 4 bytes a la VRAM; lo pinta 0x5CEF
;   0x5d2c..0x5d36  (10 bytes)
DATA_guion_0x5D2C:
	defb 0f9h,039h,0dch,0e6h,0e7h,0feh,01ah,03ah,0ddh,0ffh	; 5d2c  .9.....:..

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5d36..0x5d3e  (8 bytes)
DATA_5D36:
	defb 021h,004h,0e0h,035h,0c0h,0c3h,081h,043h	; 5d36  !..5...C

; ======================================================================
; CODIGO 0x5d3e..0x5d72  (52 bytes)
; ======================================================================


L_5D3E:
	ld a,(0e11dh)		;5d3e
	or a			;5d41
	ret z			;5d42
	ld b,004h		;5d43
	ld a,(0e060h)		;5d45
	bit 7,a		;5d48
	ld a,(0e11ch)		;5d4a
	jr z,L_5D54		;5d4d
	cp 00fh		;5d4f
	jr nz,L_5D54		;5d51
	dec b			;5d53
L_5D54:
	ld de,03a2eh		;5d54
	ld hl,05d72h		;5d57
	call suma_a_a_hl		;5d5a
	ld a,(hl)			;5d5d
	ld hl,05d82h		;5d5e
	call suma_a_a_hl		;5d61
L_5D64:
	push hl			;5d64
	push bc			;5d65
	ld c,0ffh		;5d66
	call L_40B4		;5d68
	pop bc			;5d6b
	inc de			;5d6c
	inc de			;5d6d
	pop hl			;5d6e
	djnz L_5D64		;5d6f
	ret			;5d71

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5d72..0x5d8e  (28 bytes)
DATA_5D72:
	defb 003h,006h,003h,006h,003h,006h,003h,006h,009h,000h,009h,000h,009h,000h,009h,000h	; 5d72  ................
	defb 0d2h,0d5h,0ffh,0d8h,0d5h,0ffh,0d2h,0d9h,0ffh,0d8h,0d9h,0ffh	; 5d82  ............

; ----------------------------------------------------------------------
; DATOS guion_0x5D8E: 29 bytes, 4 tramos, 17 bytes a la VRAM; lo pinta 0x45B3
;   0x5d8e..0x5dab  (29 bytes)
DATA_guion_0x5D8E:
	defb 00ch,038h,028h,029h,020h,0feh,016h,038h,033h,034h,021h,027h,025h,020h,0feh,02ch	; 5d8e  .8() ..834!'% .,
	defb 038h,022h,025h,021h,02dh,020h,0feh,002h,038h,011h,030h,020h,0ffh	; 5d9e  8"%!- ..8.0 .

; ----------------------------------------------------------------------
; DATOS guion_0x5DAB: 6 bytes, 1 tramos, 3 bytes a la VRAM; lo pinta 0x45C0
;   0x5dab..0x5db1  (6 bytes)
DATA_guion_0x5DAB:
	defb 022h,038h,012h,030h,020h,0ffh	; 5dab

; ----------------------------------------------------------------------
; DATOS guion_0x5DB1: 121 bytes, 6 tramos, 103 bytes a la VRAM; lo pinta
;   0x4713
;   0x5db1..0x5e2a  (121 bytes)
DATA_guion_0x5DB1:
	defb 0abh,039h,030h,02ch,021h,039h,000h,033h,025h,02ch,025h,023h,034h,0feh,007h,03ah	; 5db1  .90,!9.3%,%#4..:
	defb 011h,030h,02ch,021h,039h,025h,032h,000h,000h,03ch,03dh,000h,02ah,02fh,039h,033h	; 5dc1  .0,!9%2..<=.*/93
	defb 034h,029h,023h,02bh,0feh,047h,03ah,012h,030h,02ch,021h,039h,025h,032h,033h,000h	; 5dd1  4)#+.G:.0,!9%23.
	defb 03ch,03dh,000h,02ah,02fh,039h,033h,034h,029h,023h,02bh,0feh,087h,03ah,011h,030h	; 5de1  <=.*/934)#+..:.0
	defb 02ch,021h,039h,025h,032h,000h,000h,03ch,03dh,000h,02bh,025h,039h,022h,02fh,021h	; 5df1  ,!9%2..<=.+%9"/!
	defb 032h,024h,0feh,0c7h,03ah,012h,030h,02ch,021h,039h,025h,032h,033h,000h,03ch,03dh	; 5e01  2$..:.0,!9%23.<=
	defb 000h,02bh,025h,039h,022h,02fh,021h,032h,024h,0feh,00bh,039h,01ah,02bh,02fh,02eh	; 5e11  .+%9"/!2$..9.+/.
	defb 021h,02dh,029h,000h,011h,019h,018h,014h,0ffh	; 5e21  !-)......

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5e2a..0x5e37  (13 bytes)
DATA_5E2A:
	defb 06bh,039h,027h,021h,02dh,025h,000h,000h,02fh,036h,025h,032h,0feh	; 5e2a  k9'!-%../6%2.

; ----------------------------------------------------------------------
; DATOS guion_0x5E37: 11 bytes, 1 tramos, 8 bytes a la VRAM; lo pinta 0x41E7
;   0x5e37..0x5e42  (11 bytes)
DATA_guion_0x5E37:
	defb 02ch,039h,030h,02ch,021h,039h,025h,032h,000h,011h,0ffh	; 5e37  ,90,!9%2...

; ----------------------------------------------------------------------
; DATOS guion_0x5E42: 22 bytes, 1 tramos, 19 bytes a la VRAM; lo pinta 0x415A,
;   0x4169
;   0x5e42..0x5e58  (22 bytes)
DATA_guion_0x5E42:
	defb 066h,039h,020h,000h,036h,029h,024h,025h,02fh,000h,023h,021h,032h,034h,032h,029h	; 5e42  f9 .6)$%/.#!242)
	defb 024h,027h,025h,000h,020h,0ffh	; 5e52

; ----------------------------------------------------------------------
; DATOS sin identificar  0x5e58..0x6051  (505 bytes)
DATA_5E58:
	defb 009h,039h,024h,025h,02dh,02fh,02eh,033h,034h,032h,021h,034h,029h,02fh,02eh,0ffh	; 5e58  .9$%-/.342!4)/..
	defb 060h,039h,020h,06ch,080h,060h,038h,019h,09bh,085h,000h,0b0h,0b0h,0b0h,0b1h,004h	; 5e68  `9 l.`8.........
	defb 000h,084h,0c3h,000h,0c5h,0c7h,003h,000h,082h,0cbh,0cdh,004h,000h,082h,0cfh,0d1h	; 5e78  ................
	defb 004h,000h,096h,0d2h,0d4h,000h,0c2h,000h,0aah,0ach,0adh,0b2h,0b7h,000h,0beh,0beh	; 5e88  ................
	defb 0c4h,0beh,0c6h,0c8h,0c9h,0beh,0cah,0cch,0ceh,004h,0beh,083h,0d0h,0c8h,0c9h,003h	; 5e98  ................
	defb 0beh,08bh,0d3h,0d7h,0d6h,0c2h,000h,0b5h,0b6h,0b8h,0b3h,0b4h,000h,00ch,0c1h,001h	; 5ea8  ................
	defb 096h,005h,09ah,001h,098h,004h,0c1h,001h,0d5h,008h,0c0h,00ch,068h,001h,097h,005h	; 5eb8  ............h...
	defb 000h,001h,099h,00dh,068h,00ch,000h,001h,0c5h,005h,0c7h,001h,0c6h,00dh,000h,080h	; 5ec8  ....h...........
	defb 0e3h,03ah,09ah,023h,02fh,02dh,029h,023h,000h,022h,021h,02bh,025h,032h,039h,000h	; 5ed8  .:.#/-)#."!+%29.
	defb 000h,01ah,02bh,02fh,02eh,021h,02dh,029h,000h,011h,019h,018h,014h,000h,040h,038h	; 5ee8  ..+/.!-)......@8
	defb 02ah,001h,001h,04ah,01fh,001h,001h,04bh,015h,001h,040h,058h,006h,000h,083h,059h	; 5ef8  *..J...K..@X...Y
	defb 000h,059h,01dh,000h,083h,059h,000h,059h,01ch,000h,085h,0efh,0f0h,0f1h,0f2h,0f3h	; 5f08  .Y...Y.Y........
	defb 005h,000h,083h,040h,048h,044h,013h,000h,085h,0f4h,0f5h,0f6h,0f7h,0f8h,005h,000h	; 5f18  ...@HD..........
	defb 083h,041h,049h,045h,003h,000h,001h,0e9h,019h,000h,083h,042h,04ah,046h,003h,000h	; 5f28  .AIE.......BJF..
	defb 08ah,0eah,000h,0ebh,0ebh,0ebh,000h,0ech,0ech,0edh,0edh,00fh,000h,086h,04ch,043h	; 5f38  ..............LC
	defb 04bh,047h,04ch,000h,00bh,04dh,02fh,000h,082h,0e0h,0e1h,006h,000h,082h,0e0h,0e1h	; 5f48  KGL..M/.........
	defb 003h,000h,001h,0e8h,012h,000h,08eh,0e2h,0e3h,000h,000h,0e4h,0e5h,000h,000h,0e4h	; 5f58  ................
	defb 0e5h,000h,000h,0deh,0dfh,011h,000h,08fh,0d0h,0dah,0dbh,0d0h,0d0h,0dah,0dbh,0d0h	; 5f68  ................
	defb 0d0h,0dah,0dbh,0d0h,0d0h,0dah,0dbh,004h,0d0h,00dh,000h,08fh,0d1h,0d2h,0d5h,0d1h	; 5f78  ................
	defb 0d1h,0d2h,0d5h,0d1h,0d1h,0d2h,0d5h,0d1h,0d1h,0d2h,0d5h,004h,0d1h,00eh,000h,08eh	; 5f88  ................
	defb 0d3h,0d6h,000h,000h,0d3h,0d6h,000h,000h,0d3h,0d6h,000h,000h,0d3h,0d6h,004h,000h	; 5f98  ................
	defb 00eh,0f9h,08eh,0d4h,0d7h,0fah,0fah,0d4h,0d7h,0fah,0fah,0d4h,0d7h,0fah,0fah,0d4h	; 5fa8  ................
	defb 0d7h,004h,0fah,020h,0fbh,027h,001h,08eh,022h,02fh,02eh,035h,033h,001h,001h,016h	; 5fb8  ... .'.."/.53...
	defb 010h,010h,037h,010h,010h,038h,004h,010h,027h,001h,000h,04ch,038h,001h,040h,005h	; 5fc8  ..7..8..'..L8.@.
	defb 043h,018h,001h,089h,04ch,001h,041h,00fh,045h,046h,047h,048h,049h,016h,001h,084h	; 5fd8  C...L.A.EFGHI...
	defb 04eh,04dh,04fh,042h,005h,044h,000h,047h,038h,082h,01ch,01eh,021h,001h,001h,04ch	; 5fe8  NMOB.D.G8...!..L
	defb 01ch,001h,085h,01bh,01dh,04eh,04dh,04fh,000h,008h,008h,008h,008h,008h,008h,008h	; 5ff8  .....NMO........
	defb 008h,008h,008h,008h,008h,008h,008h,009h,008h,008h,008h,008h,008h,008h,004h,014h	; 6008  ................
	defb 004h,004h,004h,004h,004h,004h,004h,004h,004h,004h,008h,008h,008h,008h,009h,018h	; 6018  ................
	defb 008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h	; 6028  ................
	defb 008h,004h,004h,004h,004h,004h,004h,014h,004h,008h,008h,008h,008h,008h,008h,008h	; 6038  ................
	defb 008h,008h,008h,009h,018h,008h,008h,008h,008h	; 6048  .........

; ======================================================================
; CODIGO 0x6051..0x60b0  (95 bytes)
; ======================================================================


L_6051:
	ld de,00000h		;6051
	call L_60C7		;6054
	ld de,00800h		;6057
	call L_60C7		;605a
	ld de,01000h		;605d
	call L_60C7		;6060
	ld hl,065dfh		;6063
	call descomprime		;6066
	ld hl,06aeeh		;6069
	call descomprime		;606c
	ld hl,061fah		;606f
	ld de,02500h		;6072
	ld bc,00050h		;6075
	call vuelca_bloque		;6078
	ld hl,06853h		;607b
	call L_43F5		;607e
	ld hl,06c99h		;6081
	call descomprime		;6084
	ld de,006d0h		;6087
	ld b,013h		;608a
L_608C:
	push bc			;608c
	ld hl,06d14h		;608d
	ld bc,00010h		;6090
	call vuelca_bloque		;6093
	ld a,010h		;6096
	call suma_a_a_de		;6098
	pop bc			;609b
	djnz L_608C		;609c
	ld hl,06495h		;609e
	call descomprime		;60a1
L_60A4:
	ld a,071h		;60a4
L_60A6:
	ld bc,00170h		;60a6
	ld de,01080h		;60a9
	call rellena_vram		;60ac
	ret			;60af

; ----------------------------------------------------------------------
; DATOS sin identificar  0x60b0..0x60c7  (23 bytes)
DATA_60B0:
	defb 011h,000h,038h,03eh,000h,001h,000h,003h,0cdh,040h,040h,03ch,013h,00bh,06fh,078h	; 60b0  ..8>.....@@<..ox
	defb 0b1h,07dh,020h,0f4h,018h,0feh,0c9h	; 60c0

; ======================================================================
; CODIGO 0x60c7..0x61f5  (302 bytes)
; ======================================================================


L_60C7:
	push de			;60c7
	xor a			;60c8
	ld c,010h		;60c9
L_60CB:
	ld b,008h		;60cb
L_60CD:
	call escribe_en_vram		;60cd
	inc de			;60d0
	djnz L_60CD		;60d1
	inc a			;60d3
	dec c			;60d4
	jr nz,L_60CB		;60d5
	ld bc,00250h		;60d7
	ld a,0f1h		;60da
	call L_43D2		;60dc
	ld hl,06a7ch		;60df
	call L_43F5		;60e2
	pop de			;60e5
	push de			;60e6
	ld hl,00400h		;60e7
	add hl,de			;60ea
	ex de,hl			;60eb
	xor a			;60ec
	call L_61A1		;60ed
	pop de			;60f0
	push de			;60f1
	ld hl,00680h		;60f2
	add hl,de			;60f5
	ex de,hl			;60f6
	ld hl,06f7dh		;60f7
	call L_43F2		;60fa
	pop de			;60fd
	push de			;60fe
	ld hl,00398h		;60ff
	add hl,de			;6102
	ex de,hl			;6103
	xor a			;6104
	call L_6145		;6105
	pop de			;6108
	ld hl,06000h		;6109
	add hl,de			;610c
	ex de,hl			;610d
	push de			;610e
	ld hl,061f5h		;610f
	call L_43F2		;6112
	pop de			;6115
	push de			;6116
	ld hl,00400h		;6117
	add hl,de			;611a
	ex de,hl			;611b
	ld hl,066a5h		;611c
	call L_43F2		;611f
	pop de			;6122
	push de			;6123
	ld hl,00680h		;6124
	add hl,de			;6127
	ex de,hl			;6128
	ld hl,06d26h		;6129
	call L_43F2		;612c
	pop de			;612f
	ld hl,00398h		;6130
	add hl,de			;6133
	ex de,hl			;6134
	jp L_616B		;6135
L_6138:
	ld hl,06ac7h		;6138
	ld a,(0e051h)		;613b
	or a			;613e
	jr z,L_6145		;613f
	dec a			;6141
	rra			;6142
	jr c,L_6148		;6143
L_6145:
	ld hl,06ab4h		;6145
L_6148:
	jp L_43F2		;6148
L_614B:
	ld hl,06addh		;614b
	ld a,(0e051h)		;614e
	or a			;6151
	jr z,L_6158		;6152
	dec a			;6154
	rra			;6155
	jr c,L_615B		;6156
L_6158:
	ld hl,06abah		;6158
L_615B:
	jp L_43F2		;615b
L_615E:
	ld hl,0657bh		;615e
	ld a,(0e051h)		;6161
	or a			;6164
	jr z,L_616B		;6165
	dec a			;6167
	rra			;6168
	jr c,L_616E		;6169
L_616B:
	ld hl,06521h		;616b
L_616E:
	jp L_43F2		;616e
L_6171:
	ld hl,065cbh		;6171
	ld a,(0e051h)		;6174
	or a			;6177
	jr z,L_617E		;6178
	dec a			;617a
	rra			;617b
	jr c,L_6181		;617c
L_617E:
	ld hl,06566h		;617e
L_6181:
	jp L_43F2		;6181
L_6184:
	ld de,013d0h		;6184
	ld hl,06517h		;6187
	ld a,(0e051h)		;618a
	or a			;618d
	jr z,L_6194		;618e
	dec a			;6190
	rra			;6191
	jr c,L_6197		;6192
L_6194:
	ld hl,0650dh		;6194
L_6197:
	jp L_43F2		;6197
L_619A:
	ld a,(0e051h)		;619a
	or a			;619d
	jr z,L_61A7		;619e
	dec a			;61a0
L_61A1:
	rra			;61a1
	ld hl,06be6h		;61a2
	jr c,L_61AA		;61a5
L_61A7:
	ld hl,06b34h		;61a7
L_61AA:
	jp L_43F2		;61aa
L_61AD:
	ld de,004b0h		;61ad
	ld a,(0e051h)		;61b0
	or a			;61b3
	jr z,L_61BD		;61b4
	ld hl,06b14h		;61b6
	rra			;61b9
	jp nc,L_43F2		;61ba
L_61BD:
	ld hl,06af4h		;61bd
	jp L_43F2		;61c0
L_61C3:
	ld de,00a00h		;61c3
	call L_61E0		;61c6
	ld de,01200h		;61c9
	call L_61E0		;61cc
	ld de,00200h		;61cf
	push de			;61d2
	call L_61E0		;61d3
	pop de			;61d6
	ld hl,06eb9h		;61d7
	push hl			;61da
	ld hl,0702bh		;61db
	jr L_61E7		;61de
L_61E0:
	ld hl,06e56h		;61e0
	push hl			;61e3
	ld hl,06ffah		;61e4
L_61E7:
	push de			;61e7
	call L_43F2		;61e8
	pop de			;61eb
	ld hl,02000h		;61ec
	add hl,de			;61ef
	ex de,hl			;61f0
	pop hl			;61f1
	jp L_43F2		;61f2

; ----------------------------------------------------------------------
; DATOS bloque_0x61F5: 672 bytes comprimidos -> 904 en VRAM (1 tramos: ?); lo
;   carga 0x610F
;   0x61f5..0x6495  (672 bytes)
DATA_bloque_0x61F5:
	defb 040h,000h,040h,000h,0d8h,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h	; 61f5  @.@...."ccc"...8
	defb 018h,018h,018h,018h,07eh,000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h	; 6205  ....~.>c..<p..>c
	defb 003h,00eh,003h,063h,03eh,000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h	; 6215  ...c>...6ff....`
	defb 07eh,063h,003h,063h,03eh,000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h	; 6225  ~c.c>.>c`~cc>..c
	defb 006h,00ch,018h,018h,018h,000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h	; 6235  ......>cc>cc>.>c
	defb 063h,03fh,003h,063h,03eh,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,083h,03fh,007h	; 6245  c?.c><B....B<.?.
	defb 001h,009h,000h,088h,007h,01fh,03fh,07fh,0f8h,0e0h,0c0h,0e0h,008h,000h,084h,0f0h	; 6255  ......?.........
	defb 0fch,0feh,0feh,0e8h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6265  ................
	defb 07eh,000h,000h,000h,000h,01ch,036h,063h,063h,07fh,063h,063h,000h,07eh,063h,063h	; 6275  ~.....6cc.cc.~cc
	defb 07eh,063h,063h,07eh,000h,03eh,063h,060h,060h,060h,063h,03eh,000h,07ch,066h,063h	; 6285  ~cc~.>c```c>.|fc
	defb 063h,063h,066h,07ch,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07fh,060h,060h	; 6295  ccf|..``~``...``
	defb 07eh,060h,060h,060h,000h,03eh,063h,060h,067h,063h,063h,03fh,000h,063h,063h,063h	; 62a5  ~```.>c`gcc?.ccc
	defb 07fh,063h,063h,063h,000h,03ch,018h,018h,018h,018h,018h,03ch,000h,01fh,006h,006h	; 62b5  .ccc.<.....<....
	defb 006h,006h,066h,03ch,000h,063h,066h,06ch,078h,07ch,06eh,067h,0f0h,000h,060h,060h	; 62c5  ..f<.cflx|ng..``
	defb 060h,060h,060h,060h,07fh,000h,063h,077h,07fh,07fh,06bh,063h,063h,000h,063h,073h	; 62d5  ````..cw..kcc.cs
	defb 07bh,07fh,06fh,067h,063h,000h,03eh,063h,063h,063h,063h,063h,03eh,000h,07eh,063h	; 62e5  {.ogc.>ccccc>.~c
	defb 063h,063h,07eh,060h,060h,000h,046h,06eh,07eh,07eh,056h,046h,046h,000h,07eh,063h	; 62f5  cc~``.Fn~~VFF.~c
	defb 063h,062h,07ch,066h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh,000h,07eh,018h	; 6305  cb|fc.>c`>.c>.~.
	defb 018h,018h,018h,018h,018h,000h,063h,063h,063h,063h,063h,063h,03eh,000h,063h,063h	; 6315  ......cccccc>.cc
	defb 063h,063h,036h,01ch,008h,000h,042h,024h,018h,018h,024h,042h,000h,000h,000h,000h	; 6325  cc6...B$..$B....
	defb 07eh,000h,07eh,000h,000h,000h,066h,066h,07eh,03ch,018h,018h,018h,0b0h,000h,07fh	; 6335  ~.~...ff~<......
	defb 007h,00eh,01ch,038h,070h,07fh,000h,000h,02ch,076h,07eh,03ch,03ch,03ch,000h,000h	; 6345  ...8p...,v~<<<..
	defb 002h,000h,08ah,0aah,0aah,0dah,000h,000h,008h,048h,0eeh,04ah,04ah,06ah,000h,00fh	; 6355  .........H.JJj..
	defb 01fh,0ffh,0ffh,0ffh,0ffh,00fh,000h,000h,0feh,0e0h,0e0h,0c0h,0c0h,080h,00eh,000h	; 6365  ................
	defb 082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,08bh,01fh,03fh,07fh	; 6375  .........>.?..?.
	defb 0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,003h,000h,002h,03eh,005h,000h,083h,01fh	; 6385  ...........>....
	defb 07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch,0bch,005h,000h	; 6395  ...........x....
	defb 083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h,0bch,0feh,0dfh	; 63a5  .?..............
	defb 005h,000h,088h,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,003h,0f0h,002h,03fh,006h	; 63b5  ...x..`..`....?.
	defb 03eh,088h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,003h,03eh,085h,07eh,0fch,0fch	; 63c5  >.....?....>.~..
	defb 0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh,00fh,008h,01eh,088h	; 63d5  ................
	defb 0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,007h,0e7h,081h,0f7h,008h,08fh,008h,01eh	; 63e5  ..?.............
	defb 082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h,010h,0e0h	; 63f5  ...........h.(..
	defb 088h,000h,000h,01eh,07fh,0ffh,0ffh,0ffh,07fh,004h,000h,084h,080h,0c0h,0e0h,0e0h	; 6405  ................
	defb 0a0h,0f0h,038h,054h,092h,0feh,092h,054h,038h,00fh,01ch,02ah,049h,07fh,049h,02ah	; 6415  ..8T...T8..*I.I*
	defb 01ch,0f0h,038h,044h,0aah,092h,0aah,044h,038h,00fh,01ch,022h,055h,049h,055h,022h	; 6425  ..8D...D8.."UIU"
	defb 01ch,001h,01ch,006h,00eh,001h,00fh,001h,038h,006h,070h,001h,0f0h,007h,000h,00dh	; 6435  ........8.p.....
	defb 0ffh,084h,09fh,00fh,00fh,09fh,003h,00fh,005h,000h,008h,001h,088h,000h,00eh,01bh	; 6445  ................
	defb 011h,011h,001h,001h,001h,098h,0efh,0efh,0efh,000h,0bfh,0bfh,0bfh,000h,07fh,07fh	; 6455  ................
	defb 07fh,000h,0efh,0efh,0efh,000h,07fh,07fh,07fh,000h,0efh,0efh,0efh,000h,090h,0ffh	; 6465  ................
	defb 000h,0ffh,000h,000h,0ffh,000h,0ffh,0ffh,000h,0ffh,0e7h,0c3h,081h,000h,000h,006h	; 6475  ................
	defb 000h,002h,0c0h,006h,000h,002h,030h,006h,000h,002h,00ch,006h,000h,002h,003h,000h	; 6485  ......0.........

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6495..0x650d  (120 bytes)
DATA_6495:
	defb 068h,033h,0f0h,07fh,029h,03ch,057h,01fh,002h,00bh,03fh,0e1h,040h,081h,060h,0c0h	; 6495  h3..)<W...?.@.`.
	defb 000h,080h,0e1h,0fah,0aah,0f2h,0aeh,010h,0feh,010h,0ffh,012h,01fh,014h,00fh,006h	; 64a5  ................
	defb 01fh,00eh,01ah,000h,0cfh,080h,080h,080h,0c0h,05fh,0c0h,00fh,0c1h,00ah,007h,00ah	; 64b5  ........._......
	defb 007h,0e2h,00ch,04fh,0a6h,0cfh,0edh,08bh,0efh,089h,0efh,020h,0f8h,030h,0f8h,050h	; 64c5  ...O....... .0.P
	defb 0f8h,050h,070h,004h,007h,00eh,00dh,004h,005h,00ah,00bh,041h,0f7h,041h,0f7h,0a0h	; 64d5  .Pp........A.A..
	defb 0f3h,0c6h,0b3h,002h,0e2h,082h,0e3h,0c2h,0e2h,002h,0dfh,008h,008h,00bh,0c8h,008h	; 64e5  ................
	defb 008h,00ch,0e9h,0a0h,090h,0e0h,080h,080h,080h,080h,000h,000h,000h,000h,000h,000h	; 64f5  ................
	defb 000h,000h,013h,080h,068h,013h,068h,0e0h	; 6505  ....h.h.

; ----------------------------------------------------------------------
; DATOS bloque_0x650D: 10 bytes comprimidos -> 8 en VRAM (1 tramos: ?); lo
;   carga 0x6194
;   0x650d..0x6517  (10 bytes)
DATA_bloque_0x650D:
	defb 088h,002h,002h,002h,002h,003h,0ech,0ech,0ech,000h	; 650d  ..........

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6517..0x6521  (10 bytes)
DATA_6517:
	defb 088h,005h,005h,005h,005h,007h,0e4h,0e4h,0e4h,000h	; 6517  ..........

; ----------------------------------------------------------------------
; DATOS bloque_0x6521 (tramo): 90 bytes comprimidos -> 104 en VRAM (1 tramos:
;   ?); lo carga 0x616B
;   0x6521..0x6566  (69 bytes)  de 0x6521..0x657b (90 bytes)
DATA_bloque_0x6521:
	defb 090h,030h,070h,0d0h,0f8h,0f7h,06fh,02fh,017h,000h,070h,038h,078h,0b8h,0d0h,0e0h	; 6521  .0p...o/..p8x...
	defb 0c0h,006h,000h,082h,03ch,0f8h,007h,000h,001h,00ch,090h,0f0h,0d8h,0bdh,0fbh,07bh	; 6531  ....<..........{
	defb 077h,017h,003h,00eh,01ah,0deh,0eeh,0f6h,0f4h,0f0h,0e0h,006h,000h,082h,03ch,0f8h	; 6541  w.............<.
	defb 007h,000h,001h,00ch,090h,0f0h,0d8h,0bdh,0fbh,07bh,077h,017h,003h,00eh,01ah,0deh	; 6551  .........{w.....
	defb 0eeh,0f6h,0f4h,0f0h,0e0h	; 6561

; ----------------------------------------------------------------------
; DATOS bloque_0x6566: 21 bytes comprimidos -> 24 en VRAM (1 tramos: ?); lo
;   carga 0x617E
;   0x6566..0x657b  (21 bytes)
DATA_bloque_0x6566:
	defb 088h,000h,00ch,046h,0c6h,0ceh,0feh,07ch,0ffh,006h,000h,086h,006h,023h,063h,067h	; 6566  ...F...|.....#cg
	defb 07fh,03eh,004h,0ffh,000h	; 6576

; ----------------------------------------------------------------------
; DATOS sin identificar  0x657b..0x66a5  (298 bytes)
DATA_657B:
	defb 090h,01fh,0dbh,0fdh,0ffh,0ffh,0ffh,07fh,07fh,0c0h,070h,0b8h,0f8h,0f8h,0f8h,0f0h	; 657b  ..........p.....
	defb 0f0h,004h,000h,084h,01bh,07dh,07eh,0feh,004h,000h,084h,0b0h,0dch,0ech,0eeh,0b0h	; 658b  .....}~.........
	defb 0feh,0ffh,0ffh,0ffh,0ffh,055h,07fh,07fh,0eeh,0feh,0feh,0feh,0feh,054h,0feh,0feh	; 659b  .....U.......T..
	defb 000h,000h,000h,01bh,07dh,07dh,0feh,0feh,000h,000h,000h,0b0h,0dch,0eeh,0eeh,0eeh	; 65ab  ....}}..........
	defb 0feh,0ffh,0ffh,0ffh,0d5h,0aah,07fh,07fh,0efh,0ffh,0ffh,0ffh,055h,0abh,0feh,0feh	; 65bb  ............U...
	defb 088h,07ch,0feh,0feh,0feh,07ch,07ch,07ch,0ffh,005h,000h,001h,03eh,003h,07fh,003h	; 65cb  .|...|||....>...
	defb 03eh,004h,0ffh,000h,000h,024h,0c0h,030h,048h,048h,000h,048h,048h,048h,030h,000h	; 65db  >....$.0HH.HHH0.
	defb 008h,008h,000h,008h,008h,008h,000h,030h,008h,008h,030h,040h,040h,040h,030h,030h	; 65eb  .......0..0@@@00
	defb 008h,008h,030h,008h,008h,008h,030h,000h,048h,048h,030h,008h,008h,008h,000h,030h	; 65fb  ..0...0.HH0....0
	defb 040h,040h,030h,008h,008h,008h,030h,030h,040h,040h,030h,048h,048h,048h,030h,030h	; 660b  @@0...00@@0HHH00
	defb 008h,008h,000h,008h,008h,008h,000h,0c0h,030h,048h,048h,030h,048h,048h,048h,030h	; 661b  ........0HH0HHH0
	defb 030h,048h,048h,030h,008h,008h,008h,030h,040h,0c2h,0c2h,040h,042h,002h,002h,000h	; 662b  0HH0...0@..@B...
	defb 040h,0c0h,0c0h,040h,040h,000h,000h,000h,009h,015h,015h,01dh,015h,000h,000h,000h	; 663b  @..@@...........
	defb 000h,000h,000h,040h,0c0h,0c0h,040h,040h,000h,000h,000h,019h,015h,015h,019h,011h	; 664b  ...@..@@........
	defb 000h,002h,002h,040h,0c2h,0c2h,042h,040h,0b0h,00ch,012h,092h,000h,012h,092h,012h	; 665b  ...@..B@........
	defb 00ch,000h,002h,082h,000h,002h,082h,002h,000h,00ch,002h,082h,00ch,010h,090h,010h	; 666b  ................
	defb 00ch,00ch,002h,082h,00ch,002h,082h,002h,00ch,000h,012h,092h,00ch,002h,082h,002h	; 667b  ................
	defb 000h,00ch,010h,090h,00ch,002h,082h,002h,00ch,004h,000h,082h,07fh,0e0h,00ah,0f8h	; 668b  ................
	defb 004h,000h,082h,0feh,007h,00ah,01fh,010h,000h,000h	; 669b  ..........

; ----------------------------------------------------------------------
; DATOS bloque_0x66A5: 430 bytes comprimidos -> 608 en VRAM (1 tramos: ?); lo
;   carga 0x611C
;   0x66a5..0x6853  (430 bytes)
DATA_bloque_0x66A5:
	defb 001h,01fh,007h,010h,001h,0ffh,006h,000h,082h,0ffh,0f0h,00fh,010h,005h,000h,083h	; 66a5  ................
	defb 003h,00ch,0f0h,004h,000h,004h,0ffh,004h,000h,001h,07fh,003h,0ffh,004h,000h,004h	; 66b5  ................
	defb 0ffh,004h,000h,001h,0feh,003h,0ffh,004h,000h,004h,0ffh,001h,07fh,017h,0ffh,082h	; 66c5  ................
	defb 0fch,0feh,006h,0ffh,090h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,001h,003h	; 66d5  ................
	defb 007h,00fh,01fh,03fh,07fh,005h,000h,087h,001h,003h,007h,00fh,01fh,03fh,07fh,004h	; 66e5  ...?.........?..
	defb 0ffh,008h,07fh,083h,000h,000h,0ffh,005h,000h,089h,0ffh,000h,0ffh,000h,0ffh,000h	; 66f5  ................
	defb 0ffh,000h,07fh,006h,080h,082h,07fh,0efh,006h,015h,082h,0efh,0ffh,006h,049h,081h	; 6705  ..............I.
	defb 0ffh,0a1h,0ffh,0c2h,0a4h,098h,098h,0a4h,0c2h,081h,0f8h,048h,028h,018h,018h,028h	; 6715  ...........H(..(
	defb 048h,088h,081h,0c2h,0a4h,098h,098h,0a4h,0c2h,081h,088h,048h,028h,018h,018h,028h	; 6725  H..........H(..(
	defb 048h,088h,0ffh,006h,011h,083h,0ffh,000h,0ffh,006h,000h,083h,081h,0c2h,0a4h,005h	; 6735  H...............
	defb 0ffh,084h,088h,048h,028h,0f8h,004h,0ffh,004h,00fh,002h,07eh,006h,000h,004h,003h	; 6745  ...H(......~....
	defb 001h,0c0h,007h,0e0h,004h,000h,004h,0c0h,001h,0f8h,007h,0fch,0a7h,000h,020h,010h	; 6755  .............. .
	defb 038h,038h,018h,0dbh,0ffh,000h,07ch,082h,082h,082h,082h,07ch,000h,000h,07ch,082h	; 6765  88....|....|..|.
	defb 082h,082h,082h,07ch,000h,000h,077h,054h,057h,054h,054h,074h,000h,000h,070h,040h	; 6775  ...|..wTWTTt..p@
	defb 070h,040h,040h,040h,003h,000h,004h,004h,003h,000h,001h,070h,004h,050h,092h,070h	; 6785  p@@@.......p.P.p
	defb 000h,000h,090h,0d0h,0d0h,0b0h,0b0h,090h,000h,01ch,03eh,084h,080h,080h,03eh,01ch	; 6795  ..........>...>.
	defb 000h,008h,0ffh,001h,0feh,007h,0ffh,091h,000h,080h,0ffh,0ffh,0ffh,080h,000h,000h	; 67a5  ................
	defb 0fch,0ffh,0c0h,0c0h,0c0h,0cfh,0f0h,0fch,078h,004h,084h,083h,07bh,000h,079h,009h	; 67b5  ........x...{.y.
	defb 0f8h,087h,0fch,0feh,03fh,01fh,00fh,007h,007h,004h,00fh,009h,07eh,086h,03ch,000h	; 67c5  ....?.......~.<.
	defb 000h,07eh,07eh,03ch,005h,000h,004h,07eh,003h,0ffh,089h,07fh,0f7h,07eh,03ch,000h	; 67d5  .~~<...~.....~<.
	defb 000h,0ffh,0ffh,000h,006h,0e0h,082h,0ffh,0e0h,006h,00fh,082h,0ffh,00fh,002h,0b6h	; 67e5  ................
	defb 006h,0ffh,004h,0e0h,084h,0f0h,0f8h,0fch,0feh,088h,000h,0fch,0feh,038h,01ch,00ch	; 67f5  .............8..
	defb 08ch,0cch,003h,0feh,085h,0f8h,0f0h,0e0h,0c0h,080h,002h,0b6h,006h,0ffh,002h,0b6h	; 6805  ................
	defb 086h,003h,007h,00fh,01fh,03fh,07fh,088h,000h,07ch,082h,082h,082h,082h,07ch,000h	; 6815  .....?...|....|.
	defb 010h,000h,084h,0f8h,0f0h,0e0h,07fh,004h,000h,084h,01fh,00fh,007h,0feh,004h,000h	; 6825  ................
	defb 00ah,000h,002h,003h,002h,030h,006h,000h,002h,030h,002h,000h,090h,0c0h,0c0h,000h	; 6835  .....0...0......
	defb 000h,030h,030h,003h,003h,00ch,00ch,000h,000h,030h,030h,000h,000h,000h	; 6845  .00......00...

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6853..0x6ab4  (609 bytes)
DATA_6853:
	defb 008h,080h,008h,000h,090h,000h,00ch,00dh,00fh,00eh,00fh,00dh,00ch,000h,0c0h,0c0h	; 6853  ................
	defb 000h,060h,060h,0e0h,0c0h,004h,000h,08ch,004h,00eh,00fh,006h,000h,000h,030h,078h	; 6863  .``...........0x
	defb 07ch,07eh,03ch,018h,00eh,000h,004h,0fch,086h,0f0h,0f6h,0f0h,0f6h,0f0h,0f6h,005h	; 6873  |~<.............
	defb 0f0h,003h,0ffh,0a0h,000h,0c0h,000h,070h,0f8h,0d9h,0f8h,070h,000h,080h,080h,0f1h	; 6883  .......p...p....
	defb 0e0h,0e4h,0e0h,0f1h,0ffh,0ffh,0ffh,0c7h,07ch,06ch,07ch,038h,000h,000h,0f8h,00ch	; 6893  ........|l|8....
	defb 006h,002h,003h,003h,008h,000h,0a8h,000h,0e7h,009h,009h,0e9h,00fh,009h,0e9h,000h	; 68a3  ................
	defb 023h,0b7h,0bfh,0bfh,0abh,0a3h,0a3h,000h,008h,01ch,03eh,07fh,01ch,01ch,01ch,000h	; 68b3  #.........>.....
	defb 010h,030h,07fh,0ffh,07fh,030h,010h,000h,010h,018h,0fch,0feh,0fch,018h,010h,002h	; 68c3  .0...0..........
	defb 0ffh,00eh,000h,010h,000h,008h,03ch,0d8h,000h,000h,000h,0fch,0ffh,0ffh,0fbh,0f8h	; 68d3  ......<.........
	defb 0fbh,0fdh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,0ffh,0ffh,0c0h,0ffh,0c0h	; 68e3  ................
	defb 0ffh,0ffh,0d5h,0ffh,0ebh,0ffh,0d5h,0ffh,000h,000h,000h,0ffh,0ffh,003h,0ffh,003h	; 68f3  ................
	defb 0ffh,0ffh,0c3h,0bdh,0bdh,0bdh,0c3h,0ffh,000h,000h,000h,0c0h,0c0h,0c0h,0c0h,0c0h	; 6903  ................
	defb 000h,000h,000h,003h,007h,007h,007h,003h,000h,000h,0ffh,0ffh,0ffh,0ebh,0f7h,0ebh	; 6913  ................
	defb 0f7h,0ebh,0f7h,0ebh,0f7h,0ebh,0ffh,0ffh,000h,000h,0ffh,0ffh,0b7h,0ffh,0b7h,0ffh	; 6923  ................
	defb 0c0h,0ffh,0ffh,087h,07bh,07bh,07bh,087h,0ffh,000h,000h,000h,000h,0ffh,0ffh,0e0h	; 6933  ....{{{.........
	defb 0eah,0ffh,0c3h,0ffh,0c3h,0ffh,0c3h,0ffh,0ffh,000h,000h,000h,000h,0ffh,0ffh,003h	; 6943  ................
	defb 0abh,000h,000h,07fh,0edh,0ffh,0ffh,03fh,03fh,000h,001h,003h,007h,00fh,00fh,00fh	; 6953  .......??.......
	defb 00fh,000h,000h,000h,000h,080h,0c0h,0f0h,0f0h,082h,0ffh,0ffh,000h,000h,000h,000h	; 6963  ................
	defb 000h,090h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,006h,002h,002h,002h	; 6973  ................
	defb 002h,007h,010h,000h,086h,007h,01fh,03fh,07eh,078h,0f8h,004h,0f0h,08bh,0f8h,078h	; 6983  .......?~x.....x
	defb 07eh,03fh,01fh,007h,0e0h,0f1h,0f3h,017h,007h,006h,00fh,08bh,007h,017h,0f3h,0f1h	; 6993  ~?..............
	defb 0e0h,07fh,0ffh,0ffh,0e3h,080h,080h,004h,000h,002h,080h,08ah,0e3h,0ffh,0ffh,07fh	; 69a3  ................
	defb 003h,0c3h,0e3h,0f3h,0f3h,0fbh,004h,07bh,08fh,0fbh,0f3h,0f3h,0e3h,0c3h,003h,0c0h	; 69b3  .......{........
	defb 0e0h,0f1h,0fbh,0ffh,0ffh,0dfh,0ceh,0c4h,007h,0c0h,001h,07bh,005h,0fbh,00ah,07bh	; 69c3  ...........{...{
	defb 086h,0c0h,0c3h,0c7h,0cfh,0cfh,0dfh,004h,0deh,08ah,0dfh,0cfh,0cfh,0c7h,0c3h,0c0h	; 69d3  ................
	defb 0fch,0feh,0feh,0c2h,008h,000h,084h,0c2h,0feh,0feh,0fch,010h,000h,003h,0ffh,083h	; 69e3  ................
	defb 0f1h,0f0h,0f1h,003h,0ffh,084h,0f1h,0f0h,0f0h,0f1h,003h,0ffh,08ah,080h,0c0h,0e0h	; 69f3  ................
	defb 0e0h,0e1h,0c1h,0c1h,083h,0e3h,0f3h,003h,0f7h,002h,0efh,082h,0dfh,07ch,003h,0feh	; 6a03  .............|..
	defb 002h,0efh,003h,0c7h,003h,0ffh,001h,083h,003h,001h,007h,00fh,003h,08fh,003h,0cfh	; 6a13  ................
	defb 002h,0efh,092h,0ffh,00fh,01fh,03eh,07ch,0f8h,0f0h,0e0h,0c0h,0e0h,0f0h,0f8h,07ch	; 6a23  ......>|.......|
	defb 03eh,01fh,00fh,007h,0bfh,002h,03fh,003h,03ch,003h,03fh,004h,03ch,083h,03fh,0bfh	; 6a33  >.....?.<.?.<.?.
	defb 0ffh,003h,0fbh,003h,003h,003h,0fbh,004h,003h,003h,0fbh,084h,0feh,0ffh,0ffh,0c7h	; 6a43  ................
	defb 003h,0c3h,001h,0c7h,003h,0ffh,001h,0cfh,002h,0c7h,002h,0c3h,099h,07ch,0bch,0beh	; 6a53  .............|..
	defb 0deh,0dfh,0cfh,0cfh,087h,087h,003h,003h,083h,083h,0c3h,0c3h,0e3h,01fh,01eh,03eh	; 6a63  ...............>
	defb 03ch,07ch,0f8h,0f8h,0f0h,0f0h,007h,0e0h,000h,010h,0b0h,001h,0a0h,007h,0f0h,001h	; 6a73  <|..............
	defb 0a0h,007h,0f0h,001h,0a0h,007h,0f0h,001h,0a0h,007h,0f0h,018h,0c0h,083h,070h,040h	; 6a83  ..............p@
	defb 070h,005h,000h,083h,070h,040h,070h,005h,00fh,083h,070h,040h,070h,015h,0f0h,018h	; 6a93  p...p@p...p@p...
	defb 080h,088h,0f0h,000h,070h,000h,000h,070h,000h,0f0h,003h,0ach,005h,0a0h,020h,0f0h	; 6aa3  ....p..p...... .
	defb 000h	; 6ab3

; ----------------------------------------------------------------------
; DATOS bloque_0x6AB4 (tramo): 19 bytes comprimidos -> 104 en VRAM (1 tramos:
;   ?); lo carga 0x6145
;   0x6ab4..0x6aba  (6 bytes)  de 0x6ab4..0x6ac7 (19 bytes)
DATA_bloque_0x6AB4:
	defb 010h,0b0h,020h,0a0h,020h,060h	; 6ab4

; ----------------------------------------------------------------------
; DATOS bloque_0x6ABA: 13 bytes comprimidos -> 24 en VRAM (1 tramos: ?); lo
;   carga 0x6158
;   0x6aba..0x6ac7  (13 bytes)
DATA_bloque_0x6ABA:
	defb 007h,060h,001h,0c0h,00ch,060h,001h,0f0h,001h,0e0h,002h,0f0h,000h	; 6aba  .`...`.......

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6ac7..0x6af4  (45 bytes)
DATA_6AC7:
	defb 010h,0b0h,015h,0a0h,003h,0b0h,005h,0a0h,003h,0b0h,014h,060h,002h,06ah,002h,0a0h	; 6ac7  ...........`.j..
	defb 004h,060h,002h,06ah,002h,0a0h,005h,080h,002h,0a0h,001h,0c0h,00ah,060h,002h,0a0h	; 6ad7  .`.j.........`..
	defb 001h,0f0h,001h,0e0h,002h,0f0h,000h,000h,004h,070h,0f0h,040h,0f0h	; 6ae7  .........p.@.

; ----------------------------------------------------------------------
; DATOS bloque_0x6AF4: 32 bytes comprimidos -> 48 en VRAM (1 tramos: ?); lo
;   carga 0x61BD
;   0x6af4..0x6b14  (32 bytes)
DATA_bloque_0x6AF4:
	defb 086h,050h,00ch,00ch,050h,050h,054h,00bh,050h,085h,00ch,00ch,050h,050h,054h,00bh	; 6af4  .P..PPT.P...PPT.
	defb 050h,085h,00ch,00ch,000h,005h,004h,005h,000h,085h,00dh,006h,008h,008h,009h,000h	; 6b04  P...............

; ----------------------------------------------------------------------
; DATOS bloque_0x6B14: 32 bytes comprimidos -> 48 en VRAM (1 tramos: ?); lo
;   carga 0x61B6
;   0x6b14..0x6b34  (32 bytes)
DATA_bloque_0x6B14:
	defb 086h,0b0h,00ch,00ch,0b0h,0b0h,0bah,00bh,0b0h,085h,00ch,00ch,0b0h,0b0h,0bah,00bh	; 6b14  ................
	defb 0b0h,085h,00ch,00ch,000h,00bh,00ah,005h,000h,085h,004h,004h,005h,005h,007h,000h	; 6b24  ................

; ----------------------------------------------------------------------
; DATOS bloque_0x6B34: 178 bytes comprimidos -> 608 en VRAM (1 tramos: ?); lo
;   carga 0x61A7
;   0x6b34..0x6be6  (178 bytes)
DATA_bloque_0x6B34:
	defb 02dh,032h,008h,0c0h,083h,03ch,02ch,02ch,005h,0c0h,083h,03ch,02ch,02ch,005h,0c0h	; 6b34  -2...<,,...<,,..
	defb 083h,03ch,02ch,02ch,005h,0c0h,083h,03ch,02ch,02ch,082h,0c0h,03ch,006h,02ch,083h	; 6b44  .<,,...<,,..<.,.
	defb 0c0h,0c0h,03ch,009h,02ch,001h,03ch,005h,0c0h,001h,03ch,02dh,02ch,05ch,03ch,004h	; 6b54  ..<.,.<...<-,\<.
	defb 02ch,004h,03ch,008h,02ch,009h,030h,004h,0c0h,001h,030h,006h,020h,005h,030h,004h	; 6b64  ,.<.,.0...0. .0.
	defb 0c0h,001h,030h,006h,020h,006h,081h,002h,021h,002h,0f2h,004h,0f8h,004h,0f2h,004h	; 6b74  ..0. ...!.......
	defb 0f5h,02ah,0f2h,002h,050h,002h,0f5h,081h,0e5h,003h,050h,082h,0c0h,030h,006h,020h	; 6b84  .*..P.....P..0. 
	defb 082h,0c0h,030h,008h,020h,083h,0f0h,0f0h,0e0h,005h,020h,004h,02ch,089h,023h,020h	; 6b94  ..0. ..... .,.# 
	defb 020h,032h,032h,03ch,03ch,023h,023h,00ch,020h,009h,02ch,006h,030h,00eh,0b0h,004h	; 6ba4   22<<##. .,.0...
	defb 030h,004h,0b0h,006h,030h,007h,020h,081h,023h,007h,020h,081h,023h,015h,020h,005h	; 6bb4  0...0. .#. .#. .
	defb 02ch,082h,0c0h,030h,010h,0c0h,006h,02ch,008h,0f2h,008h,002h,008h,00ch,083h,050h	; 6bc4  ,..0...,.......P
	defb 054h,054h,006h,050h,002h,054h,005h,050h,084h,000h,004h,004h,005h,004h,000h,020h	; 6bd4  TT.P.T.P....... 
	defb 0a0h,000h	; 6be4

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6be6..0x6d26  (320 bytes)
DATA_6BE6:
	defb 02dh,075h,008h,040h,083h,074h,054h,054h,005h,040h,083h,074h,054h,054h,005h,040h	; 6be6  -u.@.tTT.@.tTT.@
	defb 083h,074h,054h,054h,005h,040h,083h,074h,054h,054h,083h,040h,040h,074h,005h,054h	; 6bf6  .tTT.@.tTT.@@t.T
	defb 083h,040h,040h,074h,009h,054h,001h,074h,005h,040h,001h,074h,02dh,054h,05ch,074h	; 6c06  .@@t.T.t.@.t-T\t
	defb 004h,054h,004h,074h,008h,054h,009h,070h,008h,040h,083h,070h,050h,050h,005h,070h	; 6c16  .T.t.T.p.@.pPP.p
	defb 004h,040h,001h,070h,006h,050h,006h,081h,002h,051h,002h,0f5h,004h,0f8h,004h,0f5h	; 6c26  .@.p.P...Q......
	defb 004h,0f2h,02ah,0f5h,002h,020h,002h,0f2h,001h,0e2h,003h,020h,082h,040h,070h,006h	; 6c36  ..*.. ..... .@p.
	defb 050h,082h,040h,070h,008h,050h,083h,0f0h,0f0h,0e0h,005h,050h,004h,054h,089h,057h	; 6c46  P.@p.P.....P.T.W
	defb 050h,020h,075h,075h,074h,074h,057h,057h,00ch,050h,009h,054h,006h,070h,00eh,0b0h	; 6c56  P uuttWW.P.T.p..
	defb 004h,070h,004h,0b0h,006h,070h,007h,050h,001h,057h,007h,050h,001h,057h,015h,050h	; 6c66  .p...p.P.W.P.W.P
	defb 005h,054h,082h,040h,070h,010h,040h,006h,054h,008h,0f5h,008h,005h,008h,004h,083h	; 6c76  .T.@p.@.T.......
	defb 0b0h,0bah,0bah,006h,0b0h,002h,0bah,005h,0b0h,084h,000h,00ah,00ah,00bh,004h,000h	; 6c86  ................
	defb 020h,0a0h,000h,000h,045h,050h,04fh,010h,01fh,010h,04fh,010h,0a0h,006h,000h,082h	; 6c96   ...EPO...O.....
	defb 00fh,007h,006h,000h,082h,0f0h,070h,002h,0f0h,007h,0f8h,001h,074h,002h,0f8h,005h	; 6ca6  ......p.....t...
	defb 008h,001h,0f5h,003h,0f8h,003h,0f0h,084h,00fh,007h,00fh,0f8h,004h,008h,084h,0f0h	; 6cb6  ................
	defb 070h,0f8h,0f8h,00ch,080h,084h,00fh,007h,00fh,00fh,004h,000h,028h,071h,00bh,070h	; 6cc6  p...........(q.p
	defb 085h,004h,007h,005h,005h,004h,003h,00ch,006h,000h,002h,00ch,00dh,0c0h,010h,0a0h	; 6cd6  ................
	defb 018h,0a0h,008h,0afh,002h,007h,006h,0a0h,002h,007h,008h,0a0h,00eh,0aeh,008h,0a0h	; 6ce6  ................
	defb 008h,0afh,018h,0a0h,006h,0a0h,00ah,0bah,006h,0a0h,002h,0b0h,001h,0f0h,007h,0c0h	; 6cf6  ................
	defb 088h,0f0h,00ch,0f0h,00ch,0f0h,00ch,0f0h,005h,007h,0e0h,001h,040h,000h,090h,0a0h	; 6d06  ............@...
	defb 080h,0a0h,0a0h,080h,0a0h,0a0h,080h,0a0h,0a0h,080h,0a0h,0a0h,080h,0a0h,0a0h,000h	; 6d16  ................

; ----------------------------------------------------------------------
; DATOS bloque_0x6D26: 304 bytes comprimidos -> 368 en VRAM (1 tramos: ?); lo
;   carga 0x6129
;   0x6d26..0x6e56  (304 bytes)
DATA_bloque_0x6D26:
	defb 004h,000h,004h,0ffh,090h,0aah,055h,0aah,0ffh,0ffh,0bbh,000h,000h,0aah,055h,0aah	; 6d26  ......U.......U.
	defb 0ffh,0ffh,0bbh,038h,011h,007h,001h,084h,007h,001h,00fh,03fh,005h,0ffh,088h,0aah	; 6d36  ...8.......?....
	defb 055h,0aah,0ffh,0ffh,0bbh,01ch,088h,007h,080h,084h,0e0h,080h,0f0h,0fch,005h,0ffh	; 6d46  U...............
	defb 0c0h,055h,0a2h,0c3h,0c3h,03ch,01dh,001h,001h,0aah,045h,0c3h,0c3h,03ch,0b8h,080h	; 6d56  .U...<....E..<..
	defb 080h,005h,00dh,01ch,03fh,0ffh,000h,0ffh,0ffh,0a0h,0b0h,038h,0fch,0ffh,000h,0ffh	; 6d66  ....?......8....
	defb 0ffh,000h,000h,000h,002h,002h,007h,007h,003h,0fdh,07dh,03ch,01fh,0ffh,000h,0ffh	; 6d76  ..........}<....
	defb 0ffh,04eh,066h,031h,01fh,01dh,00eh,00fh,007h,0e6h,06eh,01ch,0f8h,0b8h,070h,0f0h	; 6d86  .Nf1......n...p.
	defb 0e0h,005h,000h,003h,00fh,005h,000h,003h,0f0h,004h,01fh,084h,00fh,00fh,007h,003h	; 6d96  ................
	defb 004h,0f8h,084h,0f0h,0f0h,0e0h,0c0h,008h,01fh,008h,0f8h,090h,04ah,06eh,031h,01fh	; 6da6  ............Jn1.
	defb 01eh,00eh,00eh,007h,0a6h,0eeh,01ch,0f8h,078h,070h,070h,0e0h,004h,000h,003h,0f0h	; 6db6  ........xpp.....
	defb 005h,000h,0ach,008h,01ch,0dch,07fh,07fh,07dh,07dh,03fh,03eh,03eh,03eh,03eh,000h	; 6dc6  ........}}?>>>>.
	defb 000h,000h,07fh,07dh,07fh,03ch,018h,000h,0feh,07ch,038h,010h,010h,010h,038h,07ch	; 6dd6  ...}.<...|8...8|
	defb 07ch,07ch,07ch,038h,010h,010h,038h,010h,028h,010h,010h,028h,010h,010h,028h,0d0h	; 6de6  |||8..8.(..(..(.
	defb 000h,007h,01ch,033h,06fh,0dfh,0bfh,0bfh,0ffh,000h,0ffh,01bh,055h,015h,051h,015h	; 6df6  ...3o.......U.Q.
	defb 0ffh,000h,0ffh,051h,057h,031h,057h,051h,0ffh,000h,0ffh,015h,055h,03bh,05bh,05bh	; 6e06  ...QW1WQ....U;[[
	defb 080h,0e0h,038h,0cch,0f6h,0fbh,0fdh,0fdh,0bfh,0bfh,0dfh,06fh,033h,01ch,007h,000h	; 6e16  ..8........o3...
	defb 0ffh,0e2h,0deh,0e6h,0fah,0c6h,000h,0ffh,0ffh,0d9h,0d6h,016h,0d6h,0d9h,000h,0ffh	; 6e26  ................
	defb 0ffh,08fh,0b7h,0b7h,08fh,0bfh,000h,0ffh,0fdh,0fdh,0fbh,0f6h,0cch,038h,0e0h,080h	; 6e36  .............8..
	defb 018h,0ffh,004h,000h,088h,008h,022h,000h,041h,000h,022h,008h,000h,004h,0ffh,000h	; 6e46  ......".A.".....

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6e56..0x6f7d  (295 bytes)
DATA_6E56:
	defb 001h,0ffh,004h,003h,004h,007h,089h,00fh,00fh,01fh,01fh,03fh,07fh,07fh,03fh,03fh	; 6e56  ...........?..??
	defb 003h,01fh,003h,00fh,004h,007h,085h,003h,003h,023h,0ffh,0ffh,004h,0c0h,004h,0e0h	; 6e66  .........#......
	defb 098h,0f0h,0f0h,0f8h,0f8h,0fch,0feh,0feh,0fch,0fch,0f8h,0f8h,0f8h,0f0h,0f0h,0f0h	; 6e76  ................
	defb 0e0h,0e0h,0e0h,0d0h,0c0h,0c0h,0c4h,0ffh,000h,00ah,07eh,001h,000h,008h,07eh,001h	; 6e86  ..........~...~.
	defb 000h,009h,07eh,002h,0ffh,006h,000h,005h,0ffh,085h,040h,0ffh,001h,0ffh,008h,050h	; 6e96  ..~.......@....P
	defb 000h,090h,07eh,0bdh,0dbh,0e7h,0e7h,0dbh,0bdh,07eh,010h,028h,010h,010h,028h,010h	; 6ea6  ..~......~.(..(.
	defb 010h,028h,000h,0d0h,000h,000h,000h,000h,000h,000h,003h,007h,00fh,01fh,01fh,03fh	; 6eb6  .(.............?
	defb 03fh,03fh,03fh,01fh,01fh,03fh,079h,0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; 6ec6  ???..?y.........
	defb 078h,0feh,0ffh,0ffh,0ffh,0ffh,0feh,03ch,000h,000h,000h,000h,0ffh,0ffh,087h,0fbh	; 6ed6  x......<........
	defb 0fbh,0f3h,0efh,0ffh,0ffh,0dfh,00dh,0bdh,045h,07fh,047h,0ffh,0ffh,0fbh,0a1h,0b6h	; 6ee6  ........E.G.....
	defb 0b4h,0bah,07dh,0ffh,0ffh,0ffh,0ffh,05bh,0ddh,05dh,0efh,0ffh,0c0h,0e0h,0f0h,0f0h	; 6ef6  ..}....[.]......
	defb 0f0h,0f0h,0e0h,0c0h,0b0h,000h,0c3h,0ffh,099h,000h,000h,066h,099h,07eh,0dbh,0dbh	; 6f06  ...........f.~..
	defb 0dbh,07eh,07eh,03ch,042h,000h,0c3h,0ffh,099h,000h,066h,066h,099h,0bdh,0c3h,0e7h	; 6f16  .~~<B.....ff....
	defb 0c3h,0e7h,07eh,03ch,024h,00fh,007h,007h,003h,000h,000h,000h,000h,0f0h,0e0h,0e0h	; 6f26  ..~<$...........
	defb 0c0h,000h,000h,000h,000h,0c0h,0f4h,0f7h,0f4h,0f7h,0f6h,0f5h,0f4h,07fh,03fh,07fh	; 6f36  ..............?.
	defb 03fh,063h,07bh,03bh,0f6h,0fch,0ffh,0dah,0dah,0c2h,0dah,0dah,0ffh,07fh,0ffh,02bh	; 6f46  ?c{;...........+
	defb 0ebh,023h,0f7h,037h,0feh,0fch,0ffh,0b5h,095h,0a5h,0a5h,0b5h,0ffh,07fh,0ffh,091h	; 6f56  .#.7............
	defb 077h,071h,077h,091h,0feh,0fch,0ffh,08ah,0bah,08ah,0bah,0bah,0ffh,07fh,0ffh,0d1h	; 6f66  wqw.............
	defb 057h,091h,097h,0d1h,0feh,0fch,000h	; 6f76

; ----------------------------------------------------------------------
; DATOS bloque_0x6F7D: 125 bytes comprimidos -> 368 en VRAM (1 tramos: ?); lo
;   carga 0x60F7
;   0x6f7d..0x6ffa  (125 bytes)
DATA_bloque_0x6F7D:
	defb 005h,0f0h,001h,0e0h,005h,0f1h,005h,0f0h,003h,0f1h,003h,0f0h,002h,060h,00bh,050h	; 6f7d  .............`.P
	defb 002h,060h,083h,080h,090h,080h,003h,0f1h,003h,0f0h,002h,060h,00bh,040h,095h,060h	; 6f8d  .`.........`.@.`
	defb 060h,080h,090h,080h,0f1h,0f6h,0f6h,0f6h,060h,060h,050h,050h,0f1h,0f6h,0f6h,0f6h	; 6f9d  `.......``PP....
	defb 060h,060h,050h,050h,004h,090h,004h,0feh,004h,090h,004h,0feh,00ch,090h,004h,0feh	; 6fad  ``PP............
	defb 070h,0f0h,018h,0f0h,00ah,020h,006h,02fh,002h,020h,006h,02fh,002h,020h,006h,02fh	; 6fbd  p.... ./. ./. ./
	defb 008h,020h,008h,0c0h,006h,0cfh,002h,0c0h,006h,0cfh,002h,0c0h,006h,0cfh,00ah,0c0h	; 6fcd  . ..............
	defb 088h,080h,060h,080h,060h,060h,080h,090h,080h,003h,000h,002h,060h,082h,080h,090h	; 6fdd  ..`.``......`...
	defb 004h,080h,003h,090h,002h,0b0h,00dh,0f0h,001h,0e0h,002h,0f0h,000h	; 6fed  .............

; ----------------------------------------------------------------------
; DATOS bloque_0x6FFA: 49 bytes comprimidos -> 208 en VRAM (1 tramos: ?); lo
;   carga 0x61E4
;   0x6ffa..0x702b  (49 bytes)
DATA_bloque_0x6FFA:
	defb 001h,090h,00ah,05fh,001h,09fh,003h,05fh,001h,051h,004h,05fh,001h,09fh,009h,05fh	; 6ffa  ..._..._.Q._..._
	defb 083h,08fh,08fh,090h,00ah,05fh,001h,09fh,003h,05fh,001h,051h,004h,05fh,001h,09fh	; 700a  ....._..._.Q._..
	defb 009h,05fh,002h,08fh,01eh,059h,00ch,080h,006h,007h,050h,000h,008h,096h,008h,010h	; 701a  ._...Y....P.....
	defb 000h	; 702a

; ----------------------------------------------------------------------
; DATOS sin identificar  0x702b..0x7061  (54 bytes)
DATA_702B:
	defb 050h,0f1h,0b0h,061h,061h,06fh,06fh,06fh,06fh,0efh,09fh,091h,06eh,09eh,06eh,091h	; 702b  P..aaoooo...n.n.
	defb 061h,061h,0f1h,061h,061h,06fh,06fh,06fh,0efh,0efh,09fh,09ah,08ah,08ah,089h,089h	; 703b  aa.aaooo........
	defb 061h,061h,0f1h,061h,0e1h,061h,0e1h,0e1h,0e1h,0e1h,0e1h,061h,0e1h,061h,0e1h,0e1h	; 704b  aa.a.a.....a.a..
	defb 0e1h,0e1h,0e1h,040h,0f1h,000h	; 705b

; ======================================================================
; CODIGO 0x7061..0x7096  (53 bytes)
; ======================================================================


L_7061:
	ld hl,07096h		;7061
	push hl			;7064
	ld hl,0e080h		;7065
	push hl			;7068
	ld b,040h		;7069
L_706B:
	ld (hl),000h		;706b
	inc hl			;706d
	djnz L_706B		;706e
	pop de			;7070
	pop hl			;7071
	ld bc,00040h		;7072
	ldir		;7075
	call L_7086		;7077
L_707A:
	ld bc,00040h		;707a
L_707D:
	ld hl,0e080h		;707d
	ld de,07b00h		;7080
	jp vuelca_bloque		;7083
L_7086:
	ld a,(0e002h)		;7086
	bit 7,a		;7089
	ld a,007h		;708b
	jr z,L_7091		;708d
	ld a,00ah		;708f
L_7091:
	ld hl,0e08fh		;7091
	ld (hl),a			;7094
	ret			;7095

; ----------------------------------------------------------------------
; DATOS sin identificar  0x7096..0x70d6  (64 bytes)
DATA_7096:
	defb 087h,040h,048h,00fh,097h,040h,050h,00fh,08fh,040h,04ch,009h,0a7h,040h,054h,007h	; 7096  .@H..@P..@L..@T.
	defb 0e0h,000h,000h,00fh,028h,01ch,014h,00fh,0e0h,0e0h,0e0h,00eh,0e0h,0e0h,0e0h,00eh	; 70a6  ....(...........
	defb 0e0h,0e0h,0e0h,00ah,0e0h,0e0h,0e0h,00ah,0e0h,0e0h,0e0h,008h,0e0h,0e0h,0e0h,008h	; 70b6  ................
	defb 0e0h,0e0h,0e0h,00ah,02ah,02ah,0ech,004h,02ah,051h,0ech,004h,02ah,082h,0ech,004h	; 70c6  ....**..*Q..*...

; ======================================================================
; CODIGO 0x70d6..0x7124  (78 bytes)
; ======================================================================


L_70D6:
	ld hl,0715ch		;70d6
	ld de,05800h		;70d9
	call L_43F2		;70dc
	ld hl,071d1h		;70df
	ld de,058a0h		;70e2
	call L_43F2		;70e5
	ld hl,072f3h		;70e8
	call descomprime		;70eb
	ld hl,01860h		;70ee
	ld de,01890h		;70f1
	ld c,001h		;70f4
	call copia_c_franjas		;70f6
L_70F9:
	ld hl,018c0h		;70f9
	ld de,01a50h		;70fc
	ld c,00ch		;70ff
	call copia_c_franjas		;7101
	ld hl,01bc0h		;7104
	ld de,01dd0h		;7107
	ld c,005h		;710a
	call copia_c_franjas_alternas		;710c
	ld hl,01d00h		;710f
	ld de,01ef0h		;7112
	ld c,004h		;7115
	call copia_c_franjas		;7117
	ret			;711a
L_711B:
	ld hl,0753bh		;711b
	call descomprime		;711e
	jp L_70F9		;7121

; ----------------------------------------------------------------------
; DATOS sin identificar  0x7124..0x715c  (56 bytes)
DATA_7124:
	defb 018h,020h,01ch,024h,018h,028h,01ch,02ch,018h,030h,01ch,034h,018h,038h,01ch,03ch	; 7124  . .$.(.,.0.4.8.<
	defb 018h,040h,01ch,03ch,018h,044h,01ch,03ch,048h,050h,04ch,054h,048h,058h,04ch,05ch	; 7134  .@.<.D.<HPLTHXL\
	defb 048h,060h,04ch,064h,048h,068h,04ch,06ch,048h,070h,04ch,06ch,048h,074h,04ch,06ch	; 7144  H`LdHhLlHpLlHtLl
	defb 018h,044h,01ch,02ch,018h,004h,000h,0f8h	; 7154  .D.,....

; ----------------------------------------------------------------------
; DATOS bloque_0x715C: 117 bytes comprimidos -> 128 en VRAM (1 tramos: ?); lo
;   carga 0x70D6
;   0x715c..0x71d1  (117 bytes)
DATA_bloque_0x715C:
	defb 006h,000h,08ah,00fh,01ch,01dh,01ch,00fh,01eh,01ch,01eh,00eh,00fh,006h,000h,0cfh	; 715c  ................
	defb 0f0h,098h,0dch,09ch,0f8h,03ch,01ch,03ch,03ch,0f8h,000h,000h,000h,020h,030h,0a1h	; 716c  .....<.<<.... 0.
	defb 083h,0c0h,0e0h,0e0h,0f7h,07bh,07bh,03ah,01bh,03bh,000h,000h,000h,002h,006h,0c2h	; 717c  .....{{:.;......
	defb 060h,000h,000h,000h,0d0h,0fch,01eh,0feh,01ch,0a2h,00fh,030h,0c0h,000h,007h,018h	; 718c  `..........0....
	defb 020h,000h,003h,00ch,000h,000h,003h,000h,000h,001h,0f0h,00ch,003h,000h,0e0h,018h	; 719c   ...............
	defb 004h,000h,0c0h,030h,000h,000h,0c0h,000h,000h,080h,020h,020h,042h,044h,084h,006h	; 71ac  ...0......  BD..
	defb 088h,085h,084h,044h,042h,020h,020h,004h,000h,088h,040h,040h,088h,089h,089h,088h	; 71bc  ...DB  ...@@....
	defb 040h,040h,004h,000h,000h	; 71cc

; ----------------------------------------------------------------------
; DATOS bloque_0x71D1: 290 bytes comprimidos -> 416 en VRAM (1 tramos: ?); lo
;   carga 0x70DF
;   0x71d1..0x72f3  (290 bytes)
DATA_bloque_0x71D1:
	defb 001h,000h,007h,00fh,020h,000h,084h,00fh,01fh,01fh,01bh,003h,007h,009h,000h,001h	; 71d1  .... ...........
	defb 078h,003h,0fch,003h,0f0h,008h,000h,089h,007h,00eh,01eh,03eh,036h,003h,019h,01fh	; 71e1  x..........>6...
	defb 007h,007h,000h,08ah,0f0h,0e0h,068h,048h,0cch,0dch,0f8h,0f0h,0f0h,001h,007h,000h	; 71f1  ......hH........
	defb 0a0h,0cfh,0dfh,07eh,03dh,07dh,0fbh,0fbh,0f7h,01ch,096h,0b4h,030h,020h,000h,000h	; 7201  ...~=}......0 ..
	defb 000h,0b0h,078h,0fch,0fch,0dch,0f8h,060h,0f0h,0ffh,07fh,03fh,00fh,003h,001h,001h	; 7211  ..x....`...?....
	defb 007h,008h,000h,088h,0f8h,0f8h,0f0h,0e0h,0c0h,0c0h,0e0h,080h,010h,000h,0a0h,087h	; 7221  ................
	defb 0bfh,07fh,03fh,00fh,03eh,07dh,07bh,08eh,04bh,05ah,018h,010h,000h,000h,000h,038h	; 7231  ..?.>}{.KZ.....8
	defb 07ch,0feh,0ffh,0ffh,0f9h,0fbh,0f0h,07fh,07fh,03fh,01fh,01fh,05eh,078h,030h,008h	; 7241  |........?..^x0.
	defb 000h,088h,0f8h,0fch,0fch,0feh,0ffh,05fh,003h,002h,008h,000h,001h,001h,007h,000h	; 7251  ......._........
	defb 09eh,00fh,0dfh,0feh,03eh,07dh,0fdh,0fbh,0f7h,01ch,096h,0b4h,030h,020h,000h,000h	; 7261  ....>}......0 ..
	defb 000h,090h,07ch,0feh,0feh,0ffh,0f7h,0e3h,0e6h,07fh,07fh,03fh,0bfh,0fch,060h,00ah	; 7271  ..|........?..`.
	defb 000h,087h,0f0h,0f8h,0fch,07ch,01ch,00ch,018h,009h,000h,001h,001h,007h,000h,09ch	; 7281  .....|..........
	defb 067h,06fh,03eh,03dh,03bh,077h,077h,06fh,01ch,096h,0b4h,030h,020h,000h,000h,000h	; 7291  go>=;wwo...0 ...
	defb 0b8h,07eh,0feh,0ffh,0f2h,0f2h,0f8h,0f8h,07fh,0bfh,0ffh,0e0h,00ch,000h,085h,0f8h	; 72a1  .~..............
	defb 0ffh,0ffh,07dh,039h,00bh,000h,001h,001h,007h,000h,08dh,0dfh,07fh,0bfh,01fh,00fh	; 72b1  ..}9............
	defb 03dh,07bh,077h,01ch,096h,0b4h,030h,020h,003h,000h,001h,0d0h,004h,0f0h,003h,0f8h	; 72c1  ={w...0 ........
	defb 0a0h,046h,042h,06eh,01ch,02fh,04fh,067h,07bh,03fh,03eh,01dh,03dh,07bh,0fbh,0fbh	; 72d1  .FBn./Og{?>.={..
	defb 0fbh,08eh,04bh,05ah,018h,010h,0c0h,0e0h,0f0h,0f0h,0f8h,0f8h,0f8h,0f8h,0f8h,0f0h	; 72e1  ..KZ............
	defb 0f0h,000h	; 72f1

; ----------------------------------------------------------------------
; DATOS sin identificar  0x72f3..0x799c  (1705 bytes)
DATA_72F3:
	defb 0c0h,05bh,0a3h,002h,003h,00fh,01fh,03bh,031h,021h,041h,0a9h,033h,05dh,003h,000h	; 72f3  .[.....;1!A.3]..
	defb 000h,001h,001h,020h,060h,0b0h,0f5h,0ffh,0f7h,0fbh,0f7h,0ffh,0cfh,0ffh,07fh,07fh	; 7303  ... `...........
	defb 0bch,030h,060h,000h,000h,07fh,008h,0ffh,0b8h,0dfh,08fh,003h,009h,016h,000h,000h	; 7313  .0`.............
	defb 000h,080h,0e0h,0b0h,0c8h,0dch,0e2h,0deh,0c2h,0dch,098h,000h,000h,000h,002h,003h	; 7323  ................
	defb 00fh,01fh,03bh,031h,021h,041h,0a9h,033h,05dh,003h,000h,003h,003h,00ch,020h,060h	; 7333  ..;1!A.3]..... `
	defb 0b0h,0f9h,0ffh,0f7h,0fbh,0f7h,0ffh,0cfh,0ffh,0ffh,07fh,09fh,00ch,018h,000h,000h	; 7343  ................
	defb 07eh,009h,0ffh,0b7h,0bfh,01eh,00ch,070h,000h,000h,000h,0c0h,0f0h,0ech,092h,0cfh	; 7353  ~......p........
	defb 0c1h,0cfh,0c1h,08eh,084h,040h,040h,000h,000h,002h,003h,00fh,01fh,03bh,031h,021h	; 7363  .....@@......;1!
	defb 040h,0a8h,030h,06dh,007h,003h,007h,001h,000h,020h,060h,0a8h,0f7h,0fbh,0f7h,0ffh	; 7373  @.0m..... `.....
	defb 0f7h,0efh,07fh,0ffh,0ffh,0e3h,008h,004h,000h,000h,03eh,009h,0ffh,0b6h,0f9h,0e0h	; 7383  ..........>.....
	defb 002h,004h,000h,000h,000h,080h,0e0h,0f8h,0d4h,0feh,0e2h,0deh,0e2h,0feh,0ech,070h	; 7393  ...............p
	defb 030h,010h,018h,02bh,03fh,07fh,07fh,0e3h,0c1h,041h,088h,060h,03ah,00eh,019h,01ch	; 73a3  0..+?....A.`:...
	defb 030h,020h,020h,070h,0f9h,0f7h,0fdh,09bh,00dh,00bh,0afh,09bh,077h,06fh,0bfh,01eh	; 73b3  0  p........wo..
	defb 008h,010h,000h,078h,00ah,0ffh,091h,09eh,007h,041h,082h,000h,000h,000h,080h,0e0h	; 73c3  ...x.....A......
	defb 070h,090h,078h,088h,078h,088h,070h,0c0h,007h,000h,08ch,005h,007h,00fh,01fh,01fh	; 73d3  p.x.x.p.........
	defb 03fh,03fh,01fh,0bbh,06bh,031h,01fh,004h,000h,08ch,080h,087h,0dfh,0ffh,0dfh,0bfh	; 73e3  ??..k1..........
	defb 0dfh,0bfh,0ffh,0ffh,0ffh,077h,005h,000h,08bh,080h,0e0h,0f0h,0f8h,0fch,0fch,0fdh	; 73f3  .....w..........
	defb 0feh,0feh,0f5h,0dbh,00ah,000h,086h,078h,0b6h,0dah,0dbh,0dbh,0b6h,005h,000h,08bh	; 7403  .......x........
	defb 080h,0e0h,0f0h,0f8h,0fch,0fdh,0fch,0ffh,0ffh,0f7h,0dch,006h,000h,0e6h,01eh,077h	; 7413  ...............w
	defb 0bbh,0dbh,0eeh,0ech,078h,0f0h,080h,000h,055h,03bh,07fh,0ffh,07fh,0ffh,0f7h,063h	; 7423  ....x...U;.....c
	defb 0c1h,069h,0b1h,0cdh,0e5h,062h,041h,020h,0ach,06eh,0f6h,0f6h,0fah,0fch,0bch,01eh	; 7433  .i...bA .n......
	defb 00eh,02eh,01ah,076h,04eh,08eh,00ch,018h,03ch,072h,06fh,05ch,05bh,016h,005h,003h	; 7443  ...vN...<ro\[...
	defb 001h,007h,01fh,03fh,03fh,07fh,07fh,077h,000h,000h,000h,000h,080h,080h,000h,080h	; 7453  ...??..w........
	defb 000h,0f0h,0f8h,0fch,0fch,0feh,0feh,0f6h,077h,07fh,07fh,03fh,03fh,01fh,007h,001h	; 7463  ........w..??...
	defb 003h,005h,016h,05bh,05ch,06fh,072h,03ch,0f6h,0feh,0feh,0fch,0fch,0f8h,0f0h,000h	; 7473  ...[\or<........
	defb 080h,000h,080h,080h,004h,000h,0a0h,018h,030h,071h,072h,06eh,058h,074h,070h,078h	; 7483  ........0qrnXtpx
	defb 03dh,03fh,05fh,06fh,06fh,076h,035h,004h,082h,046h,0a7h,0b3h,08dh,096h,083h,0c6h	; 7493  =?_oov5..F......
	defb 0efh,0ffh,0feh,0ffh,0feh,0dch,0aah,080h,000h,05fh,0a0h,05bh,05dh,03fh,07fh,0ffh	; 74a3  ........._.[]?..
	defb 0ffh,0f7h,063h,0c1h,069h,031h,04dh,065h,072h,061h,008h,0ach,06eh,0f6h,0f6h,0fah	; 74b3  ..c.i1Mera..n...
	defb 0fch,0bch,01eh,00ah,02eh,01ah,076h,04eh,08eh,00ch,008h,080h,060h,05fh,003h,0f0h	; 74c3  ......vN....`_..
	defb 01eh,000h,097h,001h,080h,0c3h,0c1h,0e6h,0ebh,0fdh,0ebh,0e0h,0e0h,0e0h,0c0h,080h	; 74d3  ................
	defb 000h,000h,000h,0e0h,070h,0b0h,0d0h,0d0h,060h,040h,00bh,000h,08dh,080h,0c0h,0e0h	; 74e3  ....p...`@......
	defb 0e0h,0e0h,0ebh,0fdh,0ebh,0e6h,0c1h,0c3h,080h,001h,009h,000h,08dh,040h,060h,0d0h	; 74f3  .............@`.
	defb 0d0h,0b0h,070h,0e0h,03fh,03fh,01ch,01eh,00eh,002h,00ah,000h,088h,0feh,0feh,0feh	; 7503  ..p.??..........
	defb 01eh,0fch,0fch,0f8h,0c0h,009h,000h,09fh,001h,001h,061h,03bh,01fh,00eh,01eh,07eh	; 7513  ..........a;...~
	defb 03eh,01fh,01eh,03fh,041h,000h,000h,000h,080h,083h,0ceh,0dch,0fch,0f8h,0f8h,0f0h	; 7523  >..?A...........
	defb 0f8h,0fch,0feh,0e0h,0c0h,080h,080h,000h,040h,018h,0a0h,000h,007h,00fh,01fh,03fh	; 7533  ........@......?
	defb 07fh,079h,070h,064h,060h,060h,060h,032h,031h,018h,000h,000h,0f0h,0f8h,0fch,0feh	; 7543  .ypd```21.......
	defb 0beh,03eh,00eh,026h,006h,006h,006h,04ch,08ch,018h,000h,0a0h,003h,00fh,01fh,01fh	; 7553  .>.&...L........
	defb 03fh,03fh,07fh,07fh,076h,076h,070h,070h,072h,079h,078h,07ch,0c0h,0f0h,0f8h,0f8h	; 7563  ??..vvppryx|....
	defb 0fch,0fch,0feh,0feh,06eh,06eh,00eh,00eh,04eh,09eh,01eh,03eh,0a0h,003h,00fh,01fh	; 7573  ....nn..N..>....
	defb 01fh,03fh,03eh,07eh,078h,076h,076h,060h,070h,072h,039h,038h,01ch,0e0h,0f8h,0fch	; 7583  .?>~xvv`pr98....
	defb 0fch,0feh,0feh,07eh,01eh,067h,06fh,007h,00fh,04eh,09eh,01eh,03ch,0a0h,000h,000h	; 7593  ...~.go..N..<...
	defb 000h,000h,000h,000h,000h,000h,000h,007h,01fh,03fh,03fh,07fh,07fh,07eh,000h,000h	; 75a3  .........??..~..
	defb 000h,000h,000h,000h,000h,000h,000h,0c0h,0f0h,0fch,0bch,09eh,00eh,00eh,0a0h,00fh	; 75b3  ................
	defb 01fh,01fh,01bh,007h,007h,007h,000h,000h,000h,000h,000h,000h,000h,000h,000h,078h	; 75c3  ...............x
	defb 0fch,0fch,0fch,0f0h,0f0h,0f0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0a0h	; 75d3  ................
	defb 007h,00eh,01eh,03eh,036h,003h,019h,01fh,007h,000h,000h,000h,000h,000h,000h,000h	; 75e3  ...>6...........
	defb 0f0h,0e0h,068h,048h,0cch,0dch,0f8h,0f0h,0f0h,000h,000h,000h,000h,000h,000h,000h	; 75f3  ..hH............
	defb 000h,0aeh,08eh,094h,094h,094h,094h,094h,094h,08ch,068h,0aeh,0c4h,0c4h,0c4h,0c4h	; 7603  ..........h.....
	defb 0c4h,0c4h,0c4h,08ch,068h,0a4h,0b1h,0b3h,0b3h,0b3h,0b4h,0c4h,0c4h,08ch,068h,000h	; 7613  ....h.........h.
	defb 0b2h,000h,000h,05dh,088h,0c4h,08fh,08ch,068h,000h,0beh,0a0h,000h,06bh,000h,000h	; 7623  ...]....h....k..
	defb 000h,0a3h,06ah,000h,000h,000h,000h,06bh,000h,000h,000h,000h,068h,000h,000h,000h	; 7633  ..j....k....h...
	defb 000h,06bh,000h,000h,000h,000h,068h,000h,000h,000h,000h,05ch,000h,000h,000h,0a1h	; 7643  .k....h....\....
	defb 068h,08ah,0bah,0c3h,0bah,0c4h,0c4h,0c4h,08fh,08ch,068h,0aeh,0b9h,0c3h,0b9h,0c4h	; 7653  h.........h.....
	defb 094h,094h,094h,08ch,068h,0aeh,0b9h,0c3h,0b9h,0c4h,094h,094h,094h,08ch,068h,0aeh	; 7663  ....h.........h.
	defb 0b9h,0c3h,0b9h,0c4h,094h,094h,094h,07ah,06dh,0aeh,0b9h,0c3h,0b9h,0c4h,094h,094h	; 7673  .......zm.......
	defb 094h,08ch,06eh,0aeh,0b9h,08eh,0b9h,0c4h,08fh,0c3h,0c3h,08ch,06fh,0aeh,0b9h,0c4h	; 7683  ..n.........o...
	defb 0b9h,08fh,0c2h,0c3h,0c2h,08ch,068h,0afh,0bbh,0c4h,0bbh,0c3h,0abh,0aah,0a8h,08ch	; 7693  ......h.........
	defb 068h,000h,000h,000h,0afh,0c3h,0ach,0c3h,0a9h,08ch,068h,000h,000h,000h,05dh,000h	; 76a3  h.........h...].
	defb 000h,000h,000h,0a3h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h	; 76b3  ....h...k.....h.
	defb 000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h	; 76c3  ..k.....h...k...
	defb 000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h	; 76d3  ..h...k.....h...
	defb 06bh,000h,000h,000h,000h,000h,069h,000h,000h,000h,06bh,000h,000h,000h,000h,000h	; 76e3  k.....i...k.....
	defb 06ah,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h	; 76f3  j...k.....h...k.
	defb 000h,000h,000h,000h,068h,000h,000h,000h,05ch,086h,0c3h,08eh,000h,0a1h,068h,000h	; 7703  ....h...\.....h.
	defb 000h,000h,08ah,092h,092h,092h,08eh,08ch,068h,08ah,0c3h,08eh,0c4h,0c4h,0c4h,0c4h	; 7713  ........h.......
	defb 08fh,08ch,068h,0aeh,098h,09ah,09ah,09ah,09ah,09ah,09eh,08ch,070h,0aeh,099h,09bh	; 7723  ..h.........p...
	defb 09bh,09bh,09bh,09bh,09fh,08ch,071h,0aeh,0c4h,0c4h,0c4h,0c4h,08fh,0c3h,0c3h,08ch	; 7733  ......q.........
	defb 072h,0aeh,0c4h,0c0h,0c0h,0c1h,0c3h,0c3h,0c3h,08ch,073h,0aeh,0c4h,0c4h,08fh,0c3h	; 7743  r.........s.....
	defb 0c2h,0c3h,0c2h,08ch,074h,0aeh,0c4h,0c1h,0bch,0bch,0abh,0aah,0a8h,08ch,068h,0afh	; 7753  ....t.........h.
	defb 08fh,0c3h,0c3h,0c3h,0ach,0c3h,0a9h,08ch,068h,000h,000h,000h,05dh,000h,000h,000h	; 7763  ........h...]...
	defb 000h,0a3h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h	; 7773  ..h...k.....h...
	defb 06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h	; 7783  k.....h...k.....
	defb 068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h	; 7793  h...k.....h...k.
	defb 000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,069h,000h	; 77a3  ....h...k.....i.
	defb 000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h	; 77b3  ..k.....h...k...
	defb 000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h	; 77c3  ..h...k.....h...
	defb 06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h	; 77d3  k.....h...k.....
	defb 069h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,06ah,000h,000h,000h,06bh,000h	; 77e3  i...k.....j...k.
	defb 000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h	; 77f3  ....h...k.....h.
	defb 000h,000h,05ch,000h,000h,000h,000h,0a1h,068h,08ah,08eh,0c4h,0c4h,093h,0c4h,0c4h	; 7803  ..\.....h.......
	defb 08fh,08ch,068h,0aeh,080h,083h,083h,093h,094h,094h,094h,08ch,068h,0aeh,081h,087h	; 7813  ..h.........h...
	defb 0a5h,093h,094h,094h,094h,08ch,075h,0aeh,081h,087h,0a5h,093h,0c4h,0c4h,08fh,08ch	; 7823  ......u.........
	defb 076h,0aeh,081h,087h,0a5h,093h,094h,094h,094h,08ch,077h,0aeh,081h,087h,0a5h,093h	; 7833  v.........w.....
	defb 090h,091h,0c3h,08ch,078h,0aeh,081h,087h,0a5h,08bh,0c2h,0c3h,0c2h,08ch,079h,0afh	; 7843  ....x.........y.
	defb 082h,083h,083h,08bh,0abh,0aah,0a8h,08ch,068h,000h,000h,000h,05dh,08dh,0ach,0c3h	; 7853  ........h...]...
	defb 0a9h,08ch,068h,000h,000h,000h,06bh,000h,000h,000h,000h,0a3h,068h,000h,000h,000h	; 7863  ..h...k.....h...
	defb 06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h	; 7873  k.....h...k.....
	defb 068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h	; 7883  h...k.....h...k.
	defb 000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,069h,000h	; 7893  ....h...k.....i.
	defb 000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h	; 78a3  ..k.....h...k...
	defb 000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h	; 78b3  ..h...k.....h...
	defb 06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h	; 78c3  k.....h...k.....
	defb 068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,069h,000h,000h,000h,06bh,000h	; 78d3  h...k.....i...k.
	defb 000h,000h,000h,000h,068h,000h,000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h	; 78e3  ....h...k.....h.
	defb 000h,000h,06bh,000h,000h,000h,000h,000h,068h,000h,000h,000h,05ch,000h,000h,000h	; 78f3  ..k.....h...\...
	defb 000h,0a1h,068h,000h,08ah,0c3h,0c3h,08eh,0c4h,0c4h,08fh,08ch,068h,000h,0aeh,094h	; 7903  ..h.........h...
	defb 084h,095h,0c4h,094h,094h,08ch,068h,000h,0aeh,0c3h,085h,096h,09dh,0c4h,08fh,08ch	; 7913  ......h.........
	defb 068h,000h,0aeh,094h,085h,097h,09dh,094h,094h,08ch,068h,000h,0a2h,0bdh,085h,09ch	; 7923  h.........h.....
	defb 09dh,08fh,0c3h,08ch,068h,000h,000h,000h,0a3h,09ch,0bfh,000h,000h,0a3h,068h,000h	; 7933  ....h.........h.
	defb 000h,000h,000h,09ch,000h,067h,066h,065h,068h,000h,000h,000h,000h,060h,060h,060h	; 7943  .....gfeh....```
	defb 060h,064h,068h,000h,000h,000h,000h,062h,062h,062h,062h,063h,068h,000h,000h,000h	; 7953  `dh....bbbbch...
	defb 000h,062h,062h,062h,062h,063h,068h,000h,000h,000h,000h,062h,062h,062h,062h,063h	; 7963  .bbbbch....bbbbc
	defb 068h,000h,000h,000h,000h,062h,062h,062h,062h,063h,068h,000h,000h,000h,000h,061h	; 7973  h....bbbbch....a
	defb 061h,061h,061h,064h,068h,000h,000h,000h,000h,000h,000h,000h,000h,000h,068h,000h	; 7983  aaadh.........h.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,068h	; 7993  ........h

; ======================================================================
; CODIGO 0x799c..0x7b5e  (450 bytes)
; ======================================================================


L_799C:
	di			;799c
	push hl			;799d
	push de			;799e
	push bc			;799f
	push af			;79a0
	ld d,000h		;79a1
	call L_79AC		;79a3
	pop af			;79a6
	pop bc			;79a7
	pop de			;79a8
	pop hl			;79a9
	ei			;79aa
	ret			;79ab
L_79AC:
	ld c,a			;79ac
	ld b,002h		;79ad
	ld hl,0e012h		;79af
	cp 089h		;79b2
	jr c,L_79BD		;79b4
	cp 08dh		;79b6
	jr c,L_79CA		;79b8
	inc b			;79ba
	jr L_79CA		;79bb
L_79BD:
	and 03fh		;79bd
	dec b			;79bf
	ld hl,0e012h		;79c0
	cp 016h		;79c3
	jr z,L_79CA		;79c5
	ld hl,0e028h		;79c7
L_79CA:
	dec d			;79ca
	jr z,L_79D6		;79cb
	ld a,c			;79cd
	cp (hl)			;79ce
	ret c			;79cf
	cp 096h		;79d0
	jr c,L_79D6		;79d2
	and 07fh		;79d4
L_79D6:
	ld c,a			;79d6
	and 03fh		;79d7
	add a,a			;79d9
	ld de,07b68h		;79da
	call suma_a_a_de		;79dd
	dec hl			;79e0
	dec hl			;79e1
L_79E2:
	ld (hl),001h		;79e2
	inc hl			;79e4
	ld (hl),001h		;79e5
	inc hl			;79e7
	ld (hl),c			;79e8
	inc hl			;79e9
	ld a,(de)			;79ea
	ld (hl),a			;79eb
	inc hl			;79ec
	inc de			;79ed
	ld a,(de)			;79ee
	ld (hl),a			;79ef
	ld a,006h		;79f0
	add a,l			;79f2
	ld l,a			;79f3
	ld (hl),000h		;79f4
	inc hl			;79f6
	inc de			;79f7
	djnz L_79E2		;79f8
	ret			;79fa
L_79FB:
	inc hl			;79fb
	ld a,(ix+009h)		;79fc
	inc a			;79ff
	cp (hl)			;7a00
	jp z,L_7AB0		;7a01
	jr c,L_7A07		;7a04
	dec a			;7a06
L_7A07:
	ex af,af'			;7a07
	ld a,(ix+002h)		;7a08
	push bc			;7a0b
	ld d,001h		;7a0c
	call L_79AC		;7a0e
	pop bc			;7a11
	ex af,af'			;7a12
	ld (ix+009h),a		;7a13
	ret			;7a16
L_7A17:
	ret			;7a17
L_7A18:
	ld a,007h		;7a18
	call 00096h		;7a1a   ; BIOS RDPSG - Reads value from PSG-register
	and 0b8h		;7a1d
	ld e,a			;7a1f
	ld a,007h		;7a20
	call 00093h		;7a22   ; BIOS WRTPSG - Writes data to PSG-register
	ld c,001h		;7a25
	ld ix,0e010h		;7a27
	exx			;7a2b
	ld b,003h		;7a2c
	ld de,0000bh		;7a2e
L_7A31:
	exx			;7a31
	ld a,(ix+002h)		;7a32
	or a			;7a35
	call nz,L_7A41		;7a36
	inc c			;7a39
	inc c			;7a3a
	exx			;7a3b
	add ix,de		;7a3c
	djnz L_7A31		;7a3e
	ret			;7a40
L_7A41:
	bit 6,a		;7a41
	ld d,001h		;7a43
	call z,L_7A17		;7a45
	ld a,(ix+002h)		;7a48
	or a			;7a4b
	jp m,L_7AC0		;7a4c
	dec (ix+000h)		;7a4f
	ret nz			;7a52
L_7A53:
	ld l,(ix+003h)		;7a53
	ld h,(ix+004h)		;7a56
	ld a,(hl)			;7a59
	cp 0feh		;7a5a
	jr z,L_79FB		;7a5c
	jr nc,L_7AB0		;7a5e
	bit 7,(ix+002h)		;7a60
	jp nz,L_7AEB		;7a64
	and 0f0h		;7a67
	cp 020h		;7a69
	jr nz,L_7A74		;7a6b
	ld a,(hl)			;7a6d
	and 00fh		;7a6e
	ld (ix+001h),a		;7a70
	inc hl			;7a73
L_7A74:
	ld a,(hl)			;7a74
	and 0f0h		;7a75
	cp 010h		;7a77
	jr nz,L_7A8B		;7a79
	ld a,(hl)			;7a7b
	and 01fh		;7a7c
	ld e,a			;7a7e
	ld a,006h		;7a7f
	call 00093h		;7a81   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;7a84
	call L_7A17		;7a86
	inc hl			;7a89
	ld a,(hl)			;7a8a
L_7A8B:
	and 0f0h		;7a8b
	ld b,a			;7a8d
	xor (hl)			;7a8e
	ld d,a			;7a8f
	inc hl			;7a90
	ld e,(hl)			;7a91
	inc hl			;7a92
	ld (ix+003h),l		;7a93
	ld (ix+004h),h		;7a96
	ex de,hl			;7a99
	call L_7B52		;7a9a
	ld a,b			;7a9d
	rrca			;7a9e
	rrca			;7a9f
	rrca			;7aa0
	rrca			;7aa1
L_7AA2:
	ld h,a			;7aa2
	ld a,(ix+001h)		;7aa3
	ld (ix+000h),a		;7aa6
	add a,004h		;7aa9
	ld (ix+008h),a		;7aab
	jr L_7AE2		;7aae
L_7AB0:
	xor a			;7ab0
	ld (ix+009h),a		;7ab1
	ld d,001h		;7ab4
	call L_7A17		;7ab6
	xor a			;7ab9
	ld (ix+002h),a		;7aba
	ld h,a			;7abd
	jr L_7AE2		;7abe
L_7AC0:
	dec (ix+000h)		;7ac0
	jp z,L_7A53		;7ac3
	dec (ix+008h)		;7ac6
	ld a,(ix+008h)		;7ac9
	cp (ix+000h)		;7acc
	jr nz,L_7AD6		;7acf
	cp 004h		;7ad1
	jr c,L_7AD9		;7ad3
	ret			;7ad5
L_7AD6:
	dec (ix+008h)		;7ad6
L_7AD9:
	ld a,(ix+007h)		;7ad9
	dec a			;7adc
	ret m			;7add
	ld (ix+007h),a		;7ade
	ld h,a			;7ae1
L_7AE2:
	ld e,h			;7ae2
	ld a,c			;7ae3
	rrca			;7ae4
	add a,088h		;7ae5
	call 00093h		;7ae7   ; BIOS WRTPSG - Writes data to PSG-register
	ret			;7aea
L_7AEB:
	and 0f0h		;7aeb
	cp 0d0h		;7aed
	ld a,(hl)			;7aef
	jr nz,L_7AF9		;7af0
	and 00fh		;7af2
	ld (ix+00ah),a		;7af4
	inc hl			;7af7
	ld a,(hl)			;7af8
L_7AF9:
	cp 0f0h		;7af9
	jr c,L_7B04		;7afb
	and 00fh		;7afd
	ld (ix+006h),a		;7aff
	inc hl			;7b02
	ld a,(hl)			;7b03
L_7B04:
	cp 0e0h		;7b04
	jr c,L_7B0F		;7b06
	and 00fh		;7b08
	ld (ix+005h),a		;7b0a
	inc hl			;7b0d
	ld a,(hl)			;7b0e
L_7B0F:
	and 00fh		;7b0f
	ld b,a			;7b11
	ld a,(ix+00ah)		;7b12
	jr z,L_7B1C		;7b15
L_7B17:
	add a,(ix+00ah)		;7b17
	djnz L_7B17		;7b1a
L_7B1C:
	ld (ix+001h),a		;7b1c
	ld a,(hl)			;7b1f
	inc hl			;7b20
	ld (ix+003h),l		;7b21
	ld (ix+004h),h		;7b24
	and 0f0h		;7b27
	rrca			;7b29
	rrca			;7b2a
	rrca			;7b2b
	rrca			;7b2c
	ld b,a			;7b2d
	sub 00ch		;7b2e
	ld (ix+007h),a		;7b30
	jr z,L_7B3B		;7b33
	ld a,(ix+006h)		;7b35
	ld (ix+007h),a		;7b38
L_7B3B:
	call L_7AA2		;7b3b
	ld a,b			;7b3e
	ld hl,07b5eh		;7b3f
	call suma_a_a_hl		;7b42
	ld l,(hl)			;7b45
	ld h,000h		;7b46
	ld a,(ix+005h)		;7b48
	or a			;7b4b
	jr z,L_7B52		;7b4c
	ld b,a			;7b4e
L_7B4F:
	add hl,hl			;7b4f
	djnz L_7B4F		;7b50
L_7B52:
	ld a,c			;7b52
	ld e,h			;7b53
	call 00093h		;7b54   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;7b57
	dec a			;7b58
	ld e,l			;7b59
	call 00093h		;7b5a   ; BIOS WRTPSG - Writes data to PSG-register
	ret			;7b5d

; ----------------------------------------------------------------------
; DATOS escala_cromatica: los doce periodos
;   0x7b5e..0x7b6a  (12 bytes)
DATA_escala_cromatica:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 7b5e  jd_YTPKGC?<8

; ----------------------------------------------------------------------
; DATOS tabla_de_sonidos: 28 punteros
;   0x7b6a..0x7ba2  (56 bytes)
DATA_tabla_de_sonidos:
	defw 07ba2h,07bcdh,07bf5h,07c19h,07c3bh,07bafh,07c08h,07be3h	; 7b6a
	defw 07d93h,07de3h,07e43h,07e9ch,07c45h,07c73h,07c93h,07cb7h	; 7b7a
	defw 07ce8h,07d1eh,07d38h,07d5fh,07d77h,07ee9h,07d92h,07d92h	; 7b8a
	defw 07c2ah,07d92h,07d92h,07d92h	; 7b9a

; ----------------------------------------------------------------------
; DATOS partituras: los sonidos a los que apunta la tabla
;   0x7ba2..0x7ef4  (850 bytes)
DATA_partituras:
	defb 023h,0e0h,09ch,021h,0c0h,06ch,0b0h,063h,0a0h,05ch,090h,059h,0ffh,022h,0e0h,077h	; 7ba2  #..!.l.c.\.Y.".w
	defb 0e0h,044h,0d0h,077h,0d0h,044h,0c0h,077h,0c0h,044h,0b0h,077h,0b0h,044h,0a0h,077h	; 7bb2  .D.w.D.w.D.w.D.w
	defb 0a0h,044h,090h,077h,090h,044h,080h,077h,080h,044h,0ffh,022h,0e0h,099h,0e0h,055h	; 7bc2  .D.w.D.w.D."...U
	defb 0d0h,099h,0d0h,055h,0c0h,099h,0c0h,055h,0b0h,099h,0b0h,055h,0a0h,099h,0a0h,055h	; 7bd2  ...U...U...U...U
	defb 0ffh,024h,0c1h,01dh,0c0h,0d5h,0c0h,0a9h,0c0h,08eh,0c1h,01dh,0c0h,0d5h,0c0h,0a9h	; 7be2  .$..............
	defb 0c0h,08eh,0ffh,021h,0e0h,05ch,0e0h,061h,0e0h,06fh,022h,0e0h,072h,0b0h,078h,028h	; 7bf2  ...!.\.a.o".r.x(
	defb 090h,084h,02fh,070h,088h,0ffh,023h,0d0h,0aeh,0e0h,0e0h,0f1h,029h,0e1h,06eh,0d1h	; 7c02  ../p..#.....).n.
	defb 0a5h,0d1h,0e2h,02eh,0b2h,060h,0ffh,023h,0d1h,0eeh,0e1h,0a9h,0f1h,060h,0e1h,02eh	; 7c12  .....`.#.....`..
	defb 0d1h,005h,0d0h,0f1h,02eh,0b0h,0e4h,0ffh,022h,0d1h,0eeh,0d1h,0cch,0c1h,0eeh,0b1h	; 7c22  ........".......
	defb 0ffh,0a1h,099h,021h,091h,088h,081h,077h,0ffh,021h,0f1h,072h,0c1h,060h,0b1h,056h	; 7c32  ...!...w.!.r.`.V
	defb 0a1h,04fh,0ffh,0d6h,0fdh,0e1h,071h,071h,070h,040h,000h,040h,071h,071h,070h,040h	; 7c42  .O....qqp@.@qqp@
	defb 000h,040h,052h,050h,042h,040h,021h,021h,020h,020h,040h,050h,0d6h,071h,071h,070h	; 7c52  .@RPB@!!  @P.qqp
	defb 040h,000h,040h,071h,071h,070h,040h,000h,040h,052h,050h,042h,040h,021h,021h,003h	; 7c62  @.@qqp@.@RPB@!!.
	defb 0ffh,0d6h,0fdh,0e2h,071h,071h,071h,071h,071h,071h,071h,071h,023h,043h,0e3h,0b3h	; 7c72  ....qqqqqqqq#C..
	defb 0b0h,0c2h,0e2h,071h,071h,071h,071h,071h,071h,071h,071h,073h,073h,051h,051h,043h	; 7c82  ...qqqqqqqqssQQC
	defb 0ffh,0d6h,0fdh,0e2h,041h,041h,041h,041h,041h,041h,041h,041h,0e3h,0b3h,0e2h,003h	; 7c92  ....AAAAAAAA....
	defb 0e3h,073h,070h,0c2h,0e2h,041h,041h,041h,041h,041h,041h,041h,041h,023h,043h,0e3h	; 7ca2  .sp..AAAAAAAA#C.
	defb 0b1h,0b1h,0e2h,003h,0ffh,0d4h,0fch,0e1h,043h,041h,051h,073h,073h,093h,093h,071h	; 7cb2  ........CAQss..q
	defb 051h,041h,0c1h,043h,041h,051h,073h,073h,093h,093h,071h,051h,041h,021h,0d1h,0c0h	; 7cc2  QA.CAQss..qQA!..
	defb 0d4h,043h,041h,021h,003h,003h,023h,023h,041h,021h,003h,073h,071h,051h,043h,043h	; 7cd2  .CA!..##A!.sqQCC
	defb 021h,051h,041h,021h,003h,0ffh,0d4h,0fch,0e3h,001h,071h,041h,071h,001h,071h,041h	; 7ce2  !QA!......qAq.qA
	defb 071h,001h,091h,051h,091h,001h,071h,041h,071h,001h,071h,041h,071h,001h,071h,041h	; 7cf2  q..Q..qAq.qAq.qA
	defb 071h,001h,091h,051h,091h,001h,071h,041h,071h,0d1h,0c0h,0d4h,073h,073h,073h,073h	; 7d02  q..Q..qAq...ssss
	defb 073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,0ffh,0d4h,0fch,0e3h,0cfh	; 7d12  sssssssssss.....
	defb 0cfh,0cfh,0cfh,0d1h,0c0h,0d4h,043h,043h,043h,043h,023h,023h,043h,043h,043h,043h	; 7d22  ......CCCC##CCCC
	defb 043h,043h,023h,023h,042h,0ffh,0d3h,0fch,0e2h,053h,001h,001h,053h,001h,001h,053h	; 7d32  CC##B....S..S..S
	defb 093h,0e1h,005h,001h,0e2h,073h,021h,021h,073h,021h,021h,073h,0a3h,0e1h,027h,001h	; 7d42  .....s!!s!!s..'.
	defb 0e2h,0a1h,091h,071h,0a1h,091h,071h,051h,023h,043h,053h,0c3h,0ffh,0d3h,0fch,0e3h	; 7d52  ...q..qQ#CS.....
	defb 093h,093h,093h,093h,097h,095h,0c1h,093h,093h,093h,093h,093h,0a3h,0a7h,097h,097h	; 7d62  ................
	defb 0a3h,0a3h,093h,0c3h,0ffh,0d3h,0fch,0e3h,053h,053h,053h,053h,057h,055h,0c1h,053h	; 7d72  ........SSSSWU.S
	defb 053h,053h,053h,053h,003h,0e4h,0a7h,0e3h,057h,057h,0e4h,0a3h,0e3h,003h,053h,0c3h	; 7d82  SSSS....WW....S.
	defb 0ffh,0d6h,0fch,0e1h,001h,001h,021h,041h,000h,000h,041h,021h,0e2h,071h,0e1h,001h	; 7d92  ......!A..A!.q..
	defb 001h,021h,041h,003h,0e2h,0b1h,071h,0e1h,001h,001h,021h,041h,051h,041h,021h,001h	; 7da2  .!A...q...!AQA!.
	defb 0e2h,0b1h,071h,091h,0b1h,0e1h,001h,001h,003h,0e2h,092h,0b0h,091h,071h,091h,0b1h	; 7db2  ..q..........q..
	defb 0e1h,001h,0e2h,091h,072h,090h,071h,051h,041h,051h,073h,092h,0b0h,091h,071h,091h	; 7dc2  ....r.qQAQs...q.
	defb 0b1h,0e1h,001h,0e2h,091h,071h,0e1h,001h,0e2h,0b1h,0e1h,021h,003h,0c3h,0feh,0ffh	; 7dd2  .....q.....!....
	defb 0ffh,0d6h,0fch,0e3h,001h,071h,041h,071h,001h,071h,0e4h,071h,0e3h,071h,001h,071h	; 7de2  .....qAq.q.q.q.q
	defb 041h,071h,001h,071h,0e4h,071h,0e3h,071h,001h,071h,0e4h,0b1h,0e3h,001h,0e4h,051h	; 7df2  Aq.q.q.q.q.....Q
	defb 0e3h,091h,0e4h,0b1h,091h,071h,0e3h,071h,0e4h,091h,0b1h,0e3h,001h,071h,003h,0e4h	; 7e02  .....q.q.....q..
	defb 052h,0e3h,090h,001h,091h,0e4h,051h,0e3h,091h,001h,091h,002h,070h,041h,071h,001h	; 7e12  R.....Q.....pAq.
	defb 001h,021h,041h,0e4h,052h,0e3h,090h,001h,091h,0e4h,051h,0e3h,091h,001h,091h,001h	; 7e22  .!A.R.....Q.....
	defb 071h,0e4h,071h,0e3h,071h,001h,0e4h,071h,0e4h,003h,0feh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e32  q.q.q..q........
	defb 0ffh,0d3h,0fch,0e2h,043h,073h,093h,073h,043h,073h,0e1h,003h,003h,0e2h,093h,093h	; 7e42  ....Cs.sCs......
	defb 073h,043h,003h,023h,043h,0c3h,043h,073h,093h,073h,043h,073h,0e1h,003h,003h,0e2h	; 7e52  sC.#C.Cs.sCs....
	defb 093h,093h,073h,043h,023h,043h,003h,0c3h,023h,043h,023h,073h,093h,093h,073h,093h	; 7e62  ..sC#C..#C#s..s.
	defb 0e1h,003h,003h,0e2h,0b3h,093h,073h,073h,043h,0c3h,043h,073h,093h,073h,043h,073h	; 7e72  ......ssC.Cs.sCs
	defb 0e1h,003h,003h,0e2h,093h,093h,073h,043h,023h,043h,003h,0c3h,023h,043h,003h,0c3h	; 7e82  ......sC#C..#C..
	defb 023h,043h,073h,073h,073h,053h,043h,003h,0feh,0ffh,0d3h,0fch,0e2h,003h,043h,003h	; 7e92  #CsssSC.......C.
	defb 043h,003h,043h,003h,043h,003h,053h,003h,043h,003h,043h,003h,073h,003h,043h,003h	; 7ea2  C.C.C.S.C.C.s.C.
	defb 043h,003h,043h,003h,043h,003h,053h,003h,043h,0e3h,0b3h,0e2h,023h,003h,003h,07fh	; 7eb2  C.C.C.S.C...#...
	defb 057h,047h,05fh,047h,003h,043h,003h,043h,003h,043h,003h,043h,003h,043h,003h,053h	; 7ec2  WG_G.C.C.C.C.C.S
	defb 003h,043h,0e3h,0b3h,0e2h,023h,003h,003h,077h,003h,0c3h,003h,043h,003h,043h,0e3h	; 7ed2  .C...#..w...C.C.
	defb 0b3h,0e2h,023h,003h,073h,0feh,0ffh,021h,0b0h,02ch,0a0h,020h,0b0h,069h,0a0h,072h	; 7ee2  ..#.s..!.,. .i.r
	defb 0feh,016h	; 7ef2

; ----------------------------------------------------------------------
; DATOS relleno_final: 268 bytes de 0xFF hasta el final del cartucho
;   0x7ef4..0x8000  (268 bytes)
DATA_relleno_final:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ef4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f04  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f14  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f24  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f34  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f44  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f54  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f64  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f74  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f84  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f94  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fa4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fb4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fc4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fd4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fe4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ff4  ............
