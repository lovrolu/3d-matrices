#|
 This file is a part of 3d-matrices
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.flare.matrix)

(define-ofun midentity (n)
  (case n
    (2 (mat2 '(1 0
               0 1)))
    (3 (mat3 '(1 0 0
               0 1 0
               0 0 1)))
    (4 (mat4 '(1 0 0 0
               0 1 0 0
               0 0 1 0
               0 0 0 1)))
    (T (let ((mat (matn n n)))
         (dotimes (i n mat)
           (setf (mcrefn mat i i) 1))))))

(declaim (ftype (function (mat mat-dim) vec) mcol))
(define-ofun mcol (mat n)
  (etypecase mat
    (mat2 (vec2 (mcref2 mat n 0)
                (mcref2 mat n 1)))
    (mat3 (vec3 (mcref3 mat n 0)
                (mcref3 mat n 1)
                (mcref3 mat n 2)))
    (mat4 (vec4 (mcref4 mat n 0)
                (mcref4 mat n 1)
                (mcref4 mat n 2)
                (mcref4 mat n 3)))))

(declaim (ftype (function (vec mat mat-dim) vec) (setf mcol)))
(define-ofun (setf mcol) (vec mat n)
  (etypecase mat
    (mat2
     (setf (mcref2 mat n 0) (vx vec))
     (setf (mcref2 mat n 1) (vy vec)))
    (mat3
     (setf (mcref3 mat n 0) (vx vec))
     (setf (mcref3 mat n 1) (vy vec))
     (setf (mcref3 mat n 2) (vz vec)))
    (mat4
     (setf (mcref4 mat n 0) (vx vec))
     (setf (mcref4 mat n 1) (vy vec))
     (setf (mcref4 mat n 2) (vz vec))
     (setf (mcref4 mat n 3) (vw vec))))
  vec)

(declaim (ftype (function (mat mat-dim) vec) mrow))
(defun mrow (mat n)
  (etypecase mat
    (mat2 (vec2 (mcref2 mat 0 n)
                (mcref2 mat 1 n)))
    (mat3 (vec3 (mcref3 mat 0 n)
                (mcref3 mat 1 n)
                (mcref3 mat 2 n)))
    (mat4 (vec4 (mcref4 mat 0 n)
                (mcref4 mat 1 n)
                (mcref4 mat 2 n)
                (mcref4 mat 3 n)))))

(declaim (ftype (function (vec mat mat-dim) vec) (setf mrow)))
(defun (setf mrow) (vec mat n)
  (etypecase mat
    (mat2
     (setf (mcref2 mat 0 n) (vx vec))
     (setf (mcref2 mat 1 n) (vy vec)))
    (mat3
     (setf (mcref3 mat 0 n) (vx vec))
     (setf (mcref3 mat 1 n) (vy vec))
     (setf (mcref3 mat 2 n) (vz vec)))
    (mat4
     (setf (mcref4 mat 0 n) (vx vec))
     (setf (mcref4 mat 1 n) (vy vec))
     (setf (mcref4 mat 2 n) (vz vec))
     (setf (mcref4 mat 3 n) (vw vec))))
  vec)

