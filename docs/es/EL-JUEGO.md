# El juego

![El rótulo](../imagenes/rotulo.png)

El panadero guarda la panadería de los **mapaches** durante una jornada de
**ocho minutos** de reloj (`0x4614`). Anda por la planta, salta con los dos
botones y dispara; un mapache que lo toca le quita una vida. Al acabar la
jornada, el cartucho cuenta los panes (`0x5B5E`).

Las imágenes de abajo **no son capturas ni el cartucho ejecutándose**: son las
tablas de la ROM montadas como las monta el juego —las pantallas y la panadería
con su cadena de montaje, el panadero y los mapaches con sus tablas de poses y
pasos—. Cotejadas contra openMSX en dieciséis volcados de partida: **0 bytes
distintos** en las tablas de color, patrones y patrones de sprite.

## El panadero

Cuatro sprites (`0x4C51`), con los patrones de una de las catorce poses de
`0x7124` y la fila y el color de la plantilla de `0x7096`: el segundo va 0x10
por debajo del primero, el tercero 8 y el cuarto 0x20.

![El panadero](../imagenes/jugador.png)

## Los mapaches

Dos sprites en fila (`0x51D9`), el segundo dieciséis píxeles a la derecha y con
el patrón cuatro más allá. Andando hacia la izquierda los patrones salen desde
`0x78`, y hacia la derecha 0x3C más allá; el paso lo elige el contador de
cuadros y solo da 0, 8 o 16. Son tres, y los distingue el color de `0x51B2`:
gris, amarillo y rojo.

![Los mapaches](../imagenes/enemigos.png)

## La panadería de cada fase

La panadería es una sola: las **92 columnas de diez celdas** de `0x7604`. La
pantalla enseña 32, desde la fila 13. Pero el montaje de la fase (`0x49BB` a
`0x49E7`) elige sus bloques gráficos con el contador de `0xE051`, y la
panadería cambia de máquinas:

| fases | máquinas |
|---|---|
| 1, 2, 4, 6, 8... | verdes |
| 3, 5, 7, 9... | azules |

![La panadería de las fases 1, 2, 4...](../imagenes/panaderia-fases-1-2-4.png)

![La panadería de las fases 3, 5, 7...](../imagenes/panaderia-fases-3-5-7.png)

## La tienda, al final de cada jornada

Cuando se acaba la jornada, el panadero se va de la planta y se monta la
**BAKERY SHOP** (`0x5AD6`), con cuatro niños sentados al mostrador. El
panadero empuja el carro con los panes hechos al compás de la música del fin
de fase (la 0x96): el carro avanza hasta que la partitura llega a la marca
`0xD4` (`0x5BAA`). Entonces cada niño recibe un pan (`0x5C6F`) y se cobra un
premio de **600 × panes** (`0x5CCF`). En el tejado asoma un personaje con un
globo que cambia según los panes (`0x5D22`):

| panes | globo |
|---|---|
| 4 | ほっ |
| 5-6 | HEY |
| 7-8 | NICE |
| 9 o más | FINE |

Con menos de cuatro, alguno se queda sin pan: el globo dice cuántos faltan
(`4 − panes`; «1つたりない» es «falta uno») y **se pierde una vida** (`0x5D0E`,
escena 12); si no quedan vidas, se acaba la partida (`0x42A9`). Medido: con
tres panes se pasa a la fase siguiente con una vida menos (de 2 a 1), y con
diez, con las mismas.

A diferencia de las demás imágenes de esta página, esta escena **sale
ejecutando el cartucho**, como la música: `tools/tienda.py` lo arranca en frío
con z80run, le da a cada cuadro lo mismo que la interrupción (`0x406E`) y
fotografía la VRAM con el mismo renderizador cotejado. Lo único que se pone a
mano es lo que haría el jugador: pulsar en el menú, acabar la jornada
(`0xE00D`) y cuántos panes ha hecho (`0xE060`).

![La tienda con diez panes](../imagenes/tienda.gif)

![La tienda con tres panes: falta uno](../imagenes/tienda-falta.gif)

![El globo con 3, 4, 5, 6 panes (arriba) y 7, 8, 9, 10 (abajo)](../imagenes/tienda-globos.png)

## Las pantallas de menú

Montadas desde la ROM y cotejadas contra openMSX a **0 bytes**.

![La pantalla de la casa](../imagenes/pantalla-presentacion.png)

![La pantalla de título](../imagenes/pantalla-titulo.png)
