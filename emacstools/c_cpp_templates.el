;; my c++ and c templates  -*- lexical-binding: t; -*- 


(require 'tempo)

;; ============================ DEFINE MACROS =================================
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
(setq _filename_no_ex '((lambda ()(file-name-sans-extension (file-name-nondirectory (buffer-file-name))))))
(setq _filename_no_ex_upper '((lambda ()(upcase (file-name-sans-extension (file-name-nondirectory (buffer-file-name)))))))
(setq _filename_no_ex_low '((lambda () (downcase (file-name-sans-extension (file-name-nondirectory (buffer-file-name)))))))
(setq _filename_ex    '((lambda () (upcase (file-name-extension (file-name-nondirectory (buffer-file-name)))))))
;;(setq _filename_extension '(((lambda () (string= "c" (downcase (file-name-extension (file-name-nondirectory (buffer-file-name)))) (progn((insert "h")))) (progn(insert "hpp"))))))
(setq _filename_extension '(insert "h"))
(setq _creator  '(user-full-name))
(setq _author   '(user-full-name))
(setq _date     '(current-time-string))
(setq _year     '(template-insert-time "%Y" "0000"))
(setq _isodate  '(template-insert-time "%d-%m-%Y" "00-00-0000"))
;; =============================================================================

;; This is a way to hook tempo into cc-mode
(defvar c-tempo-tags nil
  "Tempo tags for C mode")
(defvar c++-tempo-tags nil
  "Tempo tags for C++ mode")

;;; C-Mode Templates and C++-Mode Templates (uses C-Mode Templates also)
(setq tempo-interactive t)


;; keybord short cut to execute template tag
(add-hook 'c-mode-hook '(lambda ()
                          (define-key c-mode-map [(M-return)] 'tempo-complete-tag)))
(add-hook 'c-ts-mode-hook '(lambda ()
                          (define-key c-ts-mode-map [(M-return)] 'tempo-complete-tag)))

(add-hook 'c++-mode-hook '(lambda ()
                            (define-key c++-mode-map [(M-return)] 'tempo-complete-tag)))

(add-hook 'c++-ts-mode-hook '(lambda ()
                            (define-key c++-ts-mode-map [(M-return)] 'tempo-complete-tag)))

;; (add-hook 'c-mode-hook '(lambda ()
;;                           (cond
;;                            ;; for mac 
;;                            ((string-equal system-type "darwin")
;;                             (define-key c-mode-map [(s-return)] 'tempo-complete-tag))
;;                            (define-key c-mode-map [(M-return)] 'tempo-complete-tag))))

;; (add-hook 'c++-mode-hook '(lambda ()
;;                             (cond
;;                              ;; for mac 
;;                            ((string-equal system-type "darwin")
;;                             (define-key c++-mode-map [(s-return)] 'tempo-complete-tag))
;;                            (define-key c++-mode-map [(M-return)] 'tempo-complete-tag))))
       
(defun tempo-complete (prompt completions match-required
                              &optional save-name no-insert)
  "Do whatever `tempo-insert-prompt' does, but use completing-read."
  (cl-flet ((read-string (prompt)
                      (completing-read prompt completions match-required)))
    (tempo-insert-prompt prompt save-name no-insert)))

;; using template in c mode
(add-hook 'c-mode-hook '(lambda ()
                          (tempo-use-tag-list 'c-tempo-tags)
                          ))
;; using template in c treesitter mode
(add-hook 'c-ts-mode-hook '(lambda ()
                          (tempo-use-tag-list 'c-tempo-tags)
                          ))

;; using template in c++ mode
(add-hook 'c++-mode-hook '(lambda ()
                            (tempo-use-tag-list 'c++-tempo-tags)
                           ))


;; using template in c++ teesitter mode
(add-hook 'c++-ts-mode-hook '(lambda ()
                            (tempo-use-tag-list 'c++-tempo-tags)
                           ))

;; Preprocessor Templates (appended to c-tempo-tags)

(tempo-define-template "c-ifdef" 
                       '("ifdef " (p "ifdef-clause: " clause) > n> p n 
                         "#else // !(" (s clause) ") " n> p n 
                         "#endif // " (s clause)" " n> 
                         ) 
                       "ifdef" 
                       "insert a #ifdef #else #endif statement" 
                       'c-tempo-tags)

(tempo-define-template "c++ifdef" 
                       '("ifdef " (p "ifdef-clause: " clause) > n> p n 
                         "#else // !(" (s clause) ") " n> p n 
                         "#endif // " (s clause)" " n> 
                         ) 
                       "ifdef" 
                       "insert a #ifdef #else #endif statement" 
                       'c++-tempo-tags)


;; im code #ifdef+M+Return fügt automatisch #ifdef xxx und #else und #endif ein  

(tempo-define-template "c-ifndef" 
                       '("ifndef " (p "ifndef-clause: " clause) > n 
                         "#define " (s clause) n> p n 
                         "#endif // " (s clause)" " n> 
                         ) 
                       "ifndef" 
                       "insert a #ifndef #define #endif statement" 
                       'c-tempo-tags) 

(tempo-define-template "c++ifndef" 
                       '("ifndef " (p "ifndef-clause: " clause) > n 
                         "#define " (s clause) n> p n 
                         "#endif // " (s clause)" " n> 
                         ) 
                       "ifndef" 
                       "insert a #ifndef #define #endif statement" 
                       'c++-tempo-tags) 


;; im code #ifndef+M+Return fügt automatisch #ifndef xxx und #else und #endif ein  

;; C-Mode Templates 

;; if template 
(tempo-define-template "c-if"
                       '(> "if (" (p "expression: " clause) ")" > n
                           > "{" > n
                           > r p n
                           > "}" > n r>
                           ) 
                       "if" 
                       "insert if statement" 
                       'c-tempo-tags)

(tempo-define-template "c++if"
                       '(> "if (" (p "expression: " clause) ")" > n
                           > "{" > n
                           > r p n
                           > "}" > n r>
                           ) 
                       "if" 
                       "insert if statement" 
                       'c++-tempo-tags)

;; else template
(tempo-define-template "c-else" 
                       '(> "else" > n
                           > "{"n> 
                           > r p n
                           > "}" > n> r>
                           ) 
                       "else" 
                       "insert else statement" 
                       'c-tempo-tags)

(tempo-define-template "c++else" 
                       '(> "else" > n
                           > "{"n> 
                           > r p n
                           > "}" > n> r>
                           ) 
                       "else" 
                       "insert else statement" 
                       'c++-tempo-tags) 

;; if else template
(tempo-define-template "c-ifelse" 
                       '(> "if (" (p "expression: " clause) ")" > n
                           > "{" > n
                           > r p n
                           > "}" " else" > n
                           > "{" > n 
                           > r n 
                           > "}" > n r>
                           ) 
                       "ifelse" 
                       "insert if else statement" 
                       'c-tempo-tags)

(tempo-define-template "c++ifelse" 
                       '(> "if (" (p "expression: " clause) ")" > n
                           > "{" > n
                           > r p n
                           > "}" " else" > n
                           > "{" > n 
                           > r n 
                           > "}" > n r>
                           ) 
                       "ifelse" 
                       "insert if else statement" 
                       'c++-tempo-tags) 

;; else if template 
(tempo-define-template "c-elseif" 
                       '(> "else if (" (p "expression: " clause) ")" > n
                           > "{" > n
                           > r p n
                           > "}" > n r>
                           ) 
                       "elseif " 
                       "insert else if statement" 
                       'c-tempo-tags)

(tempo-define-template "c++elseif" 
                       '(> "else if (" (p "expression: " clause) ")" > n
                           "{" > n
                           > r p n
                           "}" > n r>
                           ) 
                       "elseif " 
                       "insert else if statement" 
                       'c++-tempo-tags) 

;; while template 
(tempo-define-template "c+while" 
                       '(> "while (" (p "expression: " clause) ")" > n
                           >"{"> n
                           > r p n
                           >"}" > n r>
                           ) 
                       "while" 
                       "insert while statement" 
                       'c-tempo-tags)

(tempo-define-template "c++while" 
                       '(> "while (" (p "expression: " clause) ")" > n
                           >"{"> n
                           > r p n
                           >"}" > n r>
                           ) 
                       "while" 
                       "insert while statement" 
                       'c++-tempo-tags) 

;; for tamplate 
(tempo-define-template "c-for" 
                       '(> "for (" (p "expression: " clause) ")" >  n>
                           >"{" > n 
                           > r p n 
                           >"}" > n> r>
                           ) 
                       "for" 
                       "insert for statement" 
                       'c-tempo-tags)

(tempo-define-template "c++for" 
                       '(> "for (" (p "expression: " clause) ")" >  n>
                           >"{" > n 
                           > r p n 
                           >"}" > n> r>
                           ) 
                       "for" 
                       "insert for statement" 
                       'c++-tempo-tags)

;; for i++ template 
(tempo-define-template "c-fori" 
                       '(> "for (int "(p "variable: " var) " = 0; \ " (s var) 
                           " < "(p "upper bound: " ub)"; \ ++"(s var)")" > n
                           >"{" > n
                           > r p n
                           >"}" > n> r>
                           ) 
                       "fori" 
                       "insert loop statement: for(int x = 0;\ x < ..;\ ++x)" 
                       'c-tempo-tags)

(tempo-define-template "c++fori" 
                       '(> "for (auto "(p "variable: " var) " = 0; \ " (s var) 
                           " < "(p "upper bound: " ub)"; \ ++"(s var)")" > n
                           >"{" > n
                           > r p n 
                           >"}" > n> r>
                           ) 
                       "fori" 
                       "insert loop statement: for(int x = 0;\ x < ..;\ ++x)" 
                       'c++-tempo-tags) 

;; switch case tempalte 
(tempo-define-template "c-switch" 
                       '(> "switch (" (p "switch-condition: " clause) ")" > n
                           >"{"> n 
                           >"case " (p "first value: ") ":" > n
                           > r p n 
                           >"break;" > n
                           > n
                           >"default:" > n
                           >"break;" > n
                           > n
                           >"}" > n r>
                           ) 
                       "switch" 
                       "insert switch statement" 
                       'c-tempo-tags)

(tempo-define-template "c++switch" 
                       '(> "switch (" (p "switch-condition: " clause) ")" > n
                           >"{"> n 
                           >"case " (p "first value: ") ":" > n
                           > r p n 
                           >"break;" > n
                           > n
                           >"default:" > n
                           >"break;" > n
                           > n
                           >"}" > n r>
                           ) 
                       "switch" 
                       "insert switch statement" 
                       'c++-tempo-tags)

;; case template 
(tempo-define-template "c-case" 
                       '(> "case " (p "value: " clause) ":" > n
                           > r p n
                           >"break;" > n r>
                           )
                       "case"
                       "insert case statement" 
                       'c-tempo-tags)

(tempo-define-template "c++case" 
                       '(> "case " (p "value: " clause) ":" > n
                           > r p n
                           >"break;" > n r>
                           )
                       "case"
                       "insert case statement" 
                       'c++-tempo-tags)

;; class template 
(tempo-define-template "class"
                       '("class " (p "name: " var) > n
                         "{" > n
                         "public:" > n
                         (s var)"();" > n
                         ;;"~"(s var)"();" > n
                         > n
                         > r p n
                         "private:" > n
                         > n
                         "};" > n r>
                         )
                       "class"
                       "insert a class statement"
                       'c++-tempo-tags)

;; namespace
(tempo-define-template "namespace"
                       '("namespace " (p "name: " var) " {" > n
                         > r p n 
                         "} // namespace "(s var) > n r>
                         )
                       "namespace"
                       "insert a namespace statement"
                       'c++-tempo-tags)

(tempo-define-template "stv"
                       '(> "std::vector<" (p "type: " var) "> " (p "name: " name) ";" > n
                         > r p n 
                         )
                       "stv"
                       "insert a std::vector"
                       'c++-tempo-tags)

(tempo-define-template "try"
                       '(> "try " > n
                           > "{" > n
                           > r p n
                           > "}" > n
                           > "catch (const std::exception& e)" > n
                           > "{" > n 
                           > "std::cout << e.what() << std::endl;" > n
                           > "}" > n r>
                           )
                       "try"
                       "insert a try catch"
                       'c++-tempo-tags)

(tempo-define-template "throw"
                       '( > "throw std::runtime_error(""\"" (p "desc: " var) "\""");" > n
                            )
                       "throw"
                       "insert a throw exception"
                       'c++-tempo-tags)


;; insert file header template 
(tempo-define-template "c-fheader" 
                       '(  "///*******************************************************************************" n 
                           "/// Copyright (c) "_year", ARRI Cine & Video Geräte Ges.m.b.H - All rights reserved. " n 
                           "///*******************************************************************************" n 
                           "///  @file   "_filename" "n 
                           "/// "n
                           "///  @author "_author" "n
                           "///  @date   "_date" "n
                           "///  @details @b Description \n"
                           "///  "(p "description: " description)" "n 
                           "///*******************************************************************************"n 
                           " "n
                           ) 
                             "fheader" 
                             "insert a File header" 
                             'c-tempo-tags)

(tempo-define-template "c++fheader" 
                       '(  "///*******************************************************************************" n 
                           "/// Copyright (c) "_year", ARRI Cine & Video Geräte Ges.m.b.H - All rights reserved. " n 
                           "///*******************************************************************************" n 
                           "///  @file   "_filename" "n 
                           "/// "n
                           "///  @author "_author" "n
                           "///  @date   "_date" "n
                           "///  @details @b Description \n"
                           "///  "(p "description: " description)" "n 
                           "///*******************************************************************************"n 
                           " "n
                           ) 
                             "fheader" 
                             "insert a File header" 
                             'c++-tempo-tags)

;; instert header file tempalte 
(tempo-define-template "c-hheader" 
                       '(  "///*******************************************************************************" n 
                           "/// Copyright (c) "_year", ARRI Cine & Video Geräte Ges.m.b.H - All rights reserved. " n 
                           "///*******************************************************************************" n 
                           "///  @file   "_filename" "n 
                           "/// "n
                           "///  @author "_author" "n
                           "///  @date   "_date" "n
                           "///  @details @b Description \n"
                           "///  "(p "description: " description)" "n 
                           "///*******************************************************************************"n 
                           " "n
                           "#pragma once"n
                           " "n
                           ) 
                             "hheader" 
                             "insert a header File header" 
                             'c-tempo-tags)

(tempo-define-template "c++hheader" 
                       '(  "///*******************************************************************************" n 
                           "/// Copyright (c) "_year", ARRI Cine & Video Geräte Ges.m.b.H - All rights reserved. " n 
                           "///*******************************************************************************" n 
                           "///  @file   "_filename" "n 
                           "/// "n
                           "///  @author "_author" "n
                           "///  @date   "_date" "n
                           "///  @details @b Description \n"
                           "///  "(p "description: " description)" "n 
                           "///*******************************************************************************"n 
                           " "n
                           "#pragma once"n
                           " "n
                           ) 
                             "hheader" 
                             "insert a header File header" 
                             'c++-tempo-tags)

;; instert function header 
(tempo-define-template "c-pheader" 
                       '(  "///***************************************************************************"n 
                           "///  "(p "purpose: " purpose)" "n
                           "/// "n
                           "///  @param          :  "(p "Parms: " Parms)"     "n
                           "///  @return         :  "(p "return: " Return)"     "n
                           "///***************************************************************************"n 
                           ) 
                       "pheader" 
                       "insert a Function header" 
                       'c-tempo-tags)

(tempo-define-template "c++pheader" 
                       '(  "///***************************************************************************"n 
                           "///  "(p "purpose: " purpose)" "n
                           "/// "n
                           "///  @param          :  "(p "Parms: " Parms)"     "n
                           "///  @return         :  "(p "return: " Return)"     "n
                           "///***************************************************************************"n 
                           ) 
                       "pheader" 
                       "insert a Function header" 
                       'c++-tempo-tags)

;; insert header file preamble 
(tempo-define-template "c-hfile" 
                       '("#ifndef _"_filename_no_ex_upper"_"_filename_ex"_"n
                         "#define _"_filename_no_ex_upper"_"_filename_ex"_"n
                         ""n
                         "#ifdef __cplusplus"n
                         "extern ""\"C""\" {"n
                         "#endif"n
                         ""n
                         "/// @file "_filename" "n
                         ""n
                         "#ifdef __cplusplus"n
                         "}"n
                         "#endif"n
                         ""n
                         "#endif //_"_filename_no_ex_upper"_"_filename_ex"_"n
                         )
                       "hfile" 
                       "insert header file template with preprocessor locks" 
                       'c-tempo-tags)

(tempo-define-template "c++hfile" 
                       '("#ifndef _"_filename_no_ex_upper"_"_filename_ex"_"n
                         "#define _"_filename_no_ex_upper"_"_filename_ex"_"n
                         ""n
                         "/// @file "_filename" "n
                         ""n
                         "#endif //_"_filename_no_ex_upper"_"_filename_ex"_"n
                         )
                       "hfile" 
                       "insert header file template with preprocessor locks" 
                       'c++-tempo-tags)

;; insert include for c file 
(tempo-define-template "c-include"
                       '("#include " "\""_filename_no_ex_low"."_filename_extension"\"" n)
                       "include" 
                       "insert #include \"buffer name\"" 
                       'c-tempo-tags)

;; insert include for c++ file 
(tempo-define-template "c++include"
                       '("#include " "<"_filename_no_ex".hpp>" n)
                       "include" 
                       "insert #include <buffer name>" 
                       'c++-tempo-tags)

;; =============================================================================
