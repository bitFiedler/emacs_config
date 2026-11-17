CC = cc
CPPFLAGS += -Iinclude
CFLAGS += -std=c11 -Wall -Wextra -g
OBJECTS = build/main.o build/answer.o
.PHONY: all clean
all: build/demo
build/demo: $(OBJECTS)
	$(CC) $(OBJECTS) -o $@
build/%.o: src/%.c include/answer.h | build
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@
build:
	mkdir -p $@
clean:
	rm -f $(OBJECTS) build/demo
