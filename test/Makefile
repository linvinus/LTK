PRG_NAME=xcb_vala

GIT_HASH=${shell which git >/dev/null && git log -1 --pretty=format:%h}

VALA_FLAGS ?=

#use tmpfs for ssd hard drive
TMPFS=$(shell ls -d ./tmpfs 2>/dev/null)
ifeq ($(TMPFS),./tmpfs)
$(shell `[ \(  -L ./tmpfs \)  -a \( -e ./tmpfs \) ] || mkdir -p /run/shm/$(PRG_NAME)_build; rm -rf ./tmpfs ; ln -s /run/shm/$(PRG_NAME)_build ./tmpfs` )
VALA_FLAGS += -d ./tmpfs
endif

VALA_FLAGS += -v
VALA_FLAGS += --disable-warnings
VALA_FLAGS += --save-temps -X -O0 -X -g
VALA_FLAGS += -X -DGETTEXT_PACKAGE=\"$(PRG_NAME)\" -X -DAY_GIT_HASH=\"$(GIT_HASH)\"

include ../Makefile

VALA_FLAGS += $(LTK_FLAGS)

PREFIX?=/usr

VALA_FILES  =   main.vala $(LTK_FILES)


default:
	valac -o $(PRG_NAME) $(VALA_FLAGS) $(VALA_FILES)

clean:
	rm *.c *.h || true
	rm ./altyo || true
	rm ./data/*.c *.h || true

install: gen_mo
	test -z "$(DESTDIR)$(PREFIX)/bin" || mkdir -p "$(DESTDIR)$(PREFIX)/bin";
	cp -a ./$(PRG_NAME) $(DESTDIR)$(PREFIX)/bin

gen_po:
	xgettext -o ./po/$(PRG_NAME).po --from-code=UTF-8 -language=C --keyword=_ --keyword=N_ $(VALA_FILES) $(GLADE_FILES)
	msgmerge -s -U ./po/ru/LC_MESSAGES/$(PRG_NAME).po  ./po/$(PRG_NAME).po

gen_mo:
	msgfmt -c -v -o ./po/ru/LC_MESSAGES/$(PRG_NAME).mo ./po/ru/LC_MESSAGES/$(PRG_NAME).po

source-package:
	rm ./$(PRG_NAME) || true
	rm ./po/ru/LC_MESSAGES/$(PRG_NAME).mo || true
	git-buildpackage --git-upstream-tree=branch --git-upstream-branch=master -rfakeroot -S -sa
	sed -i -re '1 s/(altyo \(.*)\) .*\;/\1~precise\) precise\;/' ./debian/changelog
	dpkg-buildpackage -S -sa
	git checkout ./debian/changelog
	sed -i -re '1 s/(altyo \(.*)\) .*\;/\1~vivid\) vivid\;/' ./debian/changelog
	dpkg-buildpackage -S -sa
	git checkout ./debian/changelog

gen_changes:
	git-dch --ignore-branch --debian-branch=master --verbose -a -R
	git add .
	$(MAKE) gen_changes_stage2

gen_changes_stage2:
	git commit -m "new: debian release $(CHANGELOG_TAG)"
	git tag "debian/$(CHANGELOG_TAG)"
	git push
	git push origin --tags

#git tag "debian/0.2_121003-linvinus1" ~ -> _ , : -> %
#git-dch --ignore-branch --debian-branch=master --verbose
#git push origin --tags
