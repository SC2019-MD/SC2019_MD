CC=g++
CFLAGS=-I. -O3
OBJ = homecell.o Gen_Cell_Mem.o Gen_Lookup_Mem.o Gen_Sim_Script.o main.o


homecell.o:homecell.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Cell_Mem.o:Gen_Cell_Mem.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Lookup_Mem.o:Gen_Lookup_Mem.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
Gen_Sim_Script.o:Gen_Sim_Script.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
main.o: main.cpp
	$(CC) -c -o  $@ $< $(CFLAGS)
all: $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS)
	
clean:
	rm *.o
	rm *.v
	

