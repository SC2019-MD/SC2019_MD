.SUFFIXES:
.SUFFIXES: .o .cpp .h

#============================================================
TARGET	= gen

C_SOURCES = Gen_Sim_Script.cpp
C_OBJS = Gen_Sim_Script.o	
MY_INCLUDES = Gen_Sim_Script.h

CCX = g++
CXXFLAGS = -g -O2  $(INC)

#============================================================
all: $(TARGET)

.o:.cpp	$(MY_INCLUDES)
	$(CCX)  -c  $(CXXFLAGS) $<  

$(TARGET) :   $(C_OBJS)
	$(CCX) $(CXXFLAGS)  $^ $(LIBDIRS)  -o $@

# Implicit rules: $@ = target name, $< = first prerequisite name, $^ = name of all prerequisites 
#============================================================

ALL_SOURCES = Makefile $(C_SOURCES) $(MY_INCLUDES)

NOTES =

clean:
	rm -f $(TARGET) $(C_OBJS) *~


