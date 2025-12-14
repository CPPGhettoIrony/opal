CXX = nvcc
FORMAT = cu

DEF?=

CXXFLAGS = -O3 -use_fast_math -std=c++17 -arch=sm_75 -lineinfo -diag-suppress 20012 $(DEF)

LDFLAGS = -lGL -lGLEW -ldl -lm -lpthread -lrt -lX11 -lcudart -lraylib

SRC = $(wildcard *.$(FORMAT))
OBJ = $(SRC:.$(FORMAT)=.o)
EXE = raymarcher

%.o: %.$(FORMAT)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(EXE): $(OBJ)
	$(CXX) $(OBJ) $(LDFLAGS) -o $@

run: $(EXE)
	./$(EXE)

clean:
	rm -f $(OBJ) $(EXE)