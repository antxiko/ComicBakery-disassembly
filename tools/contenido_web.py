#!/usr/bin/env python3
"""EL CONTENIDO de la web de Comic Bakery: lo unico que es de este juego.

md2html.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui. Asi no se puede colar el texto de otro
cartucho al copiar la maquinaria, que es como se colaban otras veces.

Todas las cifras de aqui estan medidas sobre este cartucho, con las
herramientas de tools/, y no copiadas de ningun otro proyecto.
"""

NOMBRE = "Comic Bakery"
CATALOGO = "RC-714"
ANIO = 1984

# El pie legal de cada pagina. El cartucho no lleva la marca oculta de la casa
# (tools/busca_marca_konami.py: sin marca en los 16384 bytes).
PIE_LEGAL = {
    "es": "<em>Comic Bakery</em> lo publico Konami para MSX en 1984; su numero "
          "de catalogo es RC-714 y son 16 KB. Todos los derechos sobre el juego "
          "siguen siendo de sus titulares. Este trabajo es de preservacion, "
          "estudio y documentacion, y la imagen del cartucho no se distribuye.",
    "en": "<em>Comic Bakery</em> was published by Konami for the MSX in 1984; "
          "its catalogue number is RC-714 and it is 16 KB. All rights in the "
          "game remain with their holders. This is preservation, study and "
          "documentation work, and the cartridge image is not distributed.",
}


GALERIA = [
    ("jugador.png",
     "El panadero en sus catorce poses: cuatro sprites cada una, desde las "
     "tablas de 0x7124 y 0x7096.",
     "The baker's fourteen poses: four sprites each, from the tables at "
     "0x7124 and 0x7096."),
    ("enemigos.png",
     "Los tres mapaches, en sus tres pasos hacia cada lado (0x51D9).",
     "The three raccoons, in their three steps each way (0x51D9)."),
    ("panaderia-fases-1-2-4.png",
     "La panaderia de las fases 1, 2, 4, 6...: las 92 columnas de 0x7604.",
     "The bakery on stages 1, 2, 4, 6...: the 92 columns at 0x7604."),
    ("panaderia-fases-3-5-7.png",
     "La de las fases 3, 5, 7...: el mismo mapa con los otros bloques.",
     "The one on stages 3, 5, 7...: the same map with the other blocks."),
    ("pantalla-presentacion.png",
     "La pantalla de la casa, montada desde la ROM y cotejada a 0 bytes.",
     "The company screen, built from the ROM and checked down to 0 bytes."),
    ("pantalla-titulo.png",
     "La de titulo, montada igual y cotejada a 0 bytes.",
     "The title screen, built the same way and checked down to 0 bytes."),
    ("sprites.png",
     "Los 64 patrones de sprite, como los deja 0x70D6.",
     "The 64 sprite patterns, as 0x70D6 leaves them."),
    ("tiles.png",
     "Los patrones del primer tercio de la pantalla.",
     "The patterns of the screen's first third."),
]

