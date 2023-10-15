objects = build/AsmMania.o build/render.o build/window.o build/pcm.o \
		  build/time.o build/read_file.o build/load_config.o
.PHONY: clean

AsmMania: $(objects)
	$(CC) -no-pie -o "$@" $^ -lasound -lX11

build:
	mkdir build

build/%.o: src/%.s | build
	$(CC) -no-pie -c -o "$@" "$<"

clean:
	rm -rf AsmMania build
