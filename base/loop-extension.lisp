;;;; -*- Mode: LISP; Syntax: ANSI-Common-Lisp; Base: 10 -*-
;;;; *************************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          loop-extension.lisp
;;;; Purpose:       Extensions to the Loop macro for CMUCL
;;;; Programmer:    Pierre R. Mai
;;;;
;;;; Copyright (c) 1999-2001 Pierre R. Mai
;;;;
;;;; $Id$
;;;;
;;;; The functions in this file were orignally distributed in the
;;;; MaiSQL package in the file sql/sql.cl
;;;; *************************************************************************

(in-package #:cl-user)

;;;; MIT-LOOP extension

#+sbcl 
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defpackage #:ansi-loop 
    (:import-from #:sb-loop 
		  #:loop-error
		  #:*loop-epilogue*
		  #:*loop-ansi-universe* 
		  #:add-loop-path)))

#+lispworks
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defpackage #:ansi-loop 
    (:import-from #:loop
		  #:*epilogue*)))

#+allegro
(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package '#:ansi-loop)
    (let ((excl::*enable-package-locked-errors* nil))
      (rename-package '#:excl '#:excl
		      (cons '#:ansi-loop
			    (package-nicknames (find-package '#:excl)))))))

#+lispworks
(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package '#:ansi-loop)
    (rename-package '#:loop '#:loop
		    (cons '#:ansi-loop
			  (package-nicknames (find-package '#:loop))))))

#+(or sbcl lispworks)
(defun ansi-loop::loop-gentemp (&optional (pref 'loopva-))
  (gensym (string pref)))

#+(or cmu scl sbcl openmcl allegro)
(defun loop-record-iteration-path (variable data-type prep-phrases)
  (let ((in-phrase nil)
	(from-phrase nil))
    (loop for (prep . rest) in prep-phrases
	  do
	  (case prep
	    ((:in :of)
	     (when in-phrase
	       (ansi-loop::loop-error
		"Duplicate OF or IN iteration path: ~S." (cons prep rest)))
	     (setq in-phrase rest))
	    ((:from)
	     (when from-phrase
	       (ansi-loop::loop-error
		"Duplicate FROM iteration path: ~S." (cons prep rest)))
	     (setq from-phrase rest))
	    (t
	     (ansi-loop::loop-error
	      "Unknown preposition: ~S." prep))))
    (unless in-phrase
      (ansi-loop::loop-error "Missing OF or IN iteration path."))
    (unless from-phrase
      (setq from-phrase '(clsql-base-sys:*default-database*)))
    (cond
      ((consp variable)
       (let ((query-var (ansi-loop::loop-gentemp 'loop-record-))
	     (db-var (ansi-loop::loop-gentemp 'loop-record-database-))
	     (result-set-var (ansi-loop::loop-gentemp
			      'loop-record-result-set-))
	     (step-var (ansi-loop::loop-gentemp 'loop-record-step-)))
	 (push `(when ,result-set-var
		 (clsql-base-sys:database-dump-result-set ,result-set-var ,db-var))
	       ansi-loop::*loop-epilogue*)
	 `(((,variable nil ,data-type) (,query-var ,(first in-phrase))
	    (,db-var ,(first from-phrase))
	    (,result-set-var nil)
	    (,step-var nil))
	   ((multiple-value-bind (%rs %cols)
		(clsql-base-sys:database-query-result-set ,query-var ,db-var)
	      (setq ,result-set-var %rs ,step-var (make-list %cols))))
	   ()
	   ()
	   (not (clsql-base-sys:database-store-next-row ,result-set-var ,db-var ,step-var))
	   (,variable ,step-var)
	   (not ,result-set-var)
	   ()
	   (not (clsql-base-sys:database-store-next-row ,result-set-var ,db-var ,step-var))
	   (,variable ,step-var))))
      (t
       (let ((query-var (ansi-loop::loop-gentemp 'loop-record-))
	     (db-var (ansi-loop::loop-gentemp 'loop-record-database-))
	     (result-set-var (ansi-loop::loop-gentemp
			      'loop-record-result-set-)))
	 (push `(when ,result-set-var
		 (clsql-base-sys:database-dump-result-set ,result-set-var ,db-var))
	       ansi-loop::*loop-epilogue*)
	 `(((,variable nil ,data-type) (,query-var ,(first in-phrase))
	    (,db-var ,(first from-phrase))
	    (,result-set-var nil))
	   ((multiple-value-bind (%rs %cols)
		(clsql-base-sys:database-query-result-set ,query-var ,db-var)
	      (setq ,result-set-var %rs ,variable (make-list %cols))))
	   ()
	   ()
	   (not (clsql-base-sys:database-store-next-row ,result-set-var ,db-var ,variable))
	   ()
	   (not ,result-set-var)
	   ()
	   (not (clsql-base-sys:database-store-next-row ,result-set-var ,db-var ,variable))
	   ()))))))

#+(or cmu scl sbcl openmcl allegro)
(ansi-loop::add-loop-path '(record records tuple tuples)
			  'loop-record-iteration-path
			  ansi-loop::*loop-ansi-universe*
			  :preposition-groups '((:of :in) (:from))
			  :inclusive-permitted nil)

#+lispworks (in-package loop)

#+lispworks
(cl-user::define-loop-method (record records tuple tuples) ansi-loop::clsql-loop-method (in of from))

#+lispworks
(defun ansi-loop::clsql-loop-method (method-name iter-var iter-var-data-type 
				     prep-phrases inclusive? allowed-preps 
				     method-specific-data)
  (let ((in-phrase nil)
	(from-phrase nil))
    (loop for (prep . rest) in prep-phrases
	  do
	  (cond
	    ((or (eq prep 'in) (eq prep 'of))
	     (when in-phrase
	       (error
		"Duplicate OF or IN iteration path: ~S." (cons prep rest)))
	     (setq in-phrase rest))
	    ((eq prep 'from)
	     (when from-phrase
	       (error
		"Duplicate FROM iteration path: ~S." (cons prep rest)))
	     (setq from-phrase rest))
	    (t
	     (error
	      "Unknown preposition: ~S." prep))))
    (unless in-phrase
      (error "Missing OF or IN iteration path."))
    (unless from-phrase
      (setq from-phrase '(clsql-base-sys:*default-database*)))
    (cond
      ((consp iter-var)
       (let ((query-var (ansi-loop::loop-gentemp 'loop-record-))
	     (db-var (ansi-loop::loop-gentemp 'loop-record-database-))
	     (result-set-var (ansi-loop::loop-gentemp
			      'loop-record-result-set-))
	     (step-var (ansi-loop::loop-gentemp 'loop-record-step-)))
	 #+ignore
	 (push `(when ,result-set-var
		 (clsql-base-sys:database-dump-result-set ,result-set-var ,db-var))
	       ansi-loop::*epilogue*)
	 `(((,iter-var nil ,iter-var-data-type) (,query-var ,(first in-phrase))
	    (,db-var ,(first from-phrase))
	    (,result-set-var nil)
	    (,step-var nil))
	   ((multiple-value-bind (%rs %cols)
		(clsql-base-sys:database-query-result-set ,query-var ,db-var)
	      (setq ,result-set-var %rs ,step-var (make-list %cols))))
	   ()
	   ()
	   (not (clsql-base-sys:database-store-next-row ,result-set-var ,db-var ,step-var))
	   (,iter-var ,step-var)
	   (not ,result-set-var)
	   ()
	   (not (clsql-base-sys:database-store-next-row ,result-set-var ,db-var ,step-var))
	   (,iter-var ,step-var))))
      (t
       (let ((query-var (ansi-loop::loop-gentemp 'loop-record-))
	     (db-var (ansi-loop::loop-gentemp 'loop-record-database-))
	     (result-set-var (ansi-loop::loop-gentemp
			      'loop-record-result-set-)))
	 #+ignore
	 (push `(when ,result-set-var
		 (clsql-base-sys:database-dump-result-set ,result-set-var ,db-var))
	       ansi-loop::*epilogue*)
	 `(((,iter-var nil ,iter-var-data-type) (,query-var ,(first in-phrase))
	    (,db-var ,(first from-phrase))
	    (,result-set-var nil))
	   ((multiple-value-bind (%rs %cols)
		(clsql-base-sys:database-query-result-set ,query-var ,db-var)
	      (setq ,result-set-var %rs ,iter-var (make-list %cols))))
	   ()
	   ()
	   (not (clsql-base-sys:database-store-next-row ,result-set-var ,db-var ,iter-var))
	   ()
	   (not ,result-set-var)
	   ()
	   (not (clsql-base-sys:database-store-next-row ,result-set-var ,db-var ,iter-var))
	   ()))))))



