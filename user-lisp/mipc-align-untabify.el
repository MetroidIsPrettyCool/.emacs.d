;;; mipc-align-untabify.el --- align and untabify tabulated files -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;;; Code:

(defun mipc-align-untabify (start end &optional tabulation-width)
  "Replace tabs and align tabulated lines in region/buffer with spaces."
  (interactive
   (list (when (use-region-p) (region-beginning))
         (when (use-region-p) (region-end))
         (when current-prefix-arg (prefix-numeric-value current-prefix-arg))))
  (save-excursion
    (save-restriction
      (when (and start end)
        (narrow-to-region start end))
      (goto-char (point-min))
      (let ((lines nil)
            (field-max-lengths nil)
            (width (or tabulation-width 2)))
        (while
            (progn
              (let ((line
                     (string-split (thing-at-point 'line t)
                                   (format "\t\\| \\{%d,\\}" width))))
                (when (cdr line)
                  (setf (car line)
                        (string-trim-right (car line))

                        (cdr line)
                        (seq-map #'string-trim (cdr line)))
                  (setq field-max-lengths
                        (mipc-align-untabify--process-fields
                         field-max-lengths
                         line))
                  (push (cons (point) line) lines)))
              (and (= 0 (forward-line 1))
                   (not (= (point) (point-max))))))
        (while lines
          (let ((line (pop lines)))
            (goto-char (car line))
            (delete-line)
            (mipc-align-untabify--insert-fields width
                                                  field-max-lengths
                                                  (cdr line))
            (delete-char (- width))
            (insert "\n")))))))

(defun mipc-align-untabify--insert-fields
    (tabulation-width field-max-lengths-remaining fields-remaining)
  (let ((field-max-length (car field-max-lengths-remaining))
        (field (car fields-remaining)))
    (insert field
            (make-string (+ tabulation-width (- field-max-length (length field))) ?\s))
    (when (cdr fields-remaining)
      (mipc-align-untabify--insert-fields
       tabulation-width
       (cdr field-max-lengths-remaining)
       (cdr fields-remaining)))))

(defun mipc-align-untabify--process-fields
    (field-max-lengths-remaining fields-remaining)
  (let ((field-max-length (car field-max-lengths-remaining))
        (field            (car fields-remaining)))
    (cons
     (or (and field-max-length (max field-max-length (length field)))
         (length field))

     (if (cdr fields-remaining)
         (mipc-align-untabify--process-fields
          (cdr field-max-lengths-remaining)
          (cdr fields-remaining))
       (cdr field-max-lengths-remaining)))))

(provide 'mipc-align-untabify)

;;; mipc-align-untabify.el ends here
