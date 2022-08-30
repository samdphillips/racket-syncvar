#lang racket/base

(require racket/contract
         racket/match)

(provide ivar?
         exn:fail:ivar?
         make-ivar
         (contract-out
          [ivar-put!    (-> ivar? any/c any)]
          [ivar-get-evt (-> ivar? any)]
          [ivar-get     (-> ivar? any)]))

(struct exn:fail:ivar exn:fail ())

(define (ivar-get-evt an-ivar)
  (wrap-evt (semaphore-peek-evt (ivar-signal an-ivar))
            (lambda (_ignore)
              (unbox (ivar-value-box an-ivar)))))

(struct ivar (value-box signal)
  #:property prop:evt ivar-get-evt)

(define (make-ivar)
  (define signal (make-semaphore))
  (ivar (box signal) signal))

(define (ivar-put! an-ivar value)
  (match-define (ivar value-box signal) an-ivar)
  (let loop ()
    (cond
      [(box-cas! value-box signal value) (semaphore-post signal)]
      ;; spurious failure of cas
      [(eq? signal (unbox value-box)) (loop)]
      [else
       (raise (exn:fail:ivar "ivar-put!: ivar has already been assigned"
                             (current-continuation-marks)))])))

(define (ivar-get an-ivar)
  (sync an-ivar))
