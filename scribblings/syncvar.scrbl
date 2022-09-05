#lang scribble/manual

@(require
   (for-label racket
              syncvar))

@title{syncvar: a library of synchronous variables}
@author[(author+email "Sam Phillips" "samdphillips@gmail.com")]

@(when (equal? ".github/workflows/docs.yml" (getenv "GITHUB_WORKFLOW"))
   @para{@bold{WARNING!}  This documentation is for the development version of
         @racket[keyring].  Release documentation is at
         @(let ([x "https://docs.racket-lang.org/syncvar/index.html"]) (link x x)).})

The @racket[syncvar] library is a library to access synchronous variables
inspired by @link["http://cml.cs.uchicago.edu/pages/sync-var.html"]{CML}.

