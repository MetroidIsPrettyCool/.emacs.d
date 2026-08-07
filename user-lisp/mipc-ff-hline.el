;;; mipc-ff-hline.el --- font-lock form feeds as horizontal lines  -*- lexical-binding: t; -*-

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

(defgroup mipc-ff-hline nil
  "Customization group for `mipc-ff-hline-mode'."
  :group 'tools)

(defface mipc-ff-hline
   '((t :inherit escape-glyph :strike-through t :extend t))
   "Face for horizontal line.")

(defconst mipc-ff-hline-keyword
  `(,(rx bol ?\C-l (group-n 1 ?\C-j)) 1 'mipc-ff-hline))

(define-minor-mode mipc-ff-hline-mode
  "Toggle form feed hline mode.

Form feed characters on their own lines are rendered as horizontal
separators using font-lock-mode, approximately like so:

^L----------------------------------------------------------------------"
  :group 'mipc-ff-hline
  :after-hook
  (funcall
   (if mipc-ff-hline-mode #'font-lock-add-keywords #'font-lock-remove-keywords)
   nil
   (list mipc-ff-hline-keyword)))

(define-globalized-minor-mode mipc-ff-hline-global-mode
  mipc-ff-hline-mode
  mipc-ff-hline-mode--turn-on)

(defun mipc-ff-hline-mode--turn-on ()
  (mipc-ff-hline-mode t))

(provide 'mipc-ff-hline)

;;; mipc-ff-hline.el ends here
