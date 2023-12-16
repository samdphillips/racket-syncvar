#lang racket/base

(require racket/contract
         racket/match)

(provide mvar?
         exn:fail:mvar?
         (contract-out
          [make-mvar        (->* () (any/c) mvar?)]
          [mvar-put!        (-> mvar? any/c any)]
          [mvar-take!-evt   (-> mvar? evt?)]
          [mvar-get-evt     (-> mvar? evt?)]
          [mvar-swap!-evt   (-> mvar? any/c evt?)]
          [mvar-update!-evt (-> mvar? (-> any/c any) evt?)]
          [mvar-take!       (-> mvar? any)]
          [mvar-try-take!   (-> mvar? any)]
          [mvar-get         (-> mvar? any)]
          [mvar-try-get     (-> mvar? any)]
          [mvar-swap!       (-> mvar? any/c any)]
          [mvar-update!     (-> mvar? (-> any/c any) any)]))

(struct exn:fail:mvar exn:fail ())

;; an empty mvar has signal in its value-box
(struct mvar (value-box signal))

(define make-mvar
  (case-lambda
    [()
     (define signal (make-semaphore 0))
     (mvar (box signal) signal)]
    [(init-value)
     (mvar (box init-value) (make-semaphore 1))]))

(define (mvar-put! an-mvar value)
  (match-define (mvar value-box signal) an-mvar)
  (let retry ()
    (cond
      [(box-cas! value-box signal value) (semaphore-post signal)]
      ;; spurious failure of cas
      [(eq? signal (unbox value-box)) (retry)]
      [else
       (raise (exn:fail:mvar "mvar-put!: mvar is full"
                             (current-continuation-marks)))])))

(define (mvar-take!-evt an-mvar)
  (match-define (mvar value-box signal) an-mvar)
  (wrap-evt signal
            (λ (signal)
              (define value (unbox value-box))
              (set-box! value-box signal)
              value)))

(define (mvar-get-evt an-mvar)
  (match-define (mvar value-box signal) an-mvar)
  (wrap-evt signal
            (λ (signal)
              (define value (unbox value-box))
              (semaphore-post signal)
              value)))

(define (mvar-swap!-evt an-mvar new-value)
  (wrap-evt (mvar-take!-evt an-mvar)
            (λ (old-value)
              (mvar-put! an-mvar new-value)
              old-value)))

(define (mvar-update!-evt an-mvar update-func)
  (wrap-evt (mvar-take!-evt an-mvar)
            (λ (old-value)
              (define-values (new-value err)
                (with-handlers ([exn:fail? (λ (err) (values old-value err))])
                  (values (update-func old-value) #f)))
              (mvar-put! an-mvar new-value)
              (if err
                  (raise err)
                  old-value))))

(define (mvar-take! an-mvar)
  (sync (mvar-take!-evt an-mvar)))

(define (mvar-try-take! an-mvar)
  (sync/timeout 0 (mvar-take!-evt an-mvar)))

(define (mvar-get an-mvar)
  (sync (mvar-get-evt an-mvar)))

(define (mvar-try-get an-mvar)
  (sync/timeout 0 (mvar-get-evt an-mvar)))

(define (mvar-swap! an-mvar value)
  (sync (mvar-swap!-evt an-mvar value)))

(define (mvar-update! an-mvar update-func)
  (sync (mvar-update!-evt an-mvar update-func)))
