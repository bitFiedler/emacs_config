;; -*- Mode: Emacs-Lisp -*-
;;--------------------------------------------------------------------
;;     PROJECT: Generic
;;   COPYRIGHT: Matthias Popp
;;    $RCSfile: adsp.el,v $
;;   $Revision: 0.1 $
;;      AUTHOR: Matthias Popp
;;  SUBSTITUTE: -
;;    LANGUAGE: elisp
;;    COMPILER: 
;; DESCRIPTION: This module defines font-lock keywords and regular
;;              expressions for Adsp asm-mode buffers. You can use
;;              these definitions in conjunction with font-lock.el to
;;              "fontify" assembly-language buffers.
;;
;;        $Log: adsp.el,v $
;;        Revision 0.1  2004/06/14 07:06:28  mpopp
;;        blah
;;
;;
;;--------------------------------------------------------------------
;; Keywords: asm, adsp, font-lock
;;--------------------------------------------------------------------
;; This file is not part of GNU Emacs.
;;
;; This is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; Installation:
;;
;; Installation is simple: just put this file somewhere in your
;; load-path and put the following lines in your .emacs file:
;;
;; (autoload 'adsp-mode "adsp" nil t)
;; (setq auto-mode-alist (append (list (cons "\\.dsp$" 'adsp-mode))
;;                               auto-mode-alist))
;;
;; If you have modified your startup file as described above, (x)emacs
;; should enter adsp-mode whenever you load an *.asm file into emacs.
;;
;; If not, you will have to start adsp-mode manually:
;;    M-x load-library adsp
;;    M-x adsp-mode

;; Code:

(defconst adsp-mode-version "0.1"
  "Version of this adsp mode.")

(defvar wpdl-mode-hook nil)

(defvar adsp-mode-map
  (let ((adsp-mode-map (make-sparse-keymap)))
    (define-key adsp-mode-map "\t" 'tab-to-tab-stop)
;    (define-key adsp-mode-map "\t" 'adsp-indent-line)
    (define-key adsp-mode-map "\r" 'adsp-newline)

    (define-key adsp-mode-map (kbd "C-,") 'adsp-comment-region)
    (define-key adsp-mode-map (kbd "C-.") 'adsp-uncomment-region)  

	 (define-key adsp-mode-map "\C-c\C-c" 'comment-dwim)

    (define-key adsp-mode-map (kbd "<f7>") 'compile)
;	 (define-key adsp-mode-map (kbd "M-q") 'c-fill-paragraph)
    adsp-mode-map) 
  "Local keymap for `adsp-mode'.")

(defvar adsp-mode-syntax-table nil
  "Syntax table in use in adsp-mode buffers.")

(defun adsp-create-syntax-table ()
;  (if adsp-mode-syntax-table
;		()
    (setq adsp-mode-syntax-table (make-syntax-table))
    (set-syntax-table adsp-mode-syntax-table)

    ;; Declare "_" to be a valid part of a word
    (modify-syntax-entry ?_ "w" adsp-mode-syntax-table)

    ;; (modify-syntax-entry ?\% "<   " adsp-mode-syntax-table)

    ;; C++-style comments '/* */' and '//'
    (modify-syntax-entry ?/ ". 124b" adsp-mode-syntax-table)
    (modify-syntax-entry ?* ". 23" adsp-mode-syntax-table)
    (modify-syntax-entry ?\n "> b" adsp-mode-syntax-table))

(defvar adsp-mode-abbrev-table nil
  "Abbrev table used in adsp mode.")

(defun adsp-create-abbrev-table ()
  (if adsp-mode-abbrev-table
		()
	 (setq adsp-mode-abbrev-table (make-abbrev-table))
	 (define-abbrev-table 'adsp-mode-abbrev-table ())
	 
;	 (let ((abbrevs-changed nil))
    (define-abbrev adsp-mode-abbrev-table ";pm" "PM()" nil)
    (define-abbrev adsp-mode-abbrev-table ";dm" "DM()" nil)))


(defconst adsp-indent-level 3
  "*Indentation of ADSP statements with respect to containing block.")
(defconst adsp-continued-expr 1
  "*Indentation of line that is a continued expression.")
(defconst adsp-auto-newline t
  "*Non-nil means automatically newline after semicolons and the
punctation mark after an end.")
(defconst adsp-tab-always-indent t
  "*Non-nil means TAB in adsp mode should always reindent the
current line, regardless of where in the line point is when the TAB
command is used.")
(defconst adsp-label-offset -1
  "*Offset of adsp label lines relative to usual indentation.")

(defvar adsp-registers
  '("and" "do" "else" "end" "if" "until" "label" "not" "or" "ena"))

(defvar adsp-directives 

  '("ALIGN" "EXTERN" "FILE" "GLOBAL" "LEFTMARGIN" "NEWPAGE"
    "PAGELENGTH" "PAGEWIDTH" "PREVIOUS" "REPEAT" "END_REPEAT" "SECTION"
    "SIZE" "TYPE" "VAR" "INIT24" "DATA" "DM" "CODE" "PM" "RESOLVE"
    "INIT24" "IO" "REG"
    
    "RAM" "ABS" "INIT" "CIRC" "MODULE" "CONST"

    ".ALIGN" ".ASCII" ".ASM_ASSERT" ".ASSERT" ".BYTE"  ".BYTE2" ".BYTE4"
    ".ELSE" ".ENDIF" ".EXTERN" ".EXTERN STRUCT" ".FILE" ".GLOBAL" ".IF"
    ".IMPORT" ".LEFTMARGIN" ".LIST" ".LIST_DATA" ".LIST_DATAFILE"
    ".LIST_DEFTAB" ".LISTWRAPDATA" ".NEWPAGE" ".NOLIST" ".NOLIST_DATA"
    ".NOLIST_DATAFILE" ".NOLIST_WRAPDATA" ".PAGELENGTH" ".PAGEWIDTH"
    ".PERVIOUS" ".SECTION" ".STRUCT" ".TYPE" ".VAR" ".VCSE_" ".WEAK" 
    "STRUCT"))

(defvar adsp-preprocessor-directives

  '("DEFINE" "ELIF" "ELSE" "ENDIF" "ERROR" "IF" "IFDEF" "IFNDEF" "INCLUDE" "LINE" "PRAGMA" "UNDEF" "WARNING"
    "ADI" "__LASTSURFIX__" "__LINE__" "__FILE__" "__TIME__" "__DATE__" "__ADSPBLACKFIN__" "__ADSPBF531__" "__ADSPBF532__"
    "__ADSP21532_=1" "__ADSPBF533__" "__ADSP21533_=1" "__ADSPBF535__" "__ADSP21535_=1" "__ADSPBF561__" "__AD6532__"
    "__LANGUAGE_ASM" "__LANGUAGE_C"))

(defvar adsp-keywords

  '("ABS" "AC" "ADDRESS" "AF" "ALT_REG" "AND" "AR" "AR_SAT" "AS"
    "ASHIFT" "ASTAT" "AUX" "AV" "AV_LATCH" "AX0" "AX1" "AY0" "AY1"

    "BIT_REV" "BM" "BOOT" "BR" "BY" "BYTE" "B0" "B1" "B2" "B3" "B4"
    "B5" "B6" "B7"

    "C" "CACHE" "CALL" "CE" "CLEAR" "CLR" "CLRBIT" "CRLINT" "CNTR"

    "DEFINED" "DIS" "DIVQ" "DIVS" "DMOVLAY" "DO"

    "E_MODE" "EMUIDLE" "ENA" "EQ" "EXP" "EXPADJ" "EXPORT"

    "FOREVER" "FLO" "FL1" "FL2" "FLAG_IN" "FLAG_OUT" "FLUSH"

    "GE" "G_MODE" "GM" "GT"

    "HI" "HIX"

    "I0" "I1" "I2" "I3" "I4" "I5" "I6" "I7" "ICNTR" "ICTRL" "IDLE"
    "IFC" "IMASK" "INT" "INTS" "ISTAT" "IRPTL" "ICNTL"

    "JUMP" "KTRAP"

    "L0" "L1" "L2" "L3" "L4" "L5" "L6" "L7" "LE" "LENGTH" "LO" "LOOP"
    "LSHIFT" "LT"

    "M0" "M1" "M2" "M3" "M4" "M5" "M6" "M7" "MF" "M_MODE" "MM"
    "MODIFY" "MR" "MR0" "MR1" "MR2" "MSTAT" "MV" "MX0" "MX1" "MY0"
    "MY1"

    "NAME" "NE" "NEG" "NONE" "NOP" "NORM" "NOT"

    "OF" "OL" "OR" "ORG" "OWRCNTR"

    "PAGEID" "PASS" "PC" "PMOVLAY" "POP" "POS" "PRAGMA" "PRECISION"
    "PUSH" "PX"

    "RAM" "READ" "REGBANK" "RESET" "RND" "ROM" "ROUND_MINUS"
    "ROUND_NEAREST" "ROUND_PLUS" "ROUND_ZERO" "RTI" "RTS" "RX0" "RX1"

    "SAT" "SB" "SE" "SEG" "SEG_REG" "SET" "SETBIT" "SETDATA" "SETINT"
    "SHIFT" "SI" "SIMIDLE" "SR" "SR2" "SR0" "SR1" "SS" "SSTAT" "STATIC"
    "STEP" "STS" "SU" "SD"

    "TEST" "TGLBIT" "TIMER" "TI" "TOGGLE" "TOPPCSTACK" "TRAP" "TRUE"
    "TSTBIT" "TX0" "TX1"

    "UNTIL" "US" "UU"

    "WAIT" "WRITE"

    "XOR"

    

    "A0" "A1" "ABORT" "ALIGN8" "ALIGN16" "ALIGN24" "AMNOP" "AN" "ASHIFT" 
    "ASL" "ASR" "ASSIGN" "ASTAT" "AV0" "AV1" "AZ"

    "B" "B0" "B1" "B2" "B3" "BANG" "BAR" "BITCLR" "BITMUX" "BITPOS"
    "BITSET" "BITTGL" "BITTST" "BIT_XOR_AC" "BP" "BYTEOP1P" "BYTEOP16M"
    "BYTEOP1NS" "BYTEOP16P" "BYTEOP2M" "BYTEOP2P" "BYTEOP3P" "BYTEPACK" 
    "BYTEUNPACK" "BXOR" "BOXRSHIFT"
 
    "CARET" "CC" "CLI" "CLIP" "CO" "COLON" "COMMA" "CSYNC" 
    
    "DBG" "DBGA" "DBGAH" "DBGAL" "DBGCMPLX" "DBGHALT" "DEPOSIT" "DISALGNEXCPT"
    "DIVISDEPOSIT" "DOZE" "DOT" 
    
    "EMUCAUSE" "EMUEXCPT" "EXCAUSE" "EXCPT" "EXPADJ" "EXTRACT"

    "FEXT" "FEXTSX" "FLUSHINV" "FP" "FU"
    
    "GF" 
    
    "H" "HI" "HLT" "HWERRCAUSE"
    
    "IDLE_REQ" "IFLUSH" "IH" "INTRP" "IS" "ISS2" "IU" 
     
    "JUMP.L" "JUMP.S"

    "L" "LB0" "LB1" "LC0" "LC1" "LE" "LINK" "LJUMP" "LMAX" "LMIN"
    "LO" "LOOP_BEGIN" "LOOP_END" "LPAREN" "LSETUP" "LT0" "LT1" "LZ"

    "M" "MAX" "MIN" "MINUS" "MNOP" "MUNOP" 

    "NS"

    "ONES" "OUTC"

    "P0" "P1" "P2" "P3" "P4" "P5" "PACK" "PRNT" "PERCENT" "PLUS" "PREFETCH"

    "R" "R0" "R1" "R2" "R3" "R4" "R5" "R6" "R7" "RAISE" "RBRACE" "RBRACK" "RTN"
    "RTX" "R1_COLONO" 
    
    "S" "S2RND" "SAA" "SAA3H" "SAA3L" "SCO" "SEARCH" "SHT_TYPE" "SIGN" "SIGNBITS"
    "SLASH" "SLEEP" "SKPF" "SKPT" "SP" "SSF" "SSF_RND_HI" "SSF_TRUNC" "SSF_TRUNC_HI"
    "SSF_RND" "SSF_TRUNC" "SSYN" "STI" "STRUCT" "STT_TYPE" "SYSCFG"
    
    "T" "TESTSET" "TFU" "TH" "TL" "TST"
    
    "UNLINK" "UNLNK" "UNRAISE" 

    "V" "VIT_MAX" 
    
    "W" "W32" "WEAK"

    "X" "XB" "XH" 
    
    "Z" ))

(defvar adsp-ctoken "[a-zA-Z0-9_$]+")

(defface adsp-label-face
  '((((class color) (background light)) (:foreground "Red"))
    (((class color) (background dark)) (:foreground "LightSkyBlue"))
    (t (:inverse-video t :bold t)))
  "Font Lock mode face used to highlight labels.")

(defface adsp-comment-face
  '((((class color) (background light)) (:foreground "cyan"))
    (((class color) (background dark)) (:foreground "cyan"))
    (t (:inverse-video t :bold t)))
  "Font Lock mode face used to highlight comments.")

(defface adsp-directives-face
  '((((class color) (background light)) (:foreground "DodgerBlue1"))
    (((class color) (background dark)) (:foreground "gray65"))
    (t (:inverse-video t :bold t)))
  "Font Lock mode face used to highlight directives.")

(defface adsp-keyword-face
  '((((class color) (background light)) (:foreground "Blue"))
    (((class color) (background dark)) (:foreground "LightSkyBlue"))
    (t (:inverse-video t :bold t)))
  "Font Lock mode face used to highlight keywords.")

(defface adsp-register-face
  '((((class color) (background light)) (:foreground "Magenta"))
    (((class color) (background dark)) (:foreground "LightSkyBlue"))
    (t (:inverse-video t :bold t)))
  "Font Lock mode face used to highlight registers.")

(defvar adsp-label-face 'adsp-label-face
  "Face name to use for labels.")

(defvar adsp-comment-face 'adsp-comment-face
  "Face name to use for comments.")

(defvar adsp-directives-face 'adsp-directives-face
  "Face name to use for diectives.")

(defvar adsp-keyword-face 'adsp-keyword-face
  "Face name to use for keywords.")

(defvar adsp-register-face 'adsp-register-face
  "Face name to use for registers.")

(defvar adsp-font-lock-keywords
  (list 
   ;; Fontify labels
   (list (concat "^[ \t]*" adsp-ctoken ":") 0 'adsp-label-face t)

   ;; Fontify directives
   (cons (concat "\\<\\("
                 (mapconcat 'identity adsp-directives "\\|") "\\)\\>")
         'adsp-directives-face)

   ;; Fontify directives
   (cons (concat "\\<\\("
                 (mapconcat 'identity adsp-preprocessor-directives "\\|") "\\)\\>")
         'adsp-directives-face)

   ;; Match builtin registers
   (cons (concat "\\<\\("
                 (mapconcat 'identity adsp-registers "\\|") "\\)\\>")
         'adsp-register-face)

   ;; fontify reserved words
   (cons (concat "\\<\\("
                 (mapconcat 'identity adsp-keywords "\\|") "\\)\\>")
         'adsp-keyword-face))

  "Expressions to highlight in adsp-mode buffers.")

(defvar adsp-compilation-regexp-alist '("^.*?\"\\(.*?\\)\":\\(\d+\\)" 1 2)
  "Compilation-mode regexp for matching the ADSP Compiler output. See compilation-error-regexp-alist.")

;;; =============================================================================
;; Indentation
(defun adsp-indent-line ()
  "Indent current line of adsp code."
  (interactive)
  (beginning-of-line)
  (if (bobp)
		(indent-line-to 0) ; First line is always non-indented
	 (let ((not-indented t) cur-indent)
		(if (looking-at "^[ \t]*:") ; If the line we are looking at is a label, then
													 ; decrease the indentation
			 (progn
				(save-excursion
				  (forward-line -1)
				  (setq cur-indent (- (current-indentation) default-tab-width)))
				(if (< cur-indent 0) ; We can't indent past the left margin
					 (setq cur-indent 0)))
		  (save-excursion
			 (while not-indented ; Iterate backwards until we find an indentation hint
				(forward-line -1)
				(if (looking-at "^[ \t]*:") ; This hint indicates that we
													 ; need to indent at the level
													 ; of the END_ token
					 (progn
						(setq cur-indent (current-indentation))
						(setq not-indented nil))
				  (if (looking-at "^[ \t]*\\(DO\\|TRANSITION\\)") ; This
													 ; hint indicates that we need
													 ; to indent an extra level
						(progn
						  (setq cur-indent (+ (current-indentation) default-tab-width)) ; Do the actual indenting
						  (setq not-indented nil))
					 (if (bobp)
						  (setq not-indented nil)))))))
		(if cur-indent
			 (indent-line-to cur-indent)
		  (indent-line-to 0))))) ; If we didn't see an indentation hint, then allow no indentation

(defun adsp-newline ()
  "Indent current line of adsp code."
  (interactive)
  (newline)
  (tab-to-tab-stop))

(defsubst adsp-in-comment-p ()
  "Returns t if point is inside an adsp comment, nil otherwise."
  (interactive)
  (save-excursion
    (nth 4 (parse-partial-sexp (adsp-point 'bol) (point)))))

(defsubst adsp-in-string-p ()
  "Returns t if point is inside an adsp string, nil otherwise."
  (interactive)
  (save-excursion
    (nth 3 (parse-partial-sexp (adsp-point 'bol) (point)))))

(defsubst adsp-not-in-string-or-comment-p ()
  "Returns t iff point is not inside an adsp string or comment."
  (let ((pps (parse-partial-sexp (adsp-point 'bol) (point))))
    (not (or (nth 3 pps) (nth 4 pps)))))

(defun adsp-comment-region ()
  "Comment each line in the region as adsp code."
  (interactive)
  (if (region-active-p)
      (comment-region (region-beginning) (region-end))
    (comment-region (point-at-bol) (point-at-eol))))

(defun adsp-uncomment-region (&optional arg)
  "Uncomment each line in the region as adsp code."
  (interactive "P")
  (or arg (setq arg 1))
  (if (region-active-p)
      (comment-region (region-beginning) (region-end) (- arg))
    (comment-region (point-at-bol) (point-at-eol) (- arg))))

;;; =============================================================================
;; autoload
(defun adsp-mode ()
  "Major mode for editing adsp files."

  (interactive)
  (kill-all-local-variables)

  (adsp-create-syntax-table)

  (use-local-map adsp-mode-map)

  (setq major-mode 'adsp-mode)
  (setq mode-name "Assembler: adsp")

  (adsp-create-abbrev-table)

  ;; Compilation
  (setq compilation-read-command nil) ; don't ask before compiling, just do make
  (setq compilation-window-height 10) ; number of lines in a compilation window

  (eval-after-load "compile" 
    '(defadvice compile-internal
       (after compile-my-scroll activate compile)
       "Forces compile buffer to scroll. See around line 363 in compile.el"
       (let* ((ob (current-buffer)))
         (save-excursion
           (select-window (get-buffer-window ad-return-value))
           (goto-char (point-max))
           (select-window (get-buffer-window ob))
           ))))

  ;; Parse assembler errors of the form:
  ;; [Error ea1997] "main.dsp":62 [column 1]Error description
  (setq compilation-error-regexp-alist '(("^.*\"\\(.*\\)\":\\([0-9]+\\)" 1 2)))

;;   (setq compilation-mode-hook 
;;         (cons '(lambda ()
;;                  (setq compilation-error-regexp-alist
;;                        (cons adsp-compilation-regexp-alist
;;                              compilation-error-regexp-alist)))
;;               compilation-mode-hook)))

  (make-local-variable 'paragraph-start)
  (make-local-variable 'paragraph-separate)
  (setq paragraph-start "$\\|{\\|[ \t\n]*$")
  (setq paragraph-separate "$\\|{\\|[ \t\n\^L]*$")

  (make-local-variable 'comment-start)
  (setq comment-start "/*")
  (make-local-variable 'commend-end)
  (setq comment-end "*/")
  (make-local-variable 'comment-style)
  (setq comment-style 'plain)
  (make-local-variable 'comment-padding)
  (setq comment-padding "")
 
;  (setq comment-style '(adsp-comment-style t t t t))

  (setq tab-stop-list '(8 12 16 20 40 80))
  (setq indent-tabs-mode nil)

  (setq fill-column 72)

  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'adsp-indent-line)
  (setq comment-indent-hook 'adsp-indent-within-comment)

  (make-local-variable 'case-fold-search)
  (setq case-fold-search t)

  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)

  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(adsp-font-lock-keywords nil t))

  (run-hooks 'adsp-mode-hook))

(provide 'adsp)

;; End of file (adsp.el)
