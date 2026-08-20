;;; mipc-misc.el --- misc functions -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;;; Code:

(require 'thingatpt)
(require 'treesit)
(require 'url)

(defun mipc-yank-with-target (target)
  "Yank system clipboard contents using a specific ICCCM TARGET atom."
  (interactive
   (if buffer-read-only
       (user-error "Buffer is read-only: %S" (current-buffer))
     (list (intern (completing-read
                    "Target Atom: "
                    (or (seq-into (gui-get-selection 'CLIPBOARD 'TARGETS)
                                  'list)
                        (list 'UTF8_STRING 'COMPOUND_TEXT
                              'STRING      'text/plain\;charset=utf-8
                              'text/plain  'text/html
                              'TIMESTAMP   'TARGETS)))))))

  (let ((interprogram-paste-function
         (lambda ()
           (let ((s (gui-get-selection 'CLIPBOARD target)))
             (cond ((stringp s) s)
                   (s           (format "%S" s))
                   (t           (error "No data for atom!")))))))
    (yank)))

(defun mipc-de-ocr-buffer (&optional buffer)
  "Replace fancy/broken UCS characters in BUFFER with ASCII equivalents.

I just use it to clean up copy-pasted OCR'ed text for when I'm working
in Org mode.

BUFFER may be nil, in which case it will operate on the current buffer."
  (interactive)
  (with-current-buffer (or buffer (current-buffer))
    (save-mark-and-excursion
      (save-match-data
        (while (re-search-forward "—" nil t)   ; Em Dash
          (replace-match "--"))
        (while (re-search-forward (rx (| "–"   ; En Dash
                                         "¬")) ; Not Sign, I've seen OCR mix these up
                                  nil t)
          (replace-match "-"))
        (while (re-search-forward (rx (| "“"   ; Left Double Quotation Mark
                                         "”")) ; Right Double Quotation Mark
                                  nil t)
          (replace-match "\""))
        (while (re-search-forward (rx (| "‘"   ; Left Single Quotation Mark
                                         "’")) ; Right Single Quotation Mark
                                  nil t)
          (replace-match "'"))))))

(defun mipc-goto-opposite-show-paren ()
  "Go to the opposite paren as highlighted by `show-paren-mode'."
  (interactive)
  (unless show-paren-mode
    (user-error
     "Cannot go to opposite showed delimiter: show-paren-mode is not enabled"))
  (pcase (funcall show-paren-data-function)
    (`(,_here-beg ,_here-end ,there-beg ,_there-end ,mismatch)
     (if mismatch (user-error "No matching delimiter")
       (goto-char there-beg)))
    (_ (user-error "Point not at delimiter"))))

(defun mipc-to-wp-pastable (&optional start end preserve-breaks para-lines)
  "Convert region between START and END to be pastable in WordPress.

If START and/or END are nil, the values of (`point-min')
or (`point-max') will be used instead, respectively.

If PRESERVE-BREAKS is non-nil, single line breaks will be converted to
<br/>s; otherwise the relevant paragraphs will be un-filled.

Runs of line breaks shorter than PARA-LINES are converted to a <br/>s,
runs of equal or greater length are considered paragraph breaks. If
PARA-LINES is nil, the default is 2.

Interactively, C-u NUMBER M-x mipc-to-wp-pastable RET will set
PARA-LINES explicitly, M-x mipc-to-wp-pastable RET or C-u M-x
mipc-to-wp-pastable RET will set PARA-LINES to 2, and any other prefix
argument will set PARA-LINES to 3; and any non-nil prefix argument will
set PRESERVE-BREAKS to non-nil."
  (interactive (list (when (use-region-p) (region-beginning))
                     (when (use-region-p) (region-end))
                     current-prefix-arg
                     (cond ((numberp current-prefix-arg)    current-prefix-arg)
                           ((not current-prefix-arg)        2)
                           ((equal current-prefix-arg '(4)) 2)
                           (t                               3))))
  (let ((start (or start (point-min)))
        (end   (or end   (point-max)))
        (prev-buffer (current-buffer)))
    (with-temp-buffer
      (save-match-data
        (insert-buffer-substring prev-buffer start end)
        (unless preserve-breaks
          (let ((fill-column (point-max)))
            (fill-region (point-min) (point-max))))
        (goto-char (point-min))
        (insert "<meta http-equiv=\"content-type\""
                " content=\"text/html; charset=utf-8\">"
                "<!-- wp:paragraph -->\n<p>")
        (while (search-forward-regexp (rx (any ?& ?< ?> ?\" ?')) (point-max) t)
          (replace-match (pcase (match-string 0)
                           ("&"  "&amp;")
                           ("<"  "&lt;")
                           (">"  "&gt;")
                           ("\"" "&quot;")
                           ("'"  "&#39;"))
                         t t))
        (goto-char (point-min))
        (while (search-forward-regexp (rx (+ "\n")) (point-max) t)
          (let* ((str (match-string 0))
                 (len (length str)))
            (replace-match
             (if (< len para-lines) (apply #'concat (make-list len "<br/>"))
               "</p>\n<!-- /wp:paragraph -->\n\n<!-- wp:paragraph -->\n<p>")
             t t)))
        (goto-char (point-max))
        (insert "</p>\n<!-- /wp:paragraph -->\n")
        (let ((tmp-buffer (current-buffer)))
          (with-current-buffer prev-buffer
            (replace-region-contents start end (lambda () tmp-buffer))))))))

(defun mipc-reformat-datetime-region (beg end)
  "Parse the region as a datetime and reformat it."
  (interactive "r")
  (replace-region-contents
   beg end
   (lambda ()
     (let* ((datetime-str (buffer-substring-no-properties (point-min)
                                                          (point-max)))
            (datetime (parse-time-string datetime-str))
            (date-fmt)
            (time-fmt)
            (zone-fmt ""))
       (when (decoded-time-day datetime)
         (push "%d" date-fmt))
       (when (decoded-time-month datetime)
         (push "%m" date-fmt))
       (when (decoded-time-year datetime)
         (push "%+4Y" date-fmt))
       (setq date-fmt (string-join date-fmt "-"))

       (when (decoded-time-second datetime)
         (push "%H" time-fmt))
       (when (decoded-time-minute datetime)
         (push "%M" time-fmt))
       (when (decoded-time-hour datetime)
         (push "%S" time-fmt))
       (setq time-fmt (string-join time-fmt "-"))

       (when (decoded-time-zone datetime)
         (setq zone-fmt "%z"))

       (format-time-string
        (string-join (list date-fmt time-fmt zone-fmt) " ")
        (date-to-time datetime-str)
        t)))))

(defvar mipc--displaying-zero-width-chars t)

;; Maybe this ↓ should be a minor mode? Using font-lock and all that?

(defconst mipc--zero-width-characters
  '((#x200B . ("ZWSP" . 'empty-box))  ; ZERO WIDTH SPACE
    (#x200C . ("ZWNJ" . 'empty-box))  ; ZERO WIDTH NON-JOINER
    (#x200D . ("ZWJ"  . 'empty-box))  ; ZERO WIDTH JOINER
    (#xFEFF . ("ZBOM" . 'empty-box))) ; ZERO WIDTH NO-BREAK SPACE (BOM)
  "Alist of characters we want to display as zero-width.

Association of (CODEPOINT-OR-RANGE . DISPLAY) pairs, where DISPLAY is
some \"element\" as described in the help page for
`glyphless-char-display'.")

(defun mipc-toggle-display-zero-width-chars ()
  "Toggle drawing zero-width characters."
  (interactive)
  (dolist (char mipc--zero-width-characters)
    (set-char-table-range
     glyphless-char-display (car char)
     (if mipc--displaying-zero-width-chars 'zero-width (cdr char))))
  (setq mipc--displaying-zero-width-chars
        (not mipc--displaying-zero-width-chars)))

(defun mipc-dump-buffer-local-variables ()
  (interactive)
  (with-temp-buffer-window "*Local Variables Dump*"
      #'display-buffer-reuse-window
      nil
    (prin1 (buffer-local-variables))))

(defun mipc-cdmktempdir ()
  "Create a temporary directory and visit it with `dired'."
  (interactive)
  (when-let* ((tempdir (make-temp-file "cdmktmpdir." t)))
    (message tempdir)
    (dired tempdir)))

(defun mipc-wiktionary-dwim ()
  "Search for the region or word at point on the English Wiktionary."
  (interactive)
  (browse-url-xdg-open
   (concat
    "https://en.wiktionary.org/wiki/Special:Search?go=Try+exact+match&search="
    (url-hexify-string (mipc--region-or-word-at-point-no-properties)
                       url-query-key-value-allowed-chars))))

(defun mipc-wikipedia-dwim ()
  "Search for the region or word at point on the English Wikipedia."
  (interactive)
  (browse-url-xdg-open
   (concat
    "https://en.wikipedia.org/wiki/Special:Search?go=Try+exact+match&search="
    (url-hexify-string (mipc--region-or-word-at-point-no-properties)
                       url-query-key-value-allowed-chars)
    "&ns0=1")))

(defun mipc--region-or-word-at-point-no-properties ()
  "Return the region as a string, or the word at point as a string.

Properties are stripped, non-contiguous regions are concatenated."
  (if (region-active-p)
      (let ((region-text (funcall region-extract-function nil)))
        (substring-no-properties (if (listp region-text)
                                     (apply #'concat region-text)
                                   region-text)))
    (word-at-point t)))

(defvar mipc-copy-messages--marker nil)

(defun mipc-copy-messages ()
  "Copy the next command's messages to the kill-ring.

Specifically, registers a `post-command-hook' that checks the *Messages*
buffer for changes after every command, and once this happens
un-registers itself and copies the contents from the end of the
*Messages* buffer at the time you called mipc-copy-messages to the
current end of the *Messages* buffer.

This command does not set `this-command' to `kill-region', so a
subsequent kill command does not append to the same kill ring entry."
  (interactive)
  (add-hook 'post-command-hook
            #'mipc-copy-messages--post-command-hook))

(defun mipc-copy-messages--post-command-hook ()
  (with-current-buffer (get-buffer-create "*Messages*")
    (if (not mipc-copy-messages--marker)
        (setq mipc-copy-messages--marker (point-max-marker))
      (unless (= (point-max) mipc-copy-messages--marker)
        (when (> (point-max) mipc-copy-messages--marker)
          (copy-region-as-kill mipc-copy-messages--marker (point-max)))
        (set-marker mipc-copy-messages--marker nil)
        (setq       mipc-copy-messages--marker nil)
        (remove-hook 'post-command-hook
                     #'mipc-copy-messages--post-command-hook)))))

(defun mipc-foo-scratch (mode)
  (interactive (list (treesit--read-major-mode)))
  (let* ((mode-name (symbol-name mode))
         (mode-name-sans-suffix
          (string-trim-right mode-name
                             (rx (? (or "-ts" "-major")) "-mode" eos)))
         (buffer-name (format "*%s scratch*" mode-name-sans-suffix))
         (buffer-existed (get-buffer buffer-name))
         (buffer (get-buffer-create buffer-name)))
    (unless buffer-existed
      (with-current-buffer buffer
        (funcall mode)
        (when-let* ((tempdir (make-temp-file "cdmktmpdir." t)))
          (setq-local default-directory (file-name-as-directory tempdir)))))
    (display-buffer buffer '(nil . ((post-command-select-window . t))))))

(defun mipc-dont-fuck-with-whitespace ()
  (interactive)
  (remove-hook 'before-save-hook #'mipc-whitespace-cleanup-unless-exempt t)
  (electric-indent-local-mode -1)
  (setq-local indent-line-function   #'indent-relative
              indent-region-function #'indent-region-line-by-line))

(provide 'mipc-misc)

;;; mipc-misc.el ends here
