(cl:in-package :cl)

(defpackage :cblas (:use))
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun cblas::cblas-c-to-lisp (name)
    (autowrap:default-c-to-lisp
     (cl:if (and (< 5 (length name))
                 (string-equal "CBLAS"
                               (subseq name 0 5)))
            (subseq name 6)
            name))))


(cl:in-package :cblas)
;; FIXME Avoid hardcoding the path
(autowrap:c-include #+x86-64 #P"/usr/include/x86_64-linux-gnu/cblas.h"
		            #+arm64 #P"/usr/include/aarch64-linux-gnu/cblas.h"
                    :spec-path
                    (cl:merge-pathnames #P"specs/"
                                        (asdf:component-pathname (asdf:find-system "cblas")))
                    :c-to-lisp-function #'cblas-c-to-lisp
                    :release-p cl:t)

(cl:in-package :cl)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (do-symbols (s (find-package :cblas))
    (when (fboundp s)
      (proclaim `(inline ,s)))))


(cl:in-package :cblas)
(autowrap:c-include #+x86-64 #P"/usr/include/x86_64-linux-gnu/cblas.h"
		    #+arm64 #P"/usr/include/aarch64-linux-gnu/cblas.h"
                    :spec-path
                    (cl:merge-pathnames #P"specs/"
                                        (asdf:component-pathname (asdf:find-system "cblas")))
                    :c-to-lisp-function #'cblas-c-to-lisp
                    :release-p cl:t)

;; The first is slower on the author's PC :/ - 10 times as slower as numpy
;; (cffi:load-foreign-library #p"/usr/lib/x86_64-linux-gnu/libblas.so")
;; The second is fast, much faster :D - at par with numpy
(cffi:load-foreign-library #+x86-64 #p"/usr/lib/x86_64-linux-gnu/libopenblas.so.0"
                           #+arm64 #p"/usr/lib/aarch64-linux-gnu/libopenblas.so")
;; The miniconda equivalents aren't faster than this for DN:SUM
