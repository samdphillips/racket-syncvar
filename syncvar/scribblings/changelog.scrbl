#lang scribble/manual

@(require
   (for-label syncvar
              syncvar/ivar
              syncvar/mvar))

@title{Changelog}

@section{0.9.3}
Release date: 2023/06/07
@itemlist[
  @item{Fix behavior in @racket[mvar-update!-evt] when running the update
        function resulted in an error.}
]

@section{0.9.2}
Release date: 2023/04/19
@itemlist[
  @item{Fixed bug in @racket[mvar-update!-evt] where the previous value was not
        returned.}
]

@section{0.9.1}
Release date: 2023/03/09
@itemlist[
  @item{Bumping version number to be valid.}
]

@section{0.9.0}
Release date: 2022/12/29
@itemlist[
  @item{Initial package server release.}
]