(defmacro %2mat-op (a b c m2 m3 m4 mnmn mnr)
  (let ((m2 (if (listp m2) m2 (list m2)))
        (m3 (if (listp m3) m3 (list m3)))
        (m4 (if (listp m4) m4 (list m4))))
    (flet ((unroll (size ref &optional constant)
             (loop for i from 0 below size
                   collect `(,c (,ref a ,i) ,(if constant 'b `(,ref b ,i))))))
      `(etypecase ,a
         (real (let ((,b (ensure-float ,a))
                     (,a ,b))
                 (etypecase ,a
                   (mat4 (,@m4 ,@(unroll 16 'miref4 T)))
                   (mat3 (,@m3 ,@(unroll 9 'miref3 T)))
                   (mat2 (,@m2 ,@(unroll 4 'miref2 T)))
                   (matn ,mnr))))
         (mat4 (etypecase b
                 (real (let ((b (ensure-float b))) (,@m4 ,@(unroll 16 'miref4 T))))
                 (mat4 (,@m4 ,@(unroll 16 'miref4)))))
         (mat3 (etypecase b
                 (real (let ((b (ensure-float b))) (,@m4 ,@(unroll 9 'miref3 T))))
                 (mat3 (,@m3 ,@(unroll 9 'miref3)))))
         (mat2 (etypecase b
                 (real (let ((b (ensure-float b))) (,@m4 ,@(unroll 4 'miref2 T))))
                 (mat2 (,@m2 ,@(unroll 4 'miref2)))))
         (matn (etypecase b
                 (real (let ((b (ensure-float b)))
                         ,mnr))
                 (mat
                  (assert (and (= (mcols a) (mcols b))
                               (= (mrows a) (mrows b))))
                  ,mnmn)))))))

(defmacro define-matcomp (name op)
  (let ((2mat-name (intern (format NIL "~a-~a" '2mat name))))
    `(progn
       (declaim (inline ,2mat-name))
       (declaim (ftype (function ((or mat real) (or mat real)) boolean) ,2mat-name))
       (declaim (ftype (function ((or mat real) &rest (or mat real)) boolean) ,name))
       (define-ofun ,2mat-name (a b)
         (%2mat-op a b ,op and and and
             (loop for i from 0 below (* (%cols a) (%rows a))
                   always (,op (mirefn a i) (mirefn b i)))
             (loop for i from 0 below (* (%cols a) (%rows a))
                   always (,op (mirefn a i) b))))
       (define-ofun ,name (val &rest vals)
         (loop for prev = val then next
               for next in vals
               always (,2mat-name prev next)))
       (define-compiler-macro ,name (val &rest vals)
         (case (length vals)
           (0 T)
           (1 `(,',2mat-name ,val ,(first vals)))
           (T `(and ,@(loop for prev = val then next
                            for next in vals
                            collect `(,',2mat-name ,prev ,next)))))))))

(define-matcomp m= =)
(define-matcomp m/= /=)
(define-matcomp m< <)
(define-matcomp m> >)
(define-matcomp m<= <=)
(define-matcomp m>= >=)

(defmacro define-matop (name nname op)
  (let ((2mat-name (intern (format NIL "~a-~a" '2mat name))))
    `(progn
       (declaim (inline ,name ,2mat-name))
       (declaim (ftype (function ((or vec real) &rest (or vec real)) vec) ,name))
       (declaim (ftype (function ((or vec real) (or vec real)) vec) ,2mat-name))
       (define-ofun ,2mat-name (a b)
         (%2mat-op a b ,op mat mat mat
             (let ((mat (matn (%cols a) (%rows a))))
               (loop for i from 0 below (* (%cols mat) (%rows mat))
                     do (setf (mirefn mat i) (,op (mirefn a i) (mirefn b i)))))
             (let ((mat (matn (%cols a) (%rows a))))
               (loop for i from 0 below (* (%cols mat) (%rows mat))
                     do (setf (mirefn mat i) (,op (mirefn a i) b))))))
       (define-ofun ,name (val &rest vals)
         (cond ((cdr vals)
                (apply #',nname (,2mat-name val (first vals)) (rest vals)))
               (vals (,2mat-name val (first vals)))
               (T (mapply val ,op))))
       (define-compiler-macro ,name (val &rest vals)
         (case (length vals)
           (0 `(vapply ,val ,',op))
           (1 `(,',2mat-name ,val ,(first vals)))
           (T `(,',nname (,',2mat-name ,val ,(first val)) ,@(rest vals))))))))

(defmacro define-nmatop (name op)
  (let ((2mat-name (intern (format NIL "~a-~a" '2mat name))))
    `(progn
       (declaim (inline ,name ,2mat-name))
       (declaim (ftype (function ((or vec real) &rest (or vec real)) vec) ,name))
       (declaim (ftype (function ((or vec real) (or vec real)) vec) ,2mat-name))
       (define-ofun ,2mat-name (a b)
         (%2mat-op a b ,op mat mat mat
             (loop for i from 0 below (* (%cols a) (%rows a))
                   do (setf (mirefn a i) (,op (mirefn a i) (mirefn b i))))
             (loop for i from 0 below (* (%cols a) (%rows a))
                   do (setf (mirefn a i) (,op (mirefn a i) b)))))
       (define-ofun ,name (val &rest vals)
         (if vals
             (loop for v in vals
                   do (,2mat-name val v)
                   finally (return val))
             (mapplfy val ,op)))
       (define-compiler-macro ,name (val &rest vals)
         (case (length vals)
           (0 `(vapplyf ,val ,',op))
           (1 `(,',2mat-name ,val ,(first vals)))
           (T `(,',name (,',2mat-name ,val ,(first val)) ,@(rest vals))))))))

(define-matop m+ nm+ +)
(define-matop m- nm- -)
(define-matop m* nm* *)
(define-matop m/ nm/ /)
(define-nmatop nm+ +)
(define-nmatop nm- -)
(define-nmatop nm* *)
(define-nmatop nm/ /)

(defun mapply (mat op)
  (etypecase mat
    (mat2 (let ((m (mat2))) (map-into (%marr2 m) op (%marr2 mat)) m))
    (mat3 (let ((m (mat3))) (map-into (%marr3 m) op (%marr3 mat)) m))
    (mat4 (let ((m (mat4))) (map-into (%marr4 m) op (%marr4 mat)) m))
    (matn (let ((m (matn (%cols mat) (%rows mat))))
            (map-into (%marrn m) op (%marrn mat))
            m))))

(defun mapplyf (mat op)
  (etypecase mat
    (mat2 (map-into (%marr2 mat) op (%marr2 mat)) mat)
    (mat3 (map-into (%marr3 mat) op (%marr3 mat)) mat)
    (mat4 (map-into (%marr4 mat) op (%marr4 mat)) mat)
    (matn (map-into (%marrn mat) op (%marrn mat)) mat)))

;; TODO
;; + - * /
;; determinant
;; inverses
;; transpose
;; adjoint
;; trace
;; upper-triangular
;; lower-triangular
;; diagonal
;; upgrade, downgrade
;; head, tail, left, right, segment, block, corners
;; LU, QR, eigenvalues
