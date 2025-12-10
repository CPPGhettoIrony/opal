CXX = nvcc
FORMAT = cu

CXXFLAGS = -O3 -std=c++17 -arch=sm_75 -lineinfo -diag-suppress 20012

LDFLAGS = -lGL -lGLEW -lglfw -ldl -lm -lpthread -lrt -lX11 -lcudart -lraylib

SRC = $(wildcard *.$(FORMAT))
OBJ = $(SRC:.$(FORMAT)=.o)
EXE = raymarcher

%.o: %.$(FORMAT)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(EXE): $(OBJ)
	$(CXX) $(OBJ) $(LDFLAGS) -o $@

run: $(EXE)
	prime-run ./$(EXE)

clean:
	rm -f $(OBJ) $(EXE)
