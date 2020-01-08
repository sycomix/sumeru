libbcm2835_wrapper.so: CFLAGS+=-fPIC -shared

libbcm2835_wrapper.so: bcm2835_wrapper.o
	$(CC) $(CFLAGS) -o $@ $^ -lbcm2835

clean:
	@rm -f libbcm2835_wrapper.so bcm2835_wrapper.o
