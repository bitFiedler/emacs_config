;; -*- Mode: Emacs-Lisp -*-
;;--------------------------------------------------------------------
;;     PROJECT: Generic
;;   COPYRIGHT: Matthias Popp
;;    $RCSfile: $
;;   $Revision: $
;;      AUTHOR: Matthias Popp
;;  SUBSTITUTE: -
;;    LANGUAGE: elisp
;;    COMPILER: 
;; DESCRIPTION: This module defines font-lock keywords and regular
;;              expressions for ELMEG MPS CC c files. You can use
;;              these definitions in conjunction with font-lock.el to
;;              "fontify" c-language buffers.
;;
;;        $Log: $
;;
;;--------------------------------------------------------------------


;; Installation:
;;
;; Installation is simple: just put this file somewhere in your
;; load-path and put the following lines in your .emacs file:
;;
;; (autoload 'mps-mode "mps" nil t)
;; (setq auto-mode-alist (append (list (cons "\\.c$" 'mps-mode))
;;                               auto-mode-alist))
;;
;; If you have modified your startup file as described above, (x)emacs
;; should enter mps-mode whenever you load an *.asm file into emacs.
;;
;; If not, you will have to start mps-mode manually:
;;    M-x load-library mps
;;    M-x mps-mode

;; Code:


(defconst mps-mode-version "1.0"
  "Version of this mps mode.")

(defvar wpdl-mode-hook nil)


(defvar mps-mode-map
  (let ((mps-mode-map (make-sparse-keymap)))

;;; C-Mode Templates and C++-Mode Templates (uses C-Mode Templates also)
(setq tempo-interactive t)

(add-hook 'c-mode-hook '(lambda ()
                                (define-key c-mode-map [(M-return)] 'tempo-complete-tag)))
(add-hook 'c++-mode-hook '(lambda ()
                                (define-key c++-mode-map [(M-return)] 'tempo-complete-tag)))
(add-hook 'c-mode-hook '(lambda ()
			  (tempo-use-tag-list 'c-tempo-tags)
			  ))
(add-hook 'c++-mode-hook '(lambda ()
			    (tempo-use-tag-list 'c-tempo-tags)
			    (tempo-use-tag-list 'c++-tempo-tags)
			    ))

;;; Preprocessor Templates (appended to c-tempo-tags)

(defun template-insert-time (&optional format default)
  "Insert time into current buffer using time format FORMAT.
If FORMAT is not a string, it uses DEFAULT or `current-time-string'."
  (interactive)
  (insert (if (and (stringp format) (fboundp 'format-time-string))
	      (format-time-string format (current-time))
	    (or default (current-time-string)))))
(put 'template-insert-time 'template-secure-command
     (lambda (args)
       (or (null args) (and (stringp (car args)) (null (cdr args))))))


(setq _filename '((lambda ()(file-name-nondirectory (buffer-file-name)))))
(setq _creator  '(user-full-name))
(setq _author   '( user-full-name))
(setq _date     '(current-time-string))
(setq _year     '(template-insert-time "%Y" "0000"))
(setq _isodate  '(template-insert-time "%d-%m-%Y" "00-00-0000"))


(defvar mps-tempo-tags nil
  "Tempo tags for mps mode")

(setq tempo-interactive t)

(add-hook 'mps-mode-hook '(lambda ()
                                (define-key mps-mode-map [(M-return)] 'tempo-complete-tag)))
(add-hook 'mps-mode-hook '(lambda ()
			  (tempo-use-tag-list 'mps-tempo-tags)
			  ))

;;; Preprocessor Templates (appended to c-tempo-tags)

(defun template-insert-time (&optional format default)
  "Insert time into current buffer using time format FORMAT.
If FORMAT is not a string, it uses DEFAULT or `current-time-string'."
  (interactive)
  (insert (if (and (stringp format) (fboundp 'format-time-string))
	      (format-time-string format (current-time))
	    (or default (current-time-string)))))
(put 'template-insert-time 'template-secure-command
     (lambda (args)
       (or (null args) (and (stringp (car args)) (null (cdr args))))))


(setq _filename '((lambda ()(file-name-nondirectory (buffer-file-name)))))
(setq _creator  '(user-full-name))
(setq _author   '( user-full-name))
(setq _date     '(current-time-string))
(setq _year     '(template-insert-time "%Y" "0000"))
(setq _isodate  '(template-insert-time "%d-%m-%Y" "00-00-0000"))



;;; ========== mps defines ===============
(tempo-define-template "c-mpsh" 
		       '("/*~-*/ " n 
			 "/*~XSF_LANGUAGE: C/C++*/"  n 
			 ) 
		       "mpsh" 
		       "Insert a mps file header" 
		       'c-tempo-tags)

(tempo-define-template "cvsh" 
		       '(
			 "/*~A*/ "n
			 "/*~+:cvs header*/ "n
			 "/*~T*/ "n
			 "/* -----------------------------------------------------------------------"n
			 " * $RCSfile: $"n
			 " * $Source: $"n
			 " * $Author: $"n
			 " * $Revision: $"n
			 " * $Date: $"n
			 " * $State: $"n
			 " * $Name:  $"n
			 " * -----------------------------------------------------------------------"n
			 " * Initial Author: "_author" "n
			 " * Initial Date:   "_isodate" "n
			 " * -----------------------------------------------------------------------"n
			 " * Module Description: "(p "Description: " Description:)" "n
			 " * -----------------------------------------------------------------------"n
			 " */"n
			 " "n
			 "/*"n
			 "$Log: $"n
			 "*/"n
			 " "n
			 " "n
			 "/*~E*/"n
			 ) 
		       "cvsh" 
		       "Insert a cvs header" 
		       'c-tempo-tags) 

(tempo-define-template "elmegh"
		       '(
			 "/*~K*/ "n
			 "/*~+:***************************************************************************"n
			 "/*~+:*                                                                          "n
			 "/*~+:*  Copyright (c) "_year" by Funkwerk Enterprise Communications GmbH "n
			 "/*~+:*                            All Rights Reserved                           "n
			 "/*~+:*                                                                          "n
			 "/*~+:***************************************************************************"n
			 "/*~+:*      C-Source                                                            "n
			 "/*~+:***************************************************************************"n
			 "/*~+:*      Projekt   : "(p "Projekt: " Projekt:)"  "n
			 "/*~+:*      Modul     : "_filename" "n
			 "/*~+:*      Version   : V"(p "Version: " Version:)"  "n
			 "/*~+:*      Datum     : "_isodate" "n
			 "/*~+:*                                          "n
			 "/*~+:*      Autor     : "_author" "n
			 "/*~+:*      Firma/Abt.: APHONA Funkwerk GmbH  "n
			 "/*~+:*      Telefon   : +43 616 3434 "(p "Tel: " Tel:)"  "n
			 "/*~+:****************************************************************************"n
			 "/*~+:*      Beschreibung: "(p "Beschreibung: " Beschreibung:)"  "n
			 "/*~+:****************************************************************************"n
			 "/*~+:*/"n
			 "/*~K*/"n
			 "/*~+:"  _isodate " "(p "Aenderung  (Initialen_Aenderung): " Initialen-Aenderung:)" "n
			 "/*~+:*/"n		
			 )
		       "elmegh"
		       "Insert a elmeg header"
		       'c-tempo-tags)

(tempo-define-template "history"
		       '(
			 "/*~A*/"n
			 "/*~+:History till "_date"*/"n
			 "/*~T*/"n
			 "/***************************************************************************"n
			 "*      Aenderungen:                                                         "n
			 "*      Datum       Name                  Fehler/Massnahme                   "n
			 "*      "_isodate "  "_author "   "(p " Input: " Input)"   "n
			 "****************************************************************************/"n
			 "/*~E*/"n
			 )
		       "history"
		       "Insert a history"
		       'c-tempo-tags)

(tempo-define-template "include"
		       '(
			 "/*~A*/"n
			 "/*~+:Include*/"n
			 "/*~T*/"n
			 "#include " r "" > n
			 "/*~E*/"n
			 )
		       "include"
		       "Insert a #include <> statement"
		       'c-tempo-tags)

(tempo-define-template "void"
		       '(
			 "/*~A*/"n
			 "/*~+:Funktion*/"n
			 "/*~A*/"n
			 "/*~+: "(p "funktionname: " name)"*/"n
			 "/*~T*/"n
			 "/***************************************************************************"n
			 "*       Funktion  :   " (s name) ""n                                      
			 "*       Aufgabe   :   "(p  "Aufgabe: "Aufgabe)""n
			 "*       Parameter     : "(p  "Parameter: "Parameter)""n
			 "*       Rueckgabewert : "(p  "Rueckgabewert: "Rueckgabew)""n
			 "*       Aufruf durch : "(p  "Aufruf durch: "Aufruf)""n
			 "*       Ruft auf     : "(p  "Ruft auf: "Ruft)""n
			 "****************************************************************************"n
			 "*       Beschreibung : "(p  "Beschreibung: "Beschreibung)""n
			 "****************************************************************************/"n
			 " "n
			 "/*~F*/"n
			 "void "(s name)" ("(s Parameter)")"> n >
			 "/*~-*/"> n >
			 "{"> n >
			 > r n >
			 "/*~-*/"> n >
			 "}"> n >
			 "/*~E*/"> n >
			 "/*~E*/"> n >
			 )
		       "void"
		       "Insert a Funktion"
		       'c-tempo-tags)


(tempo-define-template "for"
		       '(
			 "/*~L*/"n
			 > "for (" (p "variable: " var) " = 0; " (s var)
                           " < "(p "upper bound: " ub)"; " (s var) "++)" > n >
			  "/*~-*/"> n >
			   " {" > n >
                           > r n >
			   "/*~-*/"> n >
                           "}" > n >
			   "/*~E*/"> n >
                           )
		       "for"
		       "Insert a C for loop: for(x = 0; x < ..; x++)"
		       'c-tempo-tags)


(tempo-define-template "switch"
		       '(
			 "/*~C*/"n
			  "switch (" (p "switch-condition: " clause) ") "> n >
			 "/*~-*/" > n >
			 " {"  > n > 
			 "/*~F*/"> n >
			 "case " (p "first value: ") ":" > > n > >
			 "/*~-*/"> n >
			 "{"> n >
			  r > n >
			 "break;"  > n >
			 "/*~-*/"> n >
			 "}"> n >
			 "/*~E*/"> n >
			 "/*~O*/"> n >
			 "/*~-2*/"> n >
			 "default:"  > n >
			 "{"> n >
			 "break;"  > n >
			 "/*~-*/" > n >
			 "}"  > n >
			 "/*~-*/" > n >
			 "}"  > n >
			 "/*~E*/"> n >
			 )
		       "switch"
		       "Insert a C switch statement"
		       'c-tempo-tags)

(tempo-define-template "case"
		       '(
			 "/*~F*/"> n >
			 "case " (p "first value: ") ":" > > n > >
			 "/*~-*/"> n >
			 "{"> n >
			 r > n >
			 "break;"  > n >
			 "/*~-*/"> n >
			 "}"> n >
			 "/*~E*/"> n >
			 )
		       "case"
		       "Insert a C case statement"
		       'c-tempo-tags)


(tempo-define-template "if"
		       '(
			 "/*~I*/"n
			 "if" "(" (p "if-clause: ") ")" > > n> >
                         "/*~-*/"> n > 
			 "{" > n >
			 "/*~T* /"> n >
			 > r n >
			 "/*~-*/" > n >
			 "}" > n >
			 "/*~E*/"> n >
			 )
		       "if"
		       "Insert a C if statement"
		       'c-tempo-tags)

(tempo-define-template "else"
		       '(
			 "/*~O*/" n
			 "/*~-2*/" n
			 "else" > n >
			 "{" > n >
			 "/*~T*/" > n >
			 > r n
			 "/*~-*/" > n >
			 "}" > n >
			 )
		       "else"
		       "Insert a C else statement"
		       'c-tempo-tags)

(tempo-define-template "ifelse"
		       '(
			 "/*~I*/"n
			 "if" "(" (p "if-clause: ") ")" > > n> >
                         "/*~-*/"> n > 
			 "{" > n >
			 "/*~T* /"> n >
			 > r n
			 "/*~-*/" > n >
			 "}" > n >
			 "/*~O*/" > n >
			 "/*~-2*/" > n >
			  "else" > n >
			 "{" > n >
			 "/*~T*/" > n >
			 > r n
			 "/*~-*/" > n >
			 "}" > n >
			 "/*~E*/"> n >
			 )
		       "ifelse"
		       "Insert a C if else statement"
		       'c-tempo-tags)



(tempo-define-template "do"
		       '(
			 "/*~U*/"n
			 "/*~-2*/"n
			 > "do" > n > 
			 "{" > n >
			 > r n
			 "/*~-*/" > n >
			 "}" > n>
			 "/*~O*/" > n >
			 "while" "(" (p "while-clause: ") ");" > > n > >
;; 			 "/*~-*\/" >n>	 
;; 			 "{" > n> **/
;; 			 "/*~-*\/" >n> 
;; 			 "}" > n> **/
			 "/*~E*/"> n >
			 "/*~E*/"> n >
			 )
		       "do"
		       "Insert a C if else statement"
		       'c-tempo-tags)


(tempo-define-template "while"
		       '(
			 "/*~L*/"n
			 "while" "(" (p "while-clause: ") ")" > > n > >
			 "/*~-*/" > n >			 
			 "{" > n >
			 > r n
			 "/*~-*/" > n >
			 "}" > n >
			 "/*~E*/"> n >
			 )
		       "while"
		       "Insert a C if else statement"
		       'c-tempo-tags)



;; ======== mps end ========

;; ==================================================================================================== 
(defun my-editing-function (first last len)
  (interactive)
  (if (and (boundp 'major-mode)
           (member major-mode (list 'mps-mode ))
           (= len 0)
           (> (point) 4)
           (= first (- (point) 1)))      
      (cond
       ((and (string-equal (buffer-substring (point) (- (point) 2)) "__")
             (not (string-equal (buffer-substring (point) (- (point) 3)) "___")))
        (progn (delete-backward-char 2) (insert-char ?- 1) (insert-char ?> 1)))

       ((string-equal (buffer-substring (point) (- (point) 3)) "->_")
        (progn (delete-backward-char 3) (insert-char ?_ 3)))
       
       ((and (string-equal (buffer-substring (point) (- (point) 2)) "[]"))
        (progn (delete-backward-char 2) (insert-char ?[ 1) (insert-char ?] 1) (backward-char 1)))

       ((and (> (point-max) (point))
             (string-equal (buffer-substring (+ (point) 1) (- (point) 2)) "[.]"))
        (progn (forward-char 1) (delete-backward-char 3) (insert-char ?. 1) (insert-char ?. 1) ))

       ((and (string-equal (buffer-substring (point) (- (point) 2)) "()"))
        (progn (delete-backward-char 2) (insert-char ?( 1) (insert-char ?) 1) (backward-char 1)))

       ((and (> (point-max) (point))
             (string-equal (buffer-substring (+ (point) 1) (- (point) 2)) "(.)"))
        (progn (forward-char 1) (delete-backward-char 3) (insert-char ?. 1) (insert-char ?. 1) ))
       )
    nil))

(add-hook 'after-change-functions 'my-editing-function)
mps-mode-map) 
"Local keymap for `mps-mode'.")


(defun mps-mode ()
  "Major mode for editing mps files."
  
  (interactive)
 ;; (kill-all-local-variables)
  
  ;;(mps-create-syntax-table)
  
  ;;(use-local-map mps-mode-map)
  
  (setq major-mode 'mps-mode)
  (setq mode-name "C Mode: mps")
  
  ;;(mps-create-abbrev-table)
  
  ;; Compilation

  (setq-default c-basic-offset 3) ; set cstyle 4 wegen einrücken !!!
  (show-paren-mode t) 
  (partial-completion-mode t)
  
(run-hooks 'mps-mode-hook))

(define-key mps-mode-map (kbd "<f7>") 'compile)

(provide 'mps)