;;; mipc-snippet-ccstd.el --- implementation of ccstd snippet  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;;; Code:

(require 'cl-lib)
(require 'yasnippet)

(defvar mipc-snippet-ccstd--dialect-choices)

(defun mipc-snippet-ccstd ()
  (add-hook 'yas-after-exit-snippet-hook #'mipc-snippet-ccstd--1 nil t)
  (setq-local mipc-snippet-ccstd--dialect-choices
              (copy-sequence
               '("-D_DEFAULT_SOURCE"
                 "-D_GNU_SOURCE"
                 "-D_POSIX_C_SOURCE=1"
                 "-D_POSIX_C_SOURCE=2"
                 "-D_POSIX_C_SOURCE=200809L"
                 "-D_POSIX_C_SOURCE=202405L"
                 "-D_XOPEN_SOURCE=500"
                 "-D_XOPEN_SOURCE=600"
                 "-D_XOPEN_SOURCE=700"
                 "-D_XOPEN_SOURCE=800"
                 "-fdefer-ts"
                 "-D__STDC_ALLOC_LIB__=201004L"
                 "-fhosted"
                 "-ffreestanding"
                 "-fplan9-extensions"
                 "-fpermissive"
                 "-D__STDC_NO_VLA__=1 -Werror=vla")))
  (let ((enable-recursive-minibuffers t))
    (yas-expand-snippet
     "-std=${1:$$(yas-choose-value
                  '(\"c2y\" \"c23\" \"gnu23\" \"c17\" \"gnu17\" \"c11\" \"gnu11\"
                    \"c99\" \"gnu99\" \"iso9899:199409\" \"c89\" \"gnu90\"))} $0")))

(defun mipc-snippet-ccstd--1 ()
  (remove-hook 'yas-after-exit-snippet-hook #'mipc-snippet-ccstd--1 t)
  (when (save-excursion (backward-char 6) (looking-at-p (rx "-std= ")))
    (delete-char -6))
  (run-at-time 0 nil #'mipc-snippet-ccstd--2))

(defun mipc-snippet-ccstd--2 ()
  (cl-loop with enable-recursive-minibuffers = t
           do (yas-expand-snippet "${1:$$(mipc-snippet-ccstd--choose-dialect)} $0")
              (yas-next-field)
           until (save-excursion (backward-char 2) (looking-at-p (rx " ")))
           finally do (delete-char -2)))

(defun mipc-snippet-ccstd--choose-dialect ()
  (when-let* ((choice (yas-choose-value mipc-snippet-ccstd--dialect-choices)))
    (delete choice mipc-snippet-ccstd--dialect-choices)
    choice))

(provide 'mipc-snippet-ccstd)

;;; mipc-snippet-ccstd.el ends here
