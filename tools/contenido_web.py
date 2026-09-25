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

HALLAZGOS = {
    "es": [
        ("Los carros eran mapaches",
         "<p>El listado llamaba <b>carros</b> a lo que el panadero dispara y "
         "lo que le quita una vida. Dibujados desde la ROM son los "
         "<b>mapaches</b>: dos sprites en fila, el segundo dieciseis pixeles a "
         "la derecha, en gris, amarillo y rojo (<code>0x51B2</code>).</p>"),

        ("Dos panaderias",
         "<p>La panaderia es una sola, las 92 columnas de "
         "<code>0x7604</code>, pero el montaje de la fase elige sus bloques "
         "graficos con <code>(0xE051)</code>: maquinas <b>verdes</b> en las "
         "fases 1, 2, 4, 6... y <b>azules</b> en las 3, 5, 7... Cotejadas "
         "contra openMSX a 0 bytes.</p>"),

        ("Los sprites no los monta la pantalla",
         "<p>Los 64 patrones de sprite los carga <code>0x70D6</code>: tres "
         "bloques comprimidos y, encima, sus <b>reflejos</b> -cada byte con "
         "los bits del reves y las dos mitades cambiadas-, para tener cada "
         "figura mirando a los dos lados sin guardarla dos veces.</p>"),

        ("La demostracion se juega con un guion",
         "<p>Mientras se esta en el menu, la lectura del mando no viene del "
         "mando: viene de <b>80 bytes grabados en <code>0x6001</code></b>, "
         "que el cartucho va sirviendo como si alguien pulsara.</p>"),

        ("Una jornada de ocho minutos",
         "<p>El reloj de <code>0x4614</code> cuenta segundos en BCD hasta 60 "
         "y sube un minuto; al llegar al <b>minuto ocho</b> levanta la senal "
         "de fin de fase. Ninguno de sus dos hermanos de tanda lo tiene.</p>"),

        ("El visor que se quedo dentro",
         "<p><code>0x60B0</code> llena las 768 celdas con los indices 0, 1, "
         "2... para ver todos los patrones de golpe y se queda en un "
         "<code>jr $</code>. Nadie la llama: es la herramienta de quien hizo "
         "el juego, olvidada en la ROM.</p>"),
    ],
    "en": [
        ("The carts were raccoons",
         "<p>The listing called <b>carts</b> what the baker shoots and what "
         "costs the baker a life. Drawn from the ROM they are the <b>raccoons</b>: "
         "two sprites in a row, the second sixteen pixels to the right, in "
         "grey, yellow and red (<code>0x51B2</code>).</p>"),

        ("Two bakeries",
         "<p>There is one bakery, the 92 columns at <code>0x7604</code>, but "
         "the stage set-up picks its graphics blocks with "
         "<code>(0xE051)</code>: <b>green</b> machines on stages 1, 2, 4, "
         "6... and <b>blue</b> ones on 3, 5, 7... Checked against openMSX "
         "down to 0 bytes.</p>"),

        ("The sprites are not set up with the screen",
         "<p>The 64 sprite patterns are loaded by <code>0x70D6</code>: three "
         "compressed blocks and, on top, their <b>mirror images</b> -each "
         "byte with its bits reversed and the two halves swapped-, so every "
         "figure faces both ways without being stored twice.</p>"),

        ("The demo plays from a script",
         "<p>While in the menu, the controller reading does not come from "
         "the controller: it comes from <b>80 bytes recorded at "
         "<code>0x6001</code></b>, which the cartridge serves as if someone "
         "were pressing.</p>"),

        ("An eight-minute working day",
         "<p>The clock at <code>0x4614</code> counts seconds in BCD up to 60 "
         "and adds a minute; on <b>minute eight</b> it raises the end-of-stage "
         "flag. Neither of its two batch siblings has it.</p>"),

        ("The viewer left inside",
         "<p><code>0x60B0</code> fills the 768 cells with indices 0, 1, 2... "
         "to see every pattern at once and stays on a <code>jr $</code>. "
         "Nothing calls it: it is the developer's tool, left behind in the "
         "ROM.</p>"),
    ],
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
