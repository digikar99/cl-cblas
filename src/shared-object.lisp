(cl:in-package :cl)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (do-symbols (s (find-package :cblas))
    (when (or (and (not (fboundp s))
                   (not (boundp s)))
              (and (fboundp s)
                   (alexandria:starts-with-subseq "__" (symbol-name s))))
      (unintern s :cblas))))

(in-package :cblas)

(cl:let ((shared-library-pathname
           #+x86-64 #p"/usr/lib/x86_64-linux-gnu/libopenblas.so.0"
           #+arm64 #p"/usr/lib/aarch64-linux-gnu/libopenblas.so"
           #-(or x86-64 arm64) "libopenblas.so"))
  (cl:assert (cl:probe-file shared-library-pathname)
             (shared-library-pathname)
             "Could not find the CBLAS library at~%~%~S" shared-library-pathname)
  (cffi:load-foreign-library shared-library-pathname))
