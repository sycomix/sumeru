(use srfi-4)
(use srfi-133)
(use posix)

(define file->u8vector 
  (lambda (fname)
    (let* ([hnd (file-open fname open/binary)]
	   [sz (file-size hnd)]
	   [b (u8vector->blob (make-u8vector sz))]
	   [r (file-read hnd sz b)])
      (blob->u8vector b))))

(define get-bit
  (lambda (x i)
    (if (bit-set? x i)
      (fxshl 1 i)
      0)))

(define reverse-bits
  (lambda (x)
    (bitwise-ior (fxshl (get-bit x 0) 7)
	         (fxshl (get-bit x 1) 5)
	         (fxshl (get-bit x 2) 3)
	         (fxshl (get-bit x 3) 1)
	         (fxshr (get-bit x 4) 1)
	         (fxshr (get-bit x 5) 3)
	         (fxshr (get-bit x 6) 5)
	         (fxshr (get-bit x 7) 7))))
	  
(define u8vector-reverse-bits-internal!
  (lambda (v l o)
    (if (< o l)
      (begin
        (u8vector-set! v o (reverse-bits (u8vector-ref v o)))
	(u8vector-reverse-bits-internal! v l (+ 1 o)))
      v)))

(define u8vector-reverse-bits!
  (lambda (v)
    (u8vector-reverse-bits-internal! v (u8vector-length v) 0)))


