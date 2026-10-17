# omsx_partida.tcl - Cuadros de PARTIDA de Comic Bakery: RAM y VRAM.
#
# Arranca una partida pulsando espacio en el menu, escribe la fase de
# work/fase.txt en (0xE051) justo despues de que la escena 5 la ponga a cero
# (0x4193), antes de que se monte la pantalla, y vuelca en el cuadro de la
# partida (0x48CE) de los cuadros que diga CUADROS. Sin tocar el mando: el
# panadero se queda donde sale y lo que se ve es lo que se mueve solo.
#
#   echo 1 > work/fase.txt
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart comicbakery.rom -script tools/omsx_partida.tcl
#
# Deja en work/partida/ faseN_cK.vram (16 KB) y faseN_cK.ram (0xE000..0xE3FF),
# y el registro en work/partida/log.txt.

set ::RAIZ {C:/Users/Antxiko/Documents/DES_ASM/desensamblados/COMICBAKERY_DISAM}
set ::FASE 0
catch {
    set f [open $::RAIZ/work/fase.txt r]
    set ::FASE [string trim [read $f]]
    close $f
}
set ::SALIDA $::RAIZ/work/partida
file mkdir $::SALIDA
set ::CUADROS {1 50 200 400 800 1200 1600 2400}
set ::cuadro 0
set ::LOG [open $::SALIDA/log.txt w]

proc apunta {texto} {
    puts $::LOG "[machine_info time] $texto"
    flush $::LOG
}

proc vuelca {nombre} {
    set f [open $::SALIDA/$nombre.vram w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block VRAM 0 16384]
    close $f
    set f [open $::SALIDA/$nombre.ram w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block memory 0xE000 1024]
    close $f
    apunta "volcado $nombre"
}

proc fuerza_la_fase {} {
    debug write memory 0xE051 $::FASE
    apunta "fase $::FASE escrita en 0xE051"
}

proc cuadro_de_partida {} {
    incr ::cuadro
    if {[lsearch $::CUADROS $::cuadro] >= 0} {
        vuelca [format {fase%d_c%04d} $::FASE $::cuadro]
    }
    if {$::cuadro >= [lindex $::CUADROS end]} {
        after time 0.1 exit
    }
}

# un error dentro de la orden de un punto de ruptura PARA la emulacion: se
# apunta y se sale, para no dejar el juego congelado
proc seguro {orden} {
    if {[catch $orden error]} { apunta "ERROR en $orden: $error"; exit }
}

set throttle off
debug set_bp 0x4196 {} {seguro fuerza_la_fase}
debug set_bp 0x48CE {} {seguro cuadro_de_partida}

proc pulsa {} {
    keymatrixdown 8 0x01
    after time 0.4 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
}
after time 16.0 { pulsa }
after time 18.0 { pulsa }
after time 20.0 { pulsa }
after time 200.0 { apunta {SIN ACABAR a los 200 s}; exit }
after realtime 300 { apunta {PERRO GUARDIAN a los 300 s reales}; exit }
