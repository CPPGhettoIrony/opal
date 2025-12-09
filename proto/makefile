CXX = nvcc
CXXFLAGS =  --relocatable-device-code=true -lraylib -lGL -lGLEW -lcuda -lcudart -lglfw -ldl -lm -lpthread -lrt -lX11
FORMAT = cu

#CXX = g++
#CXXFLAGS = -lraylib -lGL -lGLEW -lglfw -ldl -lm -lglm -lpthread -lrt -lX11
#FORMAT = cpp

SRC = $(wildcard *.$(FORMAT))
OBJ = $(SRC:.$(FORMAT)=.o)
EXE = raymarcher

%.o: %.$(FORMAT)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(EXE): $(OBJ)
	$(CXX) $(CXXFLAGS) $^ -o $@ 

run: $(EXE)
	./$(EXE)

clean:
	rm -f $(OBJ) $(EXE)