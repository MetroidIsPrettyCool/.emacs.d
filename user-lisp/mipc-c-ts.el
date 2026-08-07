;;; mipc-c-ts.el --- extensions to c-ts-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; Author: Joseph Burke
;; Maintainer: Joseph Burke
;; Created:  7 Aug 2026
;; Version: 0.1.0

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;;; Code:

(require 'c-ts-mode)
(require 'text-property-search)

;;;###autoload
(defun mipc-c-ts-indent-style ()
  "TODO: rewrite to be more query-based."
  `(((parent-is ,(rx bos "translation_unit" eos)) column-0 0)

    (mipc-c-ts-comment-star-at-bol        parent 1)
    ((match null ,(rx bos "comment" eos)) parent 3)

    ((match ,(rx bos "string_literal" eos)
            ,(rx bos "concatenated_string" eos))
     parent 0)

    ((parent-is ,(rx bos "preproc_arg" eos)) parent 0)

    (mipc-c-ts-parent-is-once-guard column-0 0)

    (no-node standalone-parent c-ts-mode-indent-offset)

    ((n-p-gp ,(rx bos "labeled_statement" eos)
             ,(rx bos "case_statement" eos)
             "")
     standalone-parent 0)

    ((n-p-gp ""
             ,(rx bos "labeled_statement" eos)
             ,(rx bos "case_statement" eos))
     standalone-parent c-ts-mode-indent-offset)

    ((node-is ,(rx bos "labeled_statement" eos)) standalone-parent
     c-ts-mode-indent-offset)
    ((parent-is ,(rx bos "labeled_statement" eos)) standalone-parent 0)

    ((node-is ,(rx bos (or "{" "}") eos)) standalone-parent 0)
    ((match ,(rx bos "]" eos) ,(rx bos "array_declarator" eos))
     standalone-parent 0)

    ((node-is ,(rx bos "else_clause" eos))
     standalone-parent 0)

    ((node-is ,(rx bos "case_statement" eos))
     standalone-parent c-ts-mode-indent-offset 2)
    ((parent-is ,(rx bos "case_statement" eos))
     parent-bol c-ts-mode-indent-offset)

    ((query ((declaration (attribute_declaration) (_) @me)))
     standalone-parent 0)

    ((parent-is ,(rx bos "function_" (or "declarator" "definition") eos))
     standalone-parent 0)

    ((node-is ,(rx bos (or "argument_list" "parameter_list") eos))
     standalone-parent 0)
    ((match ,(rx bos "(" eos) ,(rx bos "for_statement" eos)) parent 0)

    ((match ,(rx bos "compound_statement" eos)
            ,(rx bos (or "for" "if") "_statement" eos))
     parent-bol 0)

    ((match ,(rx bos "expression_statement" eos)
            ,(rx bos "for_statement" eos))
     parent-bol c-ts-mode-indent-offset)

    ((match ,(rx bos ")" eos)
            ,(rx bos
                 (or "parameter_list" "argument_list" "for_statement")
                 eos))
     standalone-parent 0)
    ((n-p-gp ,(rx bos ")" eos)
             ,(rx bos "parenthesized_expression" eos)
             ,(rx bos (or "while" "if" "do") "_statement" eos))
     standalone-parent 0)
    ((node-is ,(rx bos ")" eos)) parent 0)

    ((match nil ,(rx bos (or "argument_list" "parameter_list") eos) nil 1 1)
     standalone-parent c-ts-mode-indent-offset)
    ((match nil ,(rx bos "for_statement" eos) nil 2 2)
     standalone-parent c-ts-mode-indent-offset)

    ((match nil ,(rx bos (or "argument_list" "parameter_list") eos) nil 2)
     (nth-sibling 1) 0)
    ((match nil ,(rx bos "for_statement" eos) nil 3)
     (nth-sibling 2) 0)

    ((parent-is ,(rx bos "argument_list" eos))
     standalone-parent c-ts-mode-indent-offset)

    ((parent-is ,(rx bos "initializer_list" eos))
     standalone-parent c-ts-mode-indent-offset)

    ((n-p-gp ""
             ,(rx bos "parenthesized_expression" eos)
             ,(rx bos (or "while" "if" "do") "_statement" eos))
     standalone-parent c-ts-mode-indent-offset)

    ((node-is ,(rx bos (or (seq (*? any) "_statement") "declaration") eos))
     standalone-parent c-ts-mode-indent-offset)

    ;; ((node-is ,(rx bos "compound_statement" eos)) first-sibling 0)
    ((parent-is
      ,(rx bos (or "compound_statement" "attributed_declarator") eos))
     standalone-parent c-ts-mode-indent-offset)

    ((parent-is ,(rx bos (*? any) "_expression" eos))
     first-sibling 0)

    ((node-is ,(rx bos
                   (or "preproc_elif" "preproc_else" "#elif" "#elifdef"
                       "#elifndef" "#else" "#endif")
                   eos))
     parent-bol 0)

    (catch-all standalone-parent c-ts-mode-indent-offset)))

(defun mipc-c-ts-parent-is-once-guard (_node parent _bol)
  "TODO: rewrite to use a query."
  (when t ;; (and node parent)
    (when-let* ((parent)
                (parent-type      (treesit-node-type parent))
                (grandparent      (treesit-node-parent parent))
                (grandparent-type (treesit-node-type grandparent))
                (child-0          (treesit-node-child parent 0))
                (child-0-type     (treesit-node-type child-0))
                (child-1          (treesit-node-child parent 1))
                (child-1-type     (treesit-node-type child-1))
                (child-1-txt      (treesit-node-text child-1))
                (child-2          (treesit-node-child parent 2))
                (child-2-type     (treesit-node-type child-2))
                (child-2-0        (treesit-node-child child-2 0))
                (child-2-0-type   (treesit-node-type child-2-0))
                (child-2-1        (treesit-node-child child-2 1))
                (child-2-1-type   (treesit-node-type child-2-1))
                (child-2-1-txt    (treesit-node-text child-2-1)))
      (and (string-equal grandparent-type "translation_unit")
           (string-equal parent-type      "preproc_ifdef")
           (string-equal child-0-type     "#ifndef")
           (string-equal child-1-type     "identifier")
           (string-equal child-2-type     "preproc_def")
           (string-equal child-2-0-type   "#define")
           (string-equal child-2-1-type   "identifier")
           (string-suffix-p "_H" child-1-txt)
           (string-equal child-1-txt child-2-1-txt)))))

(defun mipc-c-ts-comment-star-at-bol (node parent bol)
  (when (and (not node) parent bol)
    (when-let* ((parent-type (treesit-node-type parent)))
      (and (string-equal parent-type "comment")
           (= (char-after bol) ?*)))))

;;;###autoload
(defun mipc-c-ts-extra-font-lock-rules ()
  "Install additional treesitter font-lock rules in buffer.

TODO: (upstream) waiting for
https://github.com/tree-sitter/tree-sitter-c/pull/293"
  (setq-local
   treesit-font-lock-settings
   (append
    treesit-font-lock-settings
    (treesit-font-lock-rules
     :language 'c :override t :feature 'preprocessor
     `(;; highlight the defined operator like cc-mode
       (preproc_defined "defined" @font-lock-preprocessor-face)
       ;; highlight __VA_ARGS__ and __VA_OPT__ with `mipc-c-treesit--fontify-va-idents'
       ((preproc_arg) @mipc-c-treesit--fontify-va-idents)
       ;; highlight the new c23 preprocessor operators. TODO update when grammar makes these 1st
       ;; class. note that we only highlight when they're call expressions and not when they're e.g.
       ;; the subject of a defined query as a reminder to check and use in two different directives.
       (call_expression function: (identifier) @font-lock-preprocessor-face
                        (:match ,(rx bos
                                     (or "__has_include"
                                         "__has_embed"
                                         "__has_c_attribute")
                                     eos)
                                @font-lock-preprocessor-face)
                        (:pred mipc-c-ts--node-in-preproc-condition
                               @font-lock-preprocessor-face)))

     :language 'c :override t :feature 'keyword
     `(;; highlight the c23 constexpr qualifier
       (type_qualifier "constexpr" @font-lock-keyword-face)
       ;; highlight the c11 alignas qualifier
       (alignas_qualifier [ "alignas" "_Alignas" ] @font-lock-keyword-face)
       ;; highlight the c11 alignof operator
       (alignof_expression [ "alignof" "_Alignof" ] @font-lock-keyword-face)
       ;; highlight the c11 generic operator
       (generic_expression "_Generic" @font-lock-keyword-face)
       ;; highlight the c11 static_assert declaration and c2y countof operator. TODO update when
       ;; grammar makes these 1st class.
       ((identifier) @font-lock-keyword-face
        (:match ,(rx bos
                     (or (seq (or "_S" "s") "tatic_assert")
                         (seq (or "_C" "c") "ountof"))
                     eos)
                @font-lock-keyword-face)))

     :language 'c :override t :feature 'type
     `(;; attempt to encourage highlighting types in the alignas qualifier
       (alignas_qualifier
        [ "alignas" "_Alignas" ]
        "(" :anchor (identifier) @font-lock-type-face :anchor ")")
       ;; attempt to highlight the c23 bitint and typeof type specifiers. TODO update when grammar
       ;; makes these 1st class.
       ((identifier) @font-lock-type-face
        (:match ,(rx bos (or "_BitInt" (seq "typeof" (? "_unqual"))) eos)
                @font-lock-type-face))))))

  (treesit-font-lock-recompute-features))

(defun mipc-c-ts--node-in-preproc-condition (node)
  (catch 'found
    (while t
      (let ((parent (treesit-node-parent node)))
        (unless parent (throw 'found nil))
        (when (and (string-match-p (rx bos "preproc_" (? "el") "if" eos)
                                   (treesit-node-type parent))
                   (string-equal (treesit-node-field-name node) "condition"))
          (throw 'found t))
        (setq node parent)))))

(defun mipc-c-ts--fontify-va-idents (_node override start end &rest _)
  (save-excursion
    (save-match-data
      (with-silent-modifications
        (let ((inhibit-read-only t))
          (goto-char start)
          (while (search-forward-regexp
                  (rx symbol-start "__VA_" (or "ARGS" "OPT") "__" symbol-end)
                  end t)
            (unless (and (not override)
                         (save-excursion
                           (when (text-property-search-backward
                                  'face 'font-lock-preprocessor-face t)
                             (> (point) (match-beginning 0)))))
              (put-text-property (match-beginning 0) (match-end 0)
                                 'face 'font-lock-preprocessor-face))))))))

(defvar mipc-c-ts--no-delims-syntax-table
  (let ((table (make-syntax-table c-ts-mode-syntax-table)))
    (dolist (c (list ?\C-j ?\C-m ?\" ?\' ?\( ?\) ?\[ ?\] ?\{ ?\}
                     8261 8262 8317 8318 8333 8334 9001 9002 9140
                     9141 10088 10089 10090 10091 10092 10093 10096 10097
                     10098 10099 10100 10101 10214 10215 10216 10217 10218
                     10219 10627 10628 10629 10630 10631 10632 10633 10634
                     10635 10636 10637 10638 10639 10640 10641 10642 10643
                     10644 10645 10646 10647 10648 10748 10749 12296 12297
                     12298 12299 12300 12301 12302 12303 12304 12305 12308
                     12309 12310 12311 12312 12313 12314 12315 64830 64831
                     65077 65078 65079 65080 65081 65082 65083 65084 65085
                     65086 65087 65088 65089 65090 65091 65092 65113 65114
                     65115 65116 65117 65118 65288 65289 65339 65341 65371
                     65373 65375 65376 65378 65379))
      (modify-syntax-entry c "." table))
    table)
  "Syntax table to use in c-ts-mode where we won't recognize delimiters.

This table (by default) inherits from `c-ts-mode-syntax-table', but with
every delimiter character syntax entry changed to have punctuation
class.

The list of characters used to initialize this variable was found with
the following expression:

(cl-loop for i upfrom 0
       for elt across c-ts-mode-syntax-table
       append (when-let* ((class (or (and (consp elt)   (car elt))
                                     (and (numberp elt) elt)))
                          ((memq (logand class 15)
                                 \='(4 5 7 8 11 12 14 15))))
                (list i)))")

(defvar mipc-c-ts--num-lit-syntax-table
  (let ((table (make-syntax-table c-ts-mode-syntax-table)))
    (modify-syntax-entry ?\' "." table)
    table))

(defconst mipc-c-ts--no-delims-query
  (treesit-query-compile 'c '(((char_literal) @n)
                              ((comment) @n)
                              (preproc_def value: (_) @n))))

(defconst mipc-c-ts--num-lit-query
  (treesit-query-compile 'c '((number_literal) @n)))

;;;###autoload
(defun mipc-c-ts-adjust-syntax-table ()
  ;; alternative we could consider: change the buffer syntax table to one that
  ;; treats apostrophes as punctuation and propertize char_literal nodes
  ;; instead

  ;; (set-syntax-table mipc-c-ts-syntax-table)
  (setq-local syntax-propertize-function #'mipc-c-ts--syntax-propertize))

(defun mipc-c-ts--syntax-propertize (start end)
  (let ((on (treesit-node-on start end 'c)))
    (dolist (range
             (treesit-query-range on mipc-c-ts--num-lit-query start end))
      (put-text-property (car range) (cdr range)
                         'syntax-table mipc-c-ts--num-lit-syntax-table))
    (dolist (range
             (treesit-query-range on mipc-c-ts--no-delims-query start end))
      (put-text-property (car range) (cdr range)
                         'syntax-table mipc-c-ts--no-delims-syntax-table))))

(provide 'mipc-c-ts)

;;; mipc-c-ts.el ends here
