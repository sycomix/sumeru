TARGETS  = libgatt.so
OBJECTS  = att.o crypto.o uuid.o gatt.o gattrib.o btio.o log.o utils.o
CFLAGS  += -ggdb -fPIC -Wall -Ibluez $$(pkg-config --cflags glib-2.0)

CFLAGS  += -DVERSION='"5.25"'
CXXFLAGS = $(CFLAGS)
LDFLAGS  = -lbluetooth \
	   $$(pkg-config --libs glib-2.0)

vpath %.c bluez/attrib
vpath %.c bluez/src
vpath %.c bluez/src/shared
vpath %.c bluez/lib
vpath %.c bluez/btio

all: $(TARGETS)

libgatt.so: $(OBJECTS)
	$(CXX) $(CXXFLAGS) -shared -o $@ $^ $(LDFLAGS)

.PHONY: clean
clean:
	rm -f *.o *.so* *~
