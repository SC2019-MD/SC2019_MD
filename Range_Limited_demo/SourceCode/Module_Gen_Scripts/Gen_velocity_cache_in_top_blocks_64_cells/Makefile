.SUFFIXES:
.SUFFIXES: .o .cpp .h

#============================================================
TARGET	= gen

C_SOURCES = Gen_Velocity_Cache_in_top_blocks.cpp
C_OBJS = Gen_Velocity_Cache_in_top_blocks.o	
MY_INCLUDES = Gen_Velocity_Cache_in_top_blocks.h

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


