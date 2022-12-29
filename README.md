# syncvar: a library of synchronous variables

The `syncvar` library is a library to access synchronous variables
inspired by [CML](http://cml.cs.uchicago.edu/pages/sync-var.html).

This library primarily provides [Id
style](https://en.wikipedia.org/wiki/Id_(programming_language))
synchronous variables.  These variables have two states: empty and full.  When a
thread attempts to read a variable that is empty the thread will block until it
is full.  Any attempt to write a value to a full variable will raise an
exception.

## Changelog

### 0.9.0

Release date: 2022/12/29

* Initial package server release.
