;;; ol-tel.el --- support for links to telephone numbers in org-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Joseph Burke

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;;; Code:

(require 'ol)

;;;###autoload
(defun ol-tel-open (path _uarg)
  "Open the telephone number at point with `browse-url-xdg-open'."
  (let ((url (format "tel:%s" path)))
    (browse-url-xdg-open url)))

;;;###autoload
(defun ol-tel-export (path description backend _backend-channel-plist)
  "Format a org-mode telephone number link for export."
  (let ((url (format "tel:%s" path))
        (desc (or description path)))
    (pcase backend
      ('html    (format "<a target=\"_blank\" href=\"%s\">%s</a>" url desc))
      ('latex   (format "\\href{%s}{%s}" url desc))
      ('texinfo (format "@uref{%s,%s}" url desc))
      ('ascii   (format "%s <%s>" desc url))
      (_        url))))

(org-link-set-parameters "tel" :follow 'ol-tel-open :export 'ol-tel-export)

(provide 'ol-tel)

;;; ol-tel.el ends here
