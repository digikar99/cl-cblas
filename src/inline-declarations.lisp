(cl:in-package :cl)

(do-symbols (s (find-package :cblas))
  (when (and (fboundp s)
             (not (member s '(cblas::cblas-c-to-lisp cblas::starts-with-cblas))))
    (fmakunbound s)
    (proclaim `(inline ,s))))
