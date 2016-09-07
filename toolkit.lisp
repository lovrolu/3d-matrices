#|
 This file is a part of 3d-matrices
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.flare.matrix)

#+3d-vectors-double-floats (pushnew :3d-vectors-double-floats *features*)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *float-type*
    #+3d-vectors-double-floats 'double-float
    #-3d-vectors-double-floats 'single-float))

;; We choose this limit in order to ensure that matrix indices
;; always remain within fixnum range. I'm quite certain you don't
;; want to use matrices as big as this allows anyway. You'll want
;; BLAS/LAPACK and/or someone much smarter than me for that.
(defvar *matrix-limit* (min (floor (sqrt array-dimension-limit))
                            (floor (sqrt most-positive-fixnum))))

(defmacro define-ofun (name args &body body)
  `(defun ,name ,args
     (declare (optimize (compilation-speed 0) (debug 0) (safety 1) (space 3) speed))
     ,@body))

(declaim (inline ensure-float))
(declaim (ftype (function (real) #.*float-type*)))
(defun ensure-float (thing)
  (coerce thing '#.*float-type*))

(defun ensure-float-param (val env)
  (if (constantp val env)
      (typecase val
        (real (ensure-float val))
        (T `(load-time-value (ensure-float ,val))))
      `(ensure-float ,val)))