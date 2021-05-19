(defsystem "cblas"
  :pathname ""
  :licence "MIT"
  :depends-on ("uiop"
               "cffi"
               "cl-autowrap")
  :components ((:file "cblas")))