REPOSITORIO = 'https://github.com/antxiko/ComicBakery-disassembly'
CODIGO = 8097
COMENTARIOS = 2073
DATOS = 8287
DENSIDAD = '46,9'
DENSIDAD_EN = '46.9'
ESTILO = '\n:root{--tinta:#cfd0d4;--suave:#83868f;--fondo:#000;--panel:#0c0e13;--linea:#23262e;\n  --rojo:#ff897d;--cyan:#65dbef;--verde:#3eb849;--oro:#ded087}\n@media (prefers-color-scheme:light){:root{--tinta:#191a1e;--suave:#5a5d66;--fondo:#e9e7e1;\n  --panel:#f7f6f2;--linea:#d0cdc5;--rojo:#b23f34;--cyan:#1c6b7c;--verde:#2b7734;--oro:#8a7420}}\n:root[data-theme="dark"]{--tinta:#cfd0d4;--suave:#83868f;--fondo:#000;--panel:#0c0e13;\n  --linea:#23262e;--rojo:#ff897d;--cyan:#65dbef;--verde:#3eb849;--oro:#ded087}\n:root[data-theme="light"]{--tinta:#191a1e;--suave:#5a5d66;--fondo:#e9e7e1;--panel:#f7f6f2;\n  --linea:#d0cdc5;--rojo:#b23f34;--cyan:#1c6b7c;--verde:#2b7734;--oro:#8a7420}\n*{box-sizing:border-box}\nbody{margin:0;background:var(--fondo);color:var(--tinta);padding:0 1.25rem 6rem;\n  font:15px/1.7 ui-monospace,"SF Mono",Menlo,Consolas,monospace}\n.w{max-width:1120px;margin:0 auto}\n.n{max-width:68ch}\nh1,h2,h3,h4{font-weight:400;text-wrap:balance}\na{color:var(--cyan)}\nimg{image-rendering:pixelated;max-width:100%;height:auto;display:block}\nheader.top{display:flex;flex-direction:column;align-items:center;gap:1.5rem;\n  padding:4rem 0 2rem;text-align:center}\nheader.top img{width:min(100%,642px)}\n.claim{max-width:60ch;color:var(--suave);font-size:1.05rem}\n.claim b{color:var(--tinta);font-weight:400}\n.ficha{display:flex;flex-wrap:wrap;justify-content:center;gap:0 1.5rem;width:100%;\n  font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--suave);\n  border-top:1px solid var(--linea);border-bottom:1px solid var(--linea);padding:.85rem 0}\n.ficha b{color:var(--rojo);font-weight:400}\nnav{display:flex;flex-wrap:wrap;gap:1.25rem;justify-content:center;padding:1.25rem 0;\n  font-size:12px;letter-spacing:.08em;text-transform:uppercase}\nnav a{color:var(--suave);text-decoration:none;border-bottom:1px solid transparent}\nnav a:hover,nav a:focus{color:var(--tinta);border-bottom-color:var(--rojo)}\nnav.docs{border-top:1px solid var(--linea);border-bottom:1px solid var(--linea);\n  margin-bottom:1rem}\nsection{margin-top:4.5rem;scroll-margin-top:1rem}\nsection>h2{font-size:1rem;letter-spacing:.1em;text-transform:uppercase;\n  border-left:3px solid var(--rojo);padding-left:.9rem;margin:0 0 1.5rem}\n.cifras{display:grid;gap:1px;background:var(--linea);border:1px solid var(--linea);\n  grid-template-columns:repeat(auto-fit,minmax(160px,1fr))}\n.cifra{background:var(--panel);padding:1.1rem}\n.cifra b{display:block;font-size:1.7rem;color:var(--oro);font-weight:400;\n  font-variant-numeric:tabular-nums;line-height:1.2}\n.cifra span{font-size:11px;letter-spacing:.07em;text-transform:uppercase;color:var(--suave)}\n.hall{border-top:1px solid var(--linea);padding-top:1.75rem;margin-top:2.5rem}\n.hall:first-of-type{border-top:0;padding-top:0;margin-top:0}\n.hall h3{margin:0 0 .75rem;font-size:1.15rem;color:var(--rojo)}\n.hall h4{color:var(--oro);margin:1.5rem 0 .5rem;font-size:.95rem}\n.hall p{margin:0 0 1rem}\npre.asm{background:var(--panel);border-left:2px solid var(--verde);margin:1.25rem 0;\n  padding:1rem 1.1rem;overflow-x:auto;font-size:13px;line-height:1.6;color:var(--tinta)}\n.par{display:grid;gap:1.25rem;grid-template-columns:1fr}\n@media(min-width:820px){.par{grid-template-columns:1fr 1fr}}\n.par figure{margin:0}\ntable{border-collapse:collapse;width:100%;margin:1.25rem 0;font-size:13px;display:block;\n  overflow-x:auto}\nth,td{text-align:left;padding:.5rem .75rem;border-bottom:1px solid var(--linea)}\nth{color:var(--suave);font-weight:400;font-size:11px;letter-spacing:.07em;text-transform:uppercase}\ntd.num{font-variant-numeric:tabular-nums;color:var(--oro)}\n.nivel{margin-top:2rem}\n.nivel h3{margin:0 0 .9rem;font-size:.95rem;letter-spacing:.06em;text-transform:uppercase}\n.nivel em{color:var(--cyan);font-style:normal}\n.sep{color:var(--suave);margin:0 .6rem}\n.rejilla{display:grid;gap:.9rem;grid-template-columns:repeat(auto-fill,minmax(250px,1fr))}\n.rejilla figure{margin:0;background:var(--panel);box-shadow:0 0 0 1px var(--linea)}\n.rejilla figcaption{display:flex;justify-content:space-between;padding:.45rem .65rem;\n  font-size:11px;color:var(--suave);border-top:1px solid var(--linea)}\n.dir{font-variant-numeric:tabular-nums;color:var(--verde)}\nfooter{margin-top:5rem;padding-top:1.5rem;border-top:1px solid var(--linea);\n  color:var(--suave);font-size:12px}\n\n/* Aviso de trabajo en curso: tiene que verse antes que las cifras, porque un\n   100% mal leido hace mas dano que no ponerlo. */\n.aviso{background:#3a2a10;border-left:3px solid var(--oro);margin:1.5rem auto;\n  padding:1rem 1.2rem;max-width:900px;border-radius:4px}\n.aviso p{margin:0;color:var(--tinta);font-size:15px;line-height:1.65}\n.galeria{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));\n  gap:1.5rem;margin:1.5rem 0}\n.galeria figure{margin:0}\n.galeria img{width:100%;height:auto;image-rendering:pixelated;\n  border:1px solid var(--linea);border-radius:3px}\n.galeria figcaption{color:var(--suave);font-size:13px;margin-top:.5rem}\naudio{display:block;width:100%;max-width:640px;margin:.75rem 0 1.5rem}\n'
INSTRUCCIONES = 4422
RUTINAS = 535

