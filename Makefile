SHELL := bash

define newsetting
@read -p "$(1) [$(3)]: " thisset ; [[ -z "$$thisset" ]] && echo "$(2) $(3)" >> $(4) || echo "$(2) $$thisset" | sed 's/\/$$//g' >> $(4)
endef

define getsetting
$$(grep "^$(2)[ \t]*" $(1) | sed 's/^$(2)[ \t]*//g')
endef

all: tmp/settings build
	m4 -DLOCALPATH="$(call getsetting,tmp/settings,NEWPATH)" -DWEBPORT="$(call getsetting,tmp/settings,WEBPORT)" -DCERTFILE="$$(basename $(call getsetting,tmp/settings,CERTFILE))" -DKEYFILE="$$(basename $(call getsetting,tmp/settings,KEYFILE))" webfiler.py.m4 > build/webfiler.py
	cp -R assets build
	cp -R templates build
	cp -R renderers build
	cp $(call getsetting,tmp/settings,KEYFILE) build
	cp $(call getsetting,tmp/settings,CERTFILE) build

tmp/settings: tmp
	$(call newsetting,Enter local path,NEWPATH,/tmp,tmp/settings)
	$(call newsetting,Enter web port,WEBPORT,8443,tmp/settings)
	$(call newsetting,Enter SSL Key file,KEYFILE,,tmp/settings)
	$(call newsetting,Enter SSL Cert file,CERTFILE,,tmp/settings)

tmp:
	mkdir tmp

build:
	mkdir build

clean:
	rm -rf build
	rm -rf tmp
