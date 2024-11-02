.PHONY: download docs build build.header build.macos build.linux build.windows build.projects clean

build:
	make clean
	make download
	make bh
	make bp

download d:
	make clean
	curl -L https://github.com/wren-lang/wren/archive/refs/tags/0.4.0.zip -o wren.zip
	unzip ./wren.zip
	rm wren.zip
	mv wren-0.4.0 wren

docs:
# python3 -m pip install markdown
	cd wren && python3 util/generate_docs.py

build.header bh:
	cd wren && python3 util/generate_amalgamation.py > wren.c
	mkdir -p include
	mv wren/wren.c include
	cp wren/src/include/wren.h include

build.projects bp:
	cd wren && python3 util/generate_projects.py

build.macos bm:
	rm -rf macos
	mkdir -p macos
	cd wren/projects/make.mac && make
	mv wren/lib/libwren.a macos/wren.a
	mv wren/lib/libwren.dylib macos/wren.dylib

build.linux bl:
	rm -rf linux
	mkdir -p linux
	cd wren/projects/make && make
	mv wren/lib/libwren.a linux/wren.a
	mv wren/lib/libwren.so linux/wren.so

build.windows bw:
	echo "TODO"

clean:
	rm -rf include
	rm -rf wren.zip
	rm -rf wren-0.4.0
	rm -rf wren
