#|
 This file is a part of 3d-matrices
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.flare.matrix)

(define-ofun map-mat-diag (function mat)
  (let ((function (ensure-function function)))
    (flet ((iter (arr s)
             (dotimes (i s)
               (funcall function i (aref arr i)))))
      (declare (inline iter))
      (etypecase mat
        (mat2 (iter (marr2 mat) 2))
        (mat3 (iter (marr3 mat) 3))
        (mat4 (iter (marr4 mat) 4))
        (matn (iter (marrn mat) (min (%rows mat) (%cols mat))))))))

(define-ofun map-mat-index (function mat)
  (let ((function (ensure-function function)))
    (flet ((iter (arr s)
             (dotimes (i s)
               (funcall function i (aref arr i)))))
      (declare (inline iter))
      (etypecase mat
        (mat2 (iter (marr2 mat) 4))
        (mat3 (iter (marr3 mat) 9))
        (mat4 (iter (marr4 mat) 16))
        (matn (iter (marrn mat) (* (%rows mat) (%cols mat))))))))

(defmacro do-mat-diag ((i el mat &optional result) &body body)
  (let ((arr (gensym "ARRAY"))
        (s (gensym "SIZE"))
        (m (gensym "MATRIX"))
        (iter (gensym "ITERATOR")))
    `(flet ((,iter (,arr ,s)
              (dotimes (,i ,s ,result)
                (declare (ignorable ,i))
                (symbol-macrolet ((,el (aref ,arr (+ ,i (* ,i ,s)))))
                  ,@body))))
       (declare (inline ,iter))
       (let ((,m ,mat))
         (etypecase ,m
           (mat2 (,iter (marr2 ,m) 2))
           (mat3 (,iter (marr3 ,m) 3))
           (mat4 (,iter (marr4 ,m) 4))
           (matn (,iter (marrn ,m) (min (%rows ,m) (%cols ,m)))))))))

(defmacro do-mat-index ((i el mat &optional result) &body body)
  (let ((arr (gensym "ARRAY"))
        (s (gensym "SIZE"))
        (m (gensym "MATRIX"))
        (iter (gensym "ITERATOR")))
    `(flet ((,iter (,arr ,s)
              (dotimes (,i ,s ,result)
                (declare (ignorable ,i))
                (symbol-macrolet ((,el (aref ,arr ,i)))
                  ,@body))))
       (declare (inline ,iter))
       (let ((,m ,mat))
         (etypecase ,m
           (mat2 (,iter (marr2 ,m) 4))
           (mat3 (,iter (marr3 ,m) 9))
           (mat4 (,iter (marr4 ,m) 16))
           (matn (,iter (marrn ,m) (* (%rows ,m) (%cols ,m)))))))))