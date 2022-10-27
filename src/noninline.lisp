(cl:in-package :cblas)

(autowrap:c-include (cl:merge-pathnames #P"specs/cblas.h" *src-dir*)
                    :spec-path
                    (cl:merge-pathnames #P"specs/" *src-dir*)
                    :c-to-lisp-function #'cblas-c-to-lisp
                    :include-definitions #'starts-with-cblas)
