(load "rpi-spi")

(use srfi-133)

(define spi-cmd-flash-id 		
  (lambda ()
    (spi-issue-cmd 1 (u8vector #x9F 0 0 0))))

(define spi-cmd-flash-chip-erase
  (lambda ()
    (spi-cmd-flash-write-enable)
    (spi-issue-cmd 1 (u8vector #x60))))

(define spi-cmd-flash-write-enable 	
  (lambda ()
    (spi-issue-cmd 1 (u8vector #x06))))

(define spi-cmd-flash-write-disable 	
  (lambda ()
    (spi-issue-cmd 1 (u8vector #x04))))

(define spi-cmd-flash-read-status1	
  (lambda ()
    (spi-issue-cmd 1 (u8vector #x05 0))))

(define spi-cmd-flash-read-status2
  (lambda ()
    (spi-issue-cmd 1 (u8vector #x35 0))))

(define spi-cmd-flash-write-status
  (lambda ()
    (spi-issue-cmd 1 (u8vector #x01 0 0))))


;;
;; Hardcoded - 24 Bit Addressing

(define extract-addr-byte 
  (lambda (x pos) (bitwise-and (fxshr x (* pos 8)) #xFF)))

(define spi-flash-cmd-generic-addr-in
  (lambda (cmd addr len)
    (let ([v (make-u8vector (+ 4 len))])
      (begin 
	(u8vector-set! v 0 cmd)
	(u8vector-set! v 1 (extract-addr-byte addr 2))
	(u8vector-set! v 2 (extract-addr-byte addr 1))
	(u8vector-set! v 3 (extract-addr-byte addr 0))
	v))))

(define spi-cmd-flash-read
  (lambda (addr len)
    (spi-issue-cmd  4 (spi-flash-cmd-generic-addr-in #x03 addr len))))

(define spi-cmd-flash-erase
  (lambda (op addr)
    (spi-issue-cmd 0 (spi-flash-cmd-generic-addr-in op addr 0))))

(define spi-cmd-flash-erase-sector
    (lambda (addr)
      (spi-cmd-flash-erase #x20 addr)))

(define spi-cmd-flash-erase-32k
    (lambda (addr)
      (spi-cmd-flash-erase #x52 addr)))

(define spi-cmd-flash-erase-64k
    (lambda (addr)
      (spi-cmd-flash-erase #xD8 addr)))

(define spi-cmd-flash-erase-128k
    (lambda (addr)
      (spi-cmd-flash-erase #xD2 addr)))

(define spi-cmd-flash-write-page
  (lambda (addr data)
    (if (u8vector? data)
      (let* ([len (u8vector-length data)]
	     [v (make-u8vector (+ len 4))])
	(begin 
	  (u8vector-set! v 0 #x02)
	  (u8vector-set! v 1 (extract-addr-byte addr 2))
	  (u8vector-set! v 2 (extract-addr-byte addr 1))
	  (u8vector-set! v 3 (extract-addr-byte addr 0))
	  (#~bcm2835w_vector_append v data 4 len)
          (spi-cmd-flash-write-enable)
	  (spi-issue-cmd 0 v)))
      #f)))

(define flash-page-len 256)

(define flash-write-wait
  (lambda ()
    (if (= 0 (bitwise-and 1 (u8vector-ref (spi-cmd-flash-read-status1) 0)))
        #t
        (flash-write-wait))))

(define spi-cmd-flash-write-internal
    (lambda (addr data len offset)
        (if (u8vector? data)
            (if (>= offset len)
                #t
                (begin
                    (define x (min flash-page-len (- len offset)))
                    (print (u8vector-length data) " " len " " offset " " x)
                    (spi-cmd-flash-write-page (+ addr offset)
                                              (subu8vector data 
                                                           offset 
                                                           (+ offset x)))
                    (flash-write-wait)
                    (spi-cmd-flash-write-internal 
                                         addr data len 
                                         (+ offset x))))
            #f)))

(define spi-cmd-flash-write
    (lambda (addr data)
        (if (u8vector? data)
          (spi-cmd-flash-write-internal addr data 
                                        (u8vector-length data) 0)
          #f)))










