;;; mipc-eshell.el --- eshell functions -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;;; Code:

(require 'em-dirs)
(require 'eshell)

(defconst mipc-eshell-prompt-chars-to-lead 20
  "Maximum number of characters for the leading part of the eshell prompt.")

(defconst mipc-eshell-prompt-chars-to-follow 20
  "Maximum number of characters for the trailing part of the eshell prompt.")

(defun mipc-eshell-prompt-function ()
  (let ((ps1 '())
        (dir (abbreviate-file-name (eshell/pwd))))

    (setq ps1
          (list
           (if (length> dir (+ mipc-eshell-prompt-chars-to-lead
                               mipc-eshell-prompt-chars-to-follow))
               (concat (substring dir
                                  nil (- mipc-eshell-prompt-chars-to-lead 1))
                       ".."
                       (substring dir
                                  (- 1 mipc-eshell-prompt-chars-to-follow)))
             dir)))

    (unless (eshell-exit-success-p)
      (push (format " [%d]" eshell-last-command-status) ps1))

    ;; It should be illegal to name such a stupid company after something as
    ;; beautiful as the Y fixpoint combinator. But I digress.
    (push (cond ((= (file-user-uid) 0) " Y ")
                (" λ "))
          ps1)

    (apply #'concat (nreverse ps1))))

(defun eshell/catfl (&rest files)
  "font-lock, concatenate and print files to eshell."
  (let ((minor-modes))
    (dolist (file-or-mode (flatten-tree files))
      (cond ((string-prefix-p "-" file-or-mode)
             (let ((mode (intern (substring file-or-mode 1))))
               (setq minor-modes (delq mode minor-modes))))
            ((string-prefix-p "+" file-or-mode)
             (let ((mode (intern (substring file-or-mode 1))))
               (unless (memq mode minor-modes)
                 (push mode minor-modes))))
            (t
             (eshell-print (mipc-eshell--catfl1 file-or-mode minor-modes)))))))

(defun mipc-eshell--catfl1 (file &optional minor-modes)
  (with-temp-buffer
    (with-silent-modifications
      (insert-file-contents file t)
      (normal-mode)
      (dolist (mode minor-modes)
        (funcall mode 1))
      (font-lock-ensure)
      ;; attempt to neutralize any problematic text properties
      (remove-text-properties (point-min) (point-max)
                              '(help-echo                      nil
                                help-echo-inhibit-substitution nil
                                left-fringe-help               nil
                                right-fringe-help              nil
                                keymap                         nil
                                local-map                      nil
                                syntax-table                   nil
                                read-only                      nil
                                inhibit-read-only              nil
                                inhibit-isearch                nil
                                field                          nil
                                wrap-prefix                    nil
                                line-prefix                    nil
                                modification-hooks             nil
                                insert-in-front-hooks          nil
                                insert-behind-hooks            nil
                                cursor-sensor-functions        nil
                                minibuffer-message             nil
                                display-line-numbers-disable   nil
                                hard                           nil
                                right-margin                   nil
                                left-margin                    nil
                                justification                  nil)))
    (buffer-substring (point-min) (point-max))))

(defun eshell/catb (&rest args)
  (seq-mapcat
   (lambda (buffer-or-file)
     (if-let* ((buffer (get-buffer buffer-or-file)))
         (with-current-buffer buffer
           (buffer-substring-no-properties (point-min) (point-max)))
       (with-temp-buffer
         (insert-file-contents-literally buffer-or-file)
         (buffer-substring-no-properties (point-min) (point-max)))))
   args
   'string))

(defun eshell/mtdp (&rest args)
  (when-let* ((tempdir (make-temp-file (or (nth 1 args) "cdmktmpdir.") t)))
    (eshell-printn tempdir)
    (eshell/pushd tempdir)))

(defun eshell/gdb (&rest args)
  (gdb (string-join (append `("gdb" "-i=mi" ,(or (car args) "./a.out"))
                            (cdr args))
        " ")))

(provide 'mipc-eshell)

;;; mipc-eshell.el ends here