EDITOR = 'Konami'

PORTADA = {
    'es': dict(
        titulo='Comic Bakery - desensamblado comentado',
        claim='Una panaderia de 92 columnas que cambia de maquinas de una fase a otra, una jornada de ocho minutos, y los mapaches que el listado llamaba carros, dibujados desde la ROM.',
        ficha=['Konami - <b>(c) Konami 1984</b>', 'Cartucho <b>RC-714</b>, 16 KB', 'MSX1 - <b>pagina 1</b>', 'Volcado <b>089e6cd7...</b>'],
        h_num='El cartucho en cifras',
        cifras=[('100 %', 'del binario explicado'), ('535', 'rutinas con nombre'), ('46,9 %', 'del listado comentado'), ('8.097', 'bytes de codigo'), ('8.287', 'bytes de datos'), ('0', 'bytes sin identificar')],
        pie_leg='Esto es trabajo de documentacion y preservacion: el codigo y los graficos siguen siendo de sus autores y de Konami, y la imagen del cartucho no se distribuye.',
        aviso='<b>Aqui no hay ninguna captura.</b> Todas las imagenes estan <b>dibujadas desde los bytes de la ROM</b>: las pantallas y la panaderia con la cadena de montaje del cartucho escrita en Python, y el panadero y los mapaches con <b>sus tablas de poses y pasos</b>, cotejado contra openMSX a cero bytes. El listado y las cifras se reproducen con <code>make</code>, y el reensamblado devuelve la ROM <b>byte a byte</b>.',
    ),
    'en': dict(
        titulo='Comic Bakery - a commented disassembly',
        claim='A 92-column bakery whose machines change from one stage to the next, an eight-minute working day, and the raccoons the listing called carts, drawn from the ROM.',
        ficha=['Konami - <b>(c) Konami 1984</b>', 'An <b>RC-714</b> 16 KB cartridge', 'MSX1 - <b>page 1</b>', 'Dump <b>089e6cd7...</b>'],
        h_num='The cartridge in numbers',
        cifras=[('100%', 'of the binary explained'), ('535', 'named routines'), ('46.9%', 'of the listing commented'), ('8,097', 'bytes of code'), ('8,287', 'bytes of data'), ('0', 'bytes unidentified')],
        pie_leg='This is documentation and preservation work: the code and artwork still belong to their authors and to Konami, and the cartridge image is not distributed.',
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from the bytes of the ROM</b>: the screens and the bakery with the cartridge's own set-up chain rewritten in Python, and the baker and the raccoons with <b>their pose and step tables</b>, checked against openMSX down to zero bytes. The listing and the numbers are reproducible with <code>make</code>, and reassembling gives back the ROM <b>byte for byte</b>.",
    ),
}

