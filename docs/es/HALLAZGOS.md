# Hallazgos

1. **Los carros eran mapaches.** El listado llamaba carros a lo que el panadero
   dispara y lo que le quita una vida; dibujados desde la ROM son los mapaches.
   Y su segundo sprite va dieciséis píxeles a la derecha, no debajo.
2. **Dos panaderías.** El montaje de la fase elige bloques gráficos con
   `(0xE051)`: máquinas verdes en las fases 1, 2, 4, 6... y azules en las 3, 5,
   7... Las fases 1 y 2 se ven igual porque la fase 0 entra por el mismo bloque
   que las impares.
3. **La pantalla se monta una vez.** `0x6051` corre al encender, con la fase a
   cero; al empezar cada fase solo se recargan sus bloques. Montándolo así, los
   dieciséis volcados dan 0 bytes distintos.
4. **Los sprites no los monta la pantalla.** Los 64 patrones los carga
   `0x70D6`, con sus reflejos: cada figura mira a los dos lados sin guardarla
   dos veces.
5. **La demostración se juega con un guion**: 80 bytes grabados en `0x6001`
   que sustituyen al mando mientras se está en el menú.
6. **Una jornada de ocho minutos**, contada en BCD por `0x4614`. Ninguno de sus
   dos hermanos de tanda tiene reloj.
7. **El visor que se quedó dentro.** `0x60B0` llena las 768 celdas con los
   índices 0, 1, 2... y se queda en un `jr $`. Nadie la llama.
8. **La interrupción guarda los doce registros**, cuando sus dos hermanos se
   fían de que el hilo principal no los usa.
9. **La vida extra sube de tres en tres**, no de dos en dos como en Circus
   Charlie y Magical Tree, sus hermanos de tanda.
10. **El cambio de jugador son 48 bytes**, no 32: este cartucho lleva más
    estado por jugador.
11. **El juego mira la música.** `0x5492` y `0x5BA6` deciden según el byte al
    que apunta la partitura de una voz.
12. **El mismo lenguaje de descompresión que sus hermanos**, con otra firma de
    rutinas (`0x43EE`).
