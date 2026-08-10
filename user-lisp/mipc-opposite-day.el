;;; mipc-opposite-day.el --- opposites of built in functions -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;;; Code:

(defun mipc-unfill-paragraph ()
  "Un-fill a paragraph at point.

Essentially the opposite of `fill-paragraph'"
  (interactive)
  (let ((fill-column (point-max)))
    (fill-paragraph nil)))

(defun mipc-yank-pop-forwards (uarg)
  "`yank-pop' with a reversed understanding of the prefix uargument."
  (interactive "p")
  (yank-pop (- uarg)))

(defun mipc-deactivate-mark (uarg)
  "Interactive wrapper around `deactivate-mark'."
  (interactive "p")
  (deactivate-mark uarg))

(defun mipc-other-window-backward (count &optional all-frames interactive)
  "`other-window' with a reversed understanding of the count argument."
  (interactive "p")
  (other-window (- count)))

(provide 'mipc-opposite-day)

;;; mipc-opposite-day.el ends here