# La portada: las cifras y el pie tal como estaban
for _i, _c in {'es': ([('100 %', 'del binario explicado'), ('535', 'rutinas con nombre'), ('46,9 %', 'del listado comentado'), ('8.097', 'bytes de codigo'), ('8.287', 'bytes de datos'), ('0', 'bytes sin identificar')], 'El cartucho en cifras', 'Esto es trabajo de documentacion y preservacion: el codigo y los graficos siguen siendo de sus autores y de Konami, y la imagen del cartucho no se distribuye.'), 'en': ([('100%', 'of the binary explained'), ('535', 'named routines'), ('46.9%', 'of the listing commented'), ('8,097', 'bytes of code'), ('8,287', 'bytes of data'), ('0', 'bytes unidentified')], 'The cartridge in numbers', 'This is documentation and preservation work: the code and artwork still belong to their authors and to Konami, and the cartridge image is not distributed.')}.items():
    PORTADA[_i]["cifras"] = _c[0]
    PORTADA[_i]["h_num"] = _c[1]
    PORTADA[_i]["pie_leg"] = _c[2]
PORTADA['es']['aviso'] = '<b>Aqui no hay ninguna captura.</b> Todas las imagenes estan <b>dibujadas desde los bytes de la ROM</b>: las pantallas y la panaderia con la cadena de montaje del cartucho escrita en Python, y el panadero y los mapaches con <b>sus tablas de poses y pasos</b>, cotejado contra openMSX a cero bytes. El listado y las cifras se reproducen con <code>make</code>, y el reensamblado devuelve la ROM <b>byte a byte</b>.'
PORTADA['en']['aviso'] = "<b>Not one capture here.</b> Every picture is <b>drawn from the bytes of the ROM</b>: the screens and the bakery with the cartridge's own set-up chain rewritten in Python, and the baker and the raccoons with <b>their pose and step tables</b>, checked against openMSX down to zero bytes. The listing and the numbers are reproducible with <code>make</code>, and reassembling gives back the ROM <b>byte for byte</b>."

PAGINAS = [
    [('THE-GAME.html', 'EL-JUEGO.html', 'The game', 'El juego',
      'what the game is and how it plays',
      'qu&eacute; es el juego y c&oacute;mo se juega'),
     ('THE-PICTURES.html', 'LAS-IMAGENES.html', 'What the cartridge draws', 'Lo que el cartucho dibuja',
      'every picture drawn from the ROM, with its caption',
      'todas las im&aacute;genes dibujadas desde la ROM, con su pie'),
     ('THE-MUSIC.html', 'LA-MUSICA.html', 'The music', 'La m&#250;sica',
      'the tunes, from its own sound engine',
      'las m&uacute;sicas, de su propio motor de sonido')],
    [('CURIOSITIES.html', 'CURIOSIDADES.html', 'Curiosities', 'Curiosidades',
      'what turned up when taking it apart, and what is still open',
      'lo que apareci&oacute; al desmontarlo y lo que queda abierto')],
    [('UNDER-THE-HOOD.html', 'POR-DENTRO.html', 'Under the hood', 'Por dentro',
      'getting started, the cartridge, the code and the emulator',
      'empezar, el cartucho, el c&oacute;digo y el emulador')],
]

VIEJAS = {
    'FINDINGS.html': 'CURIOSITIES.html',
    'HALLAZGOS.html': 'CURIOSIDADES.html',
    'GETTING-STARTED.html': 'UNDER-THE-HOOD.html',
    'EMPEZAR.html': 'POR-DENTRO.html',
    'IN-THE-EMULATOR.html': 'UNDER-THE-HOOD.html',
    'EN-EL-EMULADOR.html': 'POR-DENTRO.html',
    'OPEN-QUESTIONS.html': 'CURIOSITIES.html',
    'PREGUNTAS-ABIERTAS.html': 'CURIOSIDADES.html',
    'THE-CARTRIDGE.html': 'UNDER-THE-HOOD.html',
    'EL-CARTUCHO.html': 'POR-DENTRO.html',
    'THE-CODE.html': 'UNDER-THE-HOOD.html',
    'EL-CODIGO.html': 'POR-DENTRO.html',
}

LOGOTIPO = 'rotulo.png'
