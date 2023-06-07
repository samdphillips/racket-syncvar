#lang racket/base

(module+ test
  (require racket/match
           racket/promise
           rackunit
           syncvar)

  (define (end-trace? m)
    (match m
      [(vector 'warning (pregexp #px"^.*: done$") _ ...) #t]
      [_ #f]))

  (define (make-tracer logger)
    (delay/thread
      (define trace-rcvr (make-log-receiver logger 'info))
      (let loop ([msgs null])
        (define msg (sync trace-rcvr))
        (cond
          [(end-trace? msg) (reverse msgs)]
          [else
            (loop (cons msg msgs))]))))

  (test-case "ivar tests"
    (define-logger consumer)
    (define-logger producer)
    (define consumer-tracer (make-tracer consumer-logger))
    (define producer-tracer (make-tracer producer-logger))

    (define iv (make-ivar))
    (define s (make-semaphore))

    (define (producer i v)
      (lambda ()
        (log-producer-debug "~a waiting" i)
        (sync (semaphore-peek-evt s))
        (with-handlers ([exn:fail:ivar?
                        (lambda (e)
                          (log-producer-warning "~a ivar errored" i))])
          (log-producer-info "~a putting" i)
          (ivar-put! iv v))))

    (define (consumer i p)
      (lambda ()
        (log-consumer-debug "~a sleeping ~a" i p)
        (sleep p)
        (log-consumer-debug "~a waiting" i)
        (define v (ivar-get iv))
        (log-consumer-info "~a got ~a" i v)))

    (void (thread (consumer 'c 1)))
    (void (thread (consumer 'd 2)))

    (void (thread (producer 'a 'p1)))
    (void (thread (producer 'b 'p2)))
    (sleep 3)
    (check-false (ivar-try-get iv) "ivar-try-get should be #f before producers run")
    (semaphore-post s)
    (sleep 1)
    (log-consumer-warning "done")
    (log-producer-warning "done")
    (check-match (ivar-try-get iv) (or 'p1 'p2))
    (define consumer-trace (force consumer-tracer))
    (define producer-trace (force producer-tracer))

    (match consumer-trace
      [(list _ ...
             (vector 'info (regexp #px"(\\w+) got (\\w+)" (list _ c1 v1)) _ ...)
             (vector 'info (regexp #px"(\\w+) got (\\w+)" (list _ c2 v2)) _ ...)
             _ ...)
       (check-not-equal? c1 c2 "both consumers reporting once")
       (check-equal? v1 v2 "both consumers receiving the same value")]
      [_ (fail "no consumer recieves found")]))
      
  (test-case "mvar tests"
    ;; These generally test the *-evt values/functions since they can easily be
    ;; used with a timeout if they have a deadlock, and the non evt versions are
    ;; trivial.
    (test-case "mvar-try-get empty"
      (define mv (make-mvar))
      (check-false (mvar-try-get mv)))

    (test-case "mvar-try-get full"
      (define mv (make-mvar #t))
      (check-true (mvar-try-get mv)))

    (test-case "mvar-put! / mvar-take!"
      (define mv (make-mvar))
      (mvar-put! mv 42)
      (check-equal? (sync/timeout #f (mvar-take!-evt mv)) 42)
      (check-false (mvar-try-get mv)))
  
    (test-case "mvar-put! full"
      (define mv (make-mvar 42))
      (check-exn exn:fail:mvar? (λ () (mvar-put! mv 43))))
     
    (test-case "mvar-swap!"
      (define mv (make-mvar 42))
      (check-not-false (sync/timeout 0 (mvar-swap!-evt mv 101)))
      (check-equal? (mvar-try-get mv) 101))

    (test-case "mvar-update!-evt"
      (define mv (make-mvar 42))
      (check-equal? (sync/timeout 0 (mvar-update!-evt mv add1)) 42)
      (check-equal? (mvar-try-get mv) 43))

    (test-case "mvar-update!-evt error"
      (define mv (make-mvar 42))
      (check-exn exn:fail?
                 (λ () (sync/timeout 0 (mvar-update!-evt mv (λ (v) (error 'oops "oops"))))))
      (check-equal? (mvar-try-get mv) 42))))
