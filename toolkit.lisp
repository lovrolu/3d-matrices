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
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *matrix-limit* (min (floor (sqrt array-dimension-limit))
                              (floor (sqrt most-positive-fixnum)))))

(defvar *eps* (ecase *float-type*
                (single-float 0.00001s0)
                (double-float 0.00000000001d0)))
(declaim (type #.*float-type* *eps*))

(deftype mat-dim ()
  '(integer 0 #.(1- *matrix-limit*)))

(deftype float-type ()
  '#.*float-type*)

(defmacro define-ofun (name args &body body)
  `(defun ,name ,args
     (declare (optimize (compilation-speed 0) (debug 1) (safety 1) speed))
     ,@body))

(declaim (inline ensure-float))
(declaim (ftype (function (real) #.*float-type*)))
(defun ensure-float (thing)
  (declare (optimize (speed 1)))
  (coerce thing '#.*float-type*))

(defun ensure-float-param (val env)
  (if (constantp val env)
      (typecase val
        (real (ensure-float val))
        (T `(load-time-value (ensure-float ,val))))
      `(locally (declare (optimize (speed 1)))
         (coerce ,val ',*float-type*))))

(declaim (inline ensure-function))
(defun ensure-function (functionish)
  (etypecase functionish
    (function functionish)
    (symbol (fdefinition functionish))))

(declaim (ftype (function (float-type float-type) boolean) ~=))
(declaim (inline ~=))
(defun ~= (a b)
  (< (abs (- a b)) *eps*))

(defmacro with-floats (&environment env bindings &body body)
  `(let ,(loop for (var val) in bindings
               collect `(,var (the ,*float-type* ,(ensure-float-param val env))))
     ,@body))

(defmacro defsetf* (name args values &body body)
  #-(or ecl ccl)
  `(defsetf ,name ,args ,values ,@body)
  #+(or ecl ccl) ;; Compiler bug workarounds, hooray.
  (if (eql (first args) '&environment)
      `(defsetf ,name ,(cddr args) ,values
         (let (,(second args)) ,@body))
      `(defsetf ,name ,args ,values ,@body)))
