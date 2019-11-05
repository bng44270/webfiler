define newsetting
@read -p "$(1) [$(3)]: " thisset ; [[ -z "$$thisset" ]] && echo "$(2) $(3)" >> $(4) || echo "$(2) $$thisset" | sed 's/\/$$//g' > $(4)
endef

define getsetting
$$(grep "^$(2)[ \t]*" $(1) | sed 's/^$(2)[ \t]*//g')
endef

all: tmp/settings build
	m4 -DLOCALPATH="$(call getsetting,tmp/settings,NEWPATH)" -DWEBPORT="$(call getsetting,tmp/settings,WEBPORT)" webfiler.py.m4 > build/webfiler.py
	cp -R templates build

tmp/settings: tmp
	$(call newsetting,Enter local path,NEWPATH,/tmp,tmp/settings)
	$(call newsetting,Enter web port,WEBPORT,8080,tmp/settings)

tmp:
	mkdir tmp

build:
	mkdir build

clean:
	rm -rf build
	rm -rf tmp
