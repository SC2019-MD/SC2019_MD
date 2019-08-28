CC=g++
CFLAGS=-I. -O3
OBJ = homecell.o Gen_Pos_Cell.o Gen_Lookup_Mem.o Gen_Sim_Script.o main.o Gen_Velocity_Cell.o Gen_Boundary_Mem.o Gen_Sim_Top.o


homecell.o:homecell.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Pos_Cell.o:Gen_Pos_Cell.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Lookup_Mem.o:Gen_Lookup_Mem.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Sim_Script.o:Gen_Sim_Script.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Velocity_Cell.o:Gen_Velocity_Cell.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Boundary_Mem.o:Gen_Boundary_Mem.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Sim_Top.o:Gen_Sim_Top.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
main.o: main.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
all: $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS)
	
clean:
	rm *.o *.v all

