SHELL := bash

C_FILE = webfiler.py.c
H_FILE = tmp/webfiler.py.h
PY_FILE = build/webfiler.py

define newdefine
@read -p "$(1) [$(3)]: " thisset ; [[ -z "$$thisset" ]] && echo "#define $(2) $(3)" >> $(4) || echo "#define $(2) $$thisset" | sed 's/\/$$//g' >> $(4)
endef

define newdefinestr
@read -p "$(1) [$(3)]: " thisset ; [[ -z "$$thisset" ]] && echo "#define $(2) \"$(3)\"" >> $(4) || echo "#define $(2) \"$$thisset\"" | sed 's/\/$$//g' >> $(4)
endef

define getdefine
$$(cpp -P -D CPP_ACTION=$(2) $(1))
endef

all: tmp/settings build
	cpp -P -D CPP_ACTION=1 $(C_FILE) > $(PY_FILE)
	
	cp -R assets build
	cp -R templates build
	cp -R renderers build
	cp $$(sed 's/"//g' <<< "$(call getdefine,$(C_FILE),2)") build
	cp $$(sed 's/"//g' <<< "$(call getdefine,$(C_FILE),3)") build

tmp/settings: tmp
	@echo "#define PYLEN len" > tmp/webfiler.py.h
	$(call newdefinestr,Enter local path,LOCALPATH,/tmp,$(H_FILE))
	$(call newdefine,Enter web port,WEBPORT,8443,$(H_FILE))
	$(call newdefinestr,Enter SSL Key file,KEYFILE,,$(H_FILE))
	$(call newdefinestr,Enter SSL Cert file,CERTFILE,,$(H_FILE))

tmp:
	mkdir tmp

build:
	mkdir build

clean:
	rm -rf build
	rm -rf tmp
