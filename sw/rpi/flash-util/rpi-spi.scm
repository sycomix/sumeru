(require-extension lazy-ffi)
(use srfi-4)

(define SPI_MODE0 (integer->char 0))
(define SPI_MODE1 (integer->char 1))
(define SPI_MODE2 (integer->char 2))
(define SPI_MODE3 (integer->char 3))

(define SPI_CS0 (integer->char 0))
(define SPI_CS1 (integer->char 1))
(define SPI_CS2 (integer->char 2))
(define SPI_CS_NONE (integer->char 3))

(define SPI_CS_POLARITY_LOW (integer->char 0))
(define SPI_CS_POLARITY_HIGH (integer->char 1))

(define SPI_CLK_PI3_12P5M 32)
(define SPI_CLK_PI3_25M 16)
(define SPI_CLK_PI3_50M 8)

(define spi-init
  (lambda ()
    (begin
	#~"libbcm2835_wrapper.so"
	(#~bcm2835_init)
	(#~bcm2835_spi_begin)
	(#~bcm2835_spi_setDataMode SPI_MODE0)
	;; - thunk via wrapper to pass in short arg to function
	(#~bcm2835w_spi_setClockDivider SPI_CLK_PI3_12P5M) 
	(#~bcm2835_spi_setChipSelectPolarity SPI_CS0 SPI_CS_POLARITY_LOW)
	(#~bcm2835_spi_chipSelect SPI_CS0))))

(define spi-dnit
  (lambda ()
    (#~bcm2835_spi_end)))

(define spi-issue-cmd
  (lambda (oplen v) 
    (if (u8vector? v) 
	(let ([len (u8vector-length v)])
	  (begin (#~bcm2835_spi_transfern v len) 
		 (if (= oplen 0) v (subu8vector v oplen len))))
	#f)))

