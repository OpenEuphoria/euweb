CC = gcc
CFLAGS = -fPIC -O3 -Os -DJSMN_PARENT_LINKS

LD = gcc
LDFLAGS = -s

TARGET = libjsmn.so
OBJECTS = jsmn.o

all : $(TARGET)

$(TARGET) : $(OBJECTS)
	$(LD) $(LDFLAGS) -shared -o $@ $<

%.o : %.c
	$(CC) $(CFLAGS) -o $@ -c $^

clean :
	$(RM) $(OBJECTS) $(TARGET)

install : $(TARGET)
	-@[ -d /usr/lib64 ] && install $(TARGET) /usr/lib64 || install $(TARGET) /usr/lib

.PHONY : all clean install
