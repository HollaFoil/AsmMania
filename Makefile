objects = build/AsmMania.o build/render.o build/window.o build/pcm.o build/print_file.o\
		  build/time.o build/read_file.o build/load_config.o build/sound.o build/select_map.o \
		  
.PHONY: clean

AsmMania: $(objects)
	$(CC) -no-pie -g -o "$@" $^ -lasound -lX11

build:
	mkdir build

build/%.o: src/%.s | build
	$(CC) -no-pie -g -c -o "$@" "$<"

clean:
	rm -rf AsmMania build
