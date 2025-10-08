exe=explorer

all: $(exe)

$(exe):
	gcc main.c -o $(exe) -lraylib -lm -ldl -lpthread -lGL -lX11

clean:
	rm $(exe)

run: $(exe)
	./$(exe)