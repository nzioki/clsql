;;;; -*- Mode: LISP; Syntax: ANSI-Common-Lisp; Base: 10 -*-
;;;; *************************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          postgresql-socket-package.cl
;;;; Purpose:       Package definition for PostgreSQL interface using sockets
;;;; Programmers:   Kevin M. Rosenberg
;;;; Date Started:  Feb 2002
;;;;
;;;; $Id: postgresql-socket-package.cl,v 1.5 2002/04/06 20:47:29 kevin Exp $
;;;;
;;;; This file, part of CLSQL, is Copyright (c) 2002 by Kevin M. Rosenberg
;;;;
;;;; CLSQL users are granted the rights to distribute and use this software
;;;; as governed by the terms of the Lisp Lesser GNU Public License
;;;; (http://opensource.franz.com/preamble.html), also known as the LLGPL.
;;;; *************************************************************************

(declaim (optimize (debug 3) (speed 3) (safety 1) (compilation-speed 0)))
(in-package :cl-user)

#+lispworks (require "comm")

(defpackage :postgresql-socket
  (:use :common-lisp)
  (:export #:pgsql-ftype
	   #:pgsql-ftype#bytea
	   #:pgsql-ftype#int2
	   #:pgsql-ftype#int4
	   #:pgsql-ftype#int8
	   #:pgsql-ftype#float4
   	   #:pgsql-ftype#float8

	   #:+crypt-library+
	   #:postgresql-condition
	   #:postgresql-condition-connection
	   #:postgresql-condition-message
	   #:postgresql-error
	   #:postgresql-fatal-error
	   #:postgresql-login-error
	   #:postgresql-warning
	   #:postgresql-notification
	   #:postgresql-connection
	   #:postgresql-connection-p
	   #:postgresql-cursor
	   #:postgresql-cursor-p
	   #:postgresql-cursor-connection
	   #:postgresql-cursor-name
	   #:postgresql-cursor-fields
	   #:+postgresql-server-default-port+
	   #:open-postgresql-connection
	   #:reopen-postgresql-connection
	   #:close-postgresql-connection
	   #:postgresql-connection-open-p
	   #:ensure-open-postgresql-connection
	   #:start-query-execution
	   #:wait-for-query-results
	   #:read-cursor-row
	   #:copy-cursor-row
	   #:skip-cursor-row
	   ))

