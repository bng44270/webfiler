# Makefile Confuration
TARGET_DIR = build
TMP_DIR = tmp
SETTINGS_FILE = $(TMP_DIR)/settings
C_FILE = webfiler.py.c
H_FILE = $(TMP_DIR)/webfiler.py.h
PY_FILE = $(TARGET_DIR)/webfiler.py

SHELL := bash

define newdefine
@read -p "$(1) [$(3)]: " thisset ; [[ -z "$$thisset" ]] && echo "#define $(2) $(3)" >> $(4) || echo "#define $(2) $$thisset" | sed 's/\/$$//g' >> $(4)
endef

define newdefinestr
@read -p "$(1) [$(3)]: " thisset ; [[ -z "$$thisset" ]] && echo "#define $(2) \"$(3)\"" >> $(4) || echo "#define $(2) \"$$thisset\"" | sed 's/\/$$//g' >> $(4)
endef

define getdefine
$$((cpp -P <<< "$$(cat $(1) ; echo "$(2)")") | sed 's/"//g')
endef

all: $(SETTINGS_FILE) $(TARGET_DIR)
	cpp -P $(C_FILE) > $(PY_FILE)
	
	cp -R assets $(TARGET_DIR)
	cp -R templates $(TARGET_DIR)
	cp -R renderers $(TARGET_DIR)
	cp $(call getdefine,$(H_FILE),KEYFILE) $(TARGET_DIR)
	cp $(call getdefine,$(H_FILE),CERTFILE) $(TARGET_DIR)

$(SETTINGS_FILE): $(TMP_DIR)
	$(call newdefinestr,Enter local path,LOCALPATH,/tmp,$(H_FILE))
	$(call newdefine,Enter web port,WEBPORT,8443,$(H_FILE))
	$(call newdefinestr,Enter SSL Key file,KEYFILE,,$(H_FILE))
	$(call newdefinestr,Enter SSL Cert file,CERTFILE,,$(H_FILE))

$(TMP_DIR):
	mkdir $(TMP_DIR)

$(TARGET_DIR):
	mkdir $(TARGET_DIR)

clean:
	rm -rf $(TARGET_DIR)
	rm -rf $(TMP_DIR)
