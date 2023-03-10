#lang info

(define name "syncvar")
(define collection "syncvar")
(define version "0.9.1")
(define deps '("base" "syncvar-lib"))
(define implies '("syncvar-lib"))
(define build-deps '("racket-doc" "scribble-lib"))
(define pkg-authors '(samdphillips@gmail.com))
(define scribblings '(["scribblings/syncvar.scrbl" ()]))
(define license 'Apache-2.0)
