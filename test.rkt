#lang racket/base

(module+ test
  (require racket/match
           racket/promise
           rackunit
           syncvar)
  
  (define (end-trace? m)
    (match m [(vector 'warning _ ...) #t] [_ #f]))

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
                          (log-producer-error "~a ivar errored" i)
                          (raise e))])
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
      [_ (fail "no consumer recieves found")])))
