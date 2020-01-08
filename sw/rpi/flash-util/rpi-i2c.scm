(require-extension lazy-ffi)
(use srfi-4)

(define SPI_CLK_PI3_10US 2500)
(define SPI_CLK_PI3_2P504US 626)
(define SPI_CLK_PI3_60NS 150)
(define SPI_CLK_PI3_59NS 148)

(define i2c-init
  (lambda ()
    (begin
      #~"libbcm2835_wrapper.so"
      (#~bcm2835_i2c_begin)
      (#~bcm2835w_i2c_setClockDivider SPI_CLK_PI3_60NS))))

(define i2c-dnit
  (lambda ()
    (#~bcm2835_i2c_end)))



      
