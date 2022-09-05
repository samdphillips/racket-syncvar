#lang racket/base

(require racket/contract
         racket/match)

(provide ivar?
         exn:fail:ivar?
         make-ivar
         (contract-out
          [ivar-put!    (-> ivar? any/c any)]
          [ivar-get-evt (-> ivar? evt?)]
          [ivar-get     (-> ivar? any)]
          [ivar-try-get (-> ivar? any)]))

(struct empty-type ())
(define empty (empty-type))

(struct exn:fail:ivar exn:fail ())

(define (ivar-get-evt an-ivar)
  (wrap-evt (semaphore-peek-evt (ivar-signal an-ivar))
            (lambda (_ignore)
              (unbox (ivar-value-box an-ivar)))))

(struct ivar (value-box signal)
  #:property prop:evt ivar-get-evt)

(define (make-ivar)
  (ivar (box empty) (make-semaphore)))

(define (ivar-put! an-ivar value)
  (match-define (ivar value-box signal) an-ivar)
  (let retry ()
    (cond
      [(box-cas! value-box empty value) (semaphore-post signal)]
      ;; spurious failure of cas
      [(eq? empty (unbox value-box)) (retry)]
      [else
       (raise (exn:fail:ivar "ivar-put!: ivar has already been assigned"
                             (current-continuation-marks)))])))

(define (ivar-get an-ivar)
  (sync an-ivar))

(define (ivar-try-get an-ivar)
  (sync/timeout 0 an-ivar))
