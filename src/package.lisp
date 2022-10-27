(cl:in-package :cl)
(defpackage :cblas (:use))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar cblas::*src-dir* (asdf:component-pathname (asdf:find-system "cblas")))
  (defun cblas::cblas-c-to-lisp (name)
    (autowrap:default-c-to-lisp
     (if (or (< (length name) 5)
             (not (string-equal "CBLAS"
                                (subseq name 0 5))))
         name
         (cond ((char-equal #\_ (char name 5))
                (subseq name 6))
               (t
                (subseq name 5))))))
  (defun cblas::starts-with-cblas (name)
    (alexandria:starts-with-subseq "CBLAS_" (symbol-name name)))
  (defun cblas::does-not-start-with-cblas (name)
    (not (alexandria:starts-with-subseq "CBLAS_" (symbol-name name)))))
