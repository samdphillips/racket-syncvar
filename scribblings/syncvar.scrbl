#lang scribble/manual

@(require
   (for-label racket
              syncvar
              syncvar/ivar
              syncvar/mvar))

@title{syncvar: a library of synchronous variables}
@author[(author+email "Sam Phillips" "samdphillips@gmail.com")]

@(when (equal? ".github/workflows/docs.yml" (getenv "GITHUB_WORKFLOW"))
   @para{@bold{WARNING!}  This documentation is for the development version of
         @racket[keyring].  Release documentation is at
         @(let ([x "https://docs.racket-lang.org/syncvar/index.html"]) (link x x)).})

The @racket[syncvar] library is a library to access synchronous variables
inspired by @link["http://cml.cs.uchicago.edu/pages/sync-var.html"]{CML}.

@section{Reference}
@defmodule[syncvar]

This library primarily provides @link["https://en.wikipedia.org/wiki/Id_(programming_language)"]{Id style}
synchronous variable.  These variables have two states: empty and full.  When a
thread attempts to read a variable that is empty the thread will block until it
is full.  Any attempt to write a value to a full variable will raise an
exception.

@subsection{IVars}
@defmodule[syncvar/ivar]

An @deftech{ivar} is a write once synchronous variables.  Once an ivar is in the
full state it cannot go back to the empty state.

In addition to its use with ivar-specific procedures, an ivar can be used as a
@tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{synchronizable event}.
An ivar is ready for synchronization when @racket[ivar-get] would not block; the
synchronization result is the same as the @racket[ivar-get] result.

@defproc[(ivar? [v any/c]) boolean?]{
   Returns @racket[#t] if @racket[v] is a @tech{ivar}, @racket[#f] otherwise.
}

@defproc[(make-ivar) ivar?]{
   Creates an ivar in the empty state.
}

@defproc[(ivar-put!    [an-ivar ivar?] [v any/c]) any]{
   Transitions @racket[an-ivar] from the empty state to the full state, storing
   @racket[v] in it and unblocking any threads waiting to read it.  If
   @racket[an-ivar] is already in the full state raises an exception.
}

@defproc[(ivar-get     [an-ivar ivar?]) any]
@defproc[(ivar-try-get [an-ivar ivar?]) any]
@defproc[(ivar-get-evt [an-ivar ivar?]) evt?]
@defproc[(exn:fail:ivar? [v any/c]) boolean?]{
   A predicate for recognizing exceptions raised when a thread attempts to
   @racket[ivar-put!] a full ivar.
}

@subsection{MVars}
@defmodule[syncvar/mvar]

A @deftech{mvar} is a mutable synchronous variable.

@defproc[(mvar? [v any/c]) boolean?]{
   Returns @racket[#t] if @racket[v] is a @tech{mvar}, @racket[#f] otherwise.
}

@defproc[(make-mvar [initial-value any/c undefined]) mvar?]{
   Creates a mvar.  If @racket[initial-value] is specified then the mvar will be
   in the full state, otherwise it will be empty.
}

@defproc[(mvar-put! [a-mvar mvar?] [v any/c]) void?]{
   Transitions @racket[a-mvar] from the empty state to the full state, storing
   @racket[v] in it and unblocking any threads waiting to read it.  If
   @racket[a-mvar] is already in the full state raises an exception.
}

@defproc[(mvar-take! [a-mvar mvar?]) any]{
   Waits until @racket[a-mvar] is in a full state, and then transitions it back
   to the empty state and returns the stored value.
}

@defproc[(mvar-try-take! [a-mvar mvar?]) any]{
   If @racket[a-mvar] is in the full state, transitions it to the empty state
   and returns the stored value; otherwise, return @racket[#f].
}

@defproc[(mvar-get [a-mvar mvar?]) any]{
   Waits until @racket[a-mvar] is in the full state and returns the stored value.
}

@defproc[(mvar-try-get [a-mvar mvar?]) any]{
   If @racket[a-mvar] is in the full state return the stored value, otherwise
   returns @racket[#f].
}

@defproc[(mvar-swap!       [a-mvar mvar?] [v any/c]) any]
@defproc[(mvar-update!     [a-mvar mvar?] [f (-> any/c any)]) any]
@defproc[(mvar-take!-evt   [a-mvar mvar?]) evt?]
@defproc[(mvar-get-evt     [a-mvar mvar?]) evt?]
@defproc[(mvar-swap!-evt   [a-mvar mvar?]) evt?]
@defproc[(mvar-update!-evt [a-mvar mvar?] [f (-> any/c any)]) evt?]

@defproc[(exn:fail:mvar? [v any/c]) boolean?]{
   A predicate for recognizing exceptions raised when a thread attempts to
   @racket[mvar-put!] a full mvar.
}