;; -*- mode: emacs-lisp; lexical-binding: t -*-

(require 'user-custom-functions)

(custom/load-dynamic-module :module-name "bootstrap")

(defun c-ext/bootstrap/hello ()
  (unless (boundp '--c-ext-bootstrap--hello-fn)
    (error "C extension 'bootstrap' is not loaded"))
  (funcall --c-ext-bootstrap--hello-fn))
