# Comic Bakery (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# El cartucho no se distribuye: hace falta en la raiz como comicbakery.rom, y
# `make comprueba` verifica su sha256.

ROM      = comicbakery.rom
SHA      = 089e6cd7ff074c5c162325b3ac00e36e5787034bffe349b6e33db51a2e591ed8
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = COMIC BAKERY - Konami - MSX1 - cartucho RC-714 de 16 KB en la pagina 1

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Comic Bakery (Konami, RC-714) para MSX, 16384 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/comicbakery.trace.json: $(ROM) $(SRC)/comicbakery.entries $(SRC)/comicbakery.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/comicbakery.entries \
	        $(WORK)/comicbakery $(SRC)/comicbakery.nocode

trace: $(WORK)/comicbakery.trace.json

listado: $(WORK)/comicbakery.trace.json $(SRC)/comicbakery.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/comicbakery.trace.json \
	        $(SRC)/comicbakery.notes work/msx.sym $(SRC)/comicbakery.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/comicbakery.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/comicbakery.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/comicbakery.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/comicbakery.trace.json $(SRC)/comicbakery.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/comicbakery.entries $(SRC)/comicbakery.notes \
	        $(SRC)/comicbakery.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/comicbakery.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Dibuja los bloques de datos graficos declarados en el .notes, para MIRARLOS.
imagenes: $(ROM)
	@mkdir -p docs/imagenes
	python3 tools/graficos.py $(ROM) $(ORG) docs/imagenes

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; la portada la monta
# make_web.py, que declara las cifras medidas de ESTE cartucho.
web: $(ROM)
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/comicbakery.trace.json $(WORK)/comicbakery.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes web clean
