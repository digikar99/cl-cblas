(defsystem "cblas"
  :pathname ""
  :author "Shubhamkar B. Ayare (shubhamayare@yahoo.co.in)"
  :description "A cl-autowrap generated wrapper around CBLAS which provides a C interface to the Basic Linear Algebra Subprograms."
  :license "MIT"
  :depends-on ("uiop"
               "cffi"
               "cl-autowrap")
  :serial t
  :components ((:module "specs"
                :components ((:static-file "cblas.aarch64-pc-linux-gnu.spec")
                             (:static-file "cblas.aarch64-unknown-linux-android.spec")
                             (:static-file "cblas.arm-pc-linux-gnu.spec")
                             (:static-file "cblas.arm-unknown-linux-androideabi.spec")
                             (:static-file "cblas.i386-unknown-freebsd.spec")
                             (:static-file "cblas.i386-unknown-openbsd.spec")
                             (:static-file "cblas.i686-apple-darwin9.spec")
                             (:static-file "cblas.i686-pc-linux-gnu.spec")
                             (:static-file "cblas.i686-pc-windows-msvc.spec")
                             (:static-file "cblas.i686-unknown-linux-android.spec")
                             (:static-file "cblas.x86_64-apple-darwin9.spec")
                             (:static-file "cblas.x86_64-pc-linux-gnu.spec")
                             (:static-file "cblas.x86_64-pc-windows-msvc.spec")
                             (:static-file "cblas.x86_64-unknown-freebsd.spec")
                             (:static-file "cblas.x86_64-unknown-linux-android.spec")
                             (:static-file "cblas.x86_64-unknown-openbsd.spec")))
               (:module "src"
                :serial t
                :components ((:file "package")
                             (:file "noninline")
                             ;; FIXME: Simplify after autowrap adds an inline option
                             (:file "inline-declarations")
                             (:file "inline")
                             (:file "shared-object")))))
