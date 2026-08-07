;;; adora-theme.el --- personal Emacs theme  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; Author: Joseph Burke
;; Maintainer: Joseph Burke
;; Created:  3 Nov 2025
;; Version: 0.1.1
;; Keywords: theme

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Hacked up from the built-in Wombat theme.

;;; Code:

(deftheme adora
  "Personal theme color-picked from screenshots of She-Ra.

That's \"Princesses of Power\", not the original. Say what you will,
that show looks gorgeous."
  :background-mode 'dark)

(custom-theme-set-faces
 'adora
 '(cursor ((t (:background "#68656c"))))
 '(highlight ((t (:foreground "#ffffff" :background "#454249" :underline t))))
 '(region ((t (:background "#454249"))))
 '(secondary-selection ((t (:foreground "#fef9fe" :background "#8e153d"))))
 '(isearch ((t (:foreground "#868a8e" :background "#3e4a41"))))
 '(lazy-highlight ((t (:foreground "#d4d8dd" :background "#3e4a41"))))
 '(mode-line ((t (:foreground "#fef9fe" :background "#454249"))))
 '(mode-line-inactive ((t (:foreground "#868a8e" :background "#454249"))))
 '(minibuffer-prompt ((t (:foreground "#fb566b"))))
 '(escape-glyph ((t (:foreground "#a87f64" :weight bold))))
 '(homoglyph ((t (:foreground "#a87f64" :weight bold))))
 '(font-lock-builtin-face ((t (:foreground "#ffa754"))))
 '(font-lock-comment-face ((t (:foreground "#d4b352"))))
 '(font-lock-constant-face ((t (:foreground "#c2fbfb"))))
 '(font-lock-function-name-face ((t (:foreground "#dcb58e"))))
 '(font-lock-keyword-face ((t (:foreground "#ffa754" :weight bold))))
 '(font-lock-string-face ((t (:foreground "#ebd89d"))))
 '(font-lock-type-face ((t (:foreground "#fb566b" :weight bold))))
 '(font-lock-variable-name-face ((t (:foreground "#ebd89d"))))
 '(font-lock-warning-face ((t (:foreground "#b53e5c"))))
 '(help-key-binding ((t (:foreground "#fef9fe" :background "#3e4a41"))))
 '(link ((t (:foreground "#c2fbfb" :underline t))))
 '(link-visited ((t (:foreground "#fb566b" :underline t))))
 '(button ((t (:foreground "#fef9fe" :background "#3e4a41"))))
 '(header-line ((t (:foreground "#dcb58e" :background "#3e4a41"))))
 '(gnus-group-news-1 ((t (:foreground "#8ee597" :weight bold))))
 '(gnus-group-news-1-low ((t (:foreground "#8ee597"))))
 '(gnus-group-news-2 ((t (:foreground "#a87f64" :weight bold))))
 '(gnus-group-news-2-low ((t (:foreground "#a87f64"))))
 '(gnus-group-news-3 ((t (:foreground "#d4b352" :weight bold))))
 '(gnus-group-news-3-low ((t (:foreground "#d4b352"))))
 '(gnus-group-news-4 ((t (:foreground "#868a8e" :weight bold))))
 '(gnus-group-news-4-low ((t (:foreground "#868a8e"))))
 '(gnus-group-news-5 ((t (:foreground "#a87f64" :weight bold))))
 '(gnus-group-news-5-low ((t (:foreground "#a87f64"))))
 '(gnus-group-news-low ((t (:foreground "#868a8e"))))
 '(gnus-group-mail-1 ((t (:foreground "#8ee597" :weight bold))))
 '(gnus-group-mail-1-low ((t (:foreground "#8ee597"))))
 '(gnus-group-mail-2 ((t (:foreground "#a87f64" :weight bold))))
 '(gnus-group-mail-2-low ((t (:foreground "#a87f64"))))
 '(gnus-group-mail-3 ((t (:foreground "#d4b352" :weight bold))))
 '(gnus-group-mail-3-low ((t (:foreground "#d4b352"))))
 '(gnus-group-mail-low ((t (:foreground "#868a8e"))))
 '(gnus-header-content ((t (:foreground "#c2fbfb"))))
 '(gnus-header-from ((t (:foreground "#8ee597" :weight bold))))
 '(gnus-header-subject ((t (:foreground "#a87f64"))))
 '(gnus-header-name ((t (:foreground "#c2fbfb"))))
 '(gnus-header-newsgroups ((t (:foreground "#a87f64"))))
 '(message-header-name ((t (:foreground "#c2fbfb" :weight bold))))
 '(message-header-cc ((t (:foreground "#8ee597"))))
 '(message-header-other ((t (:foreground "#8ee597"))))
 '(message-header-subject ((t (:foreground "#a87f64"))))
 '(message-header-to ((t (:foreground "#a87f64"))))
 '(message-cited-text-1 ((t (:foreground "#868a8e"))))
 '(message-separator ((t (:foreground "#fb566b" :weight bold))))
 '(ansi-color-black ((t (:foreground "#060418" :background "#060418"))))
 '(ansi-color-red ((t (:foreground "#b53e5c" :background "#b53e5c"))))
 '(ansi-color-green ((t (:foreground "#5fb56b" :background "#5fb56b"))))
 '(ansi-color-yellow ((t (:foreground "#d4b352" :background "#d4b352"))))
 '(ansi-color-blue ((t (:foreground "#4b6696" :background "#4b6696"))))
 '(ansi-color-magenta ((t (:foreground "#956d92" :background "#956d92"))))
 '(ansi-color-cyan ((t (:foreground "#71b7af" :background "#71b7af"))))
 '(ansi-color-white ((t (:foreground "#fef9fe" :background "#fef9fe"))))
 '(ansi-color-bright-black ((t (:foreground "#454249" :background "#454249"))))
 '(ansi-color-bright-red ((t (:foreground "#fb566b" :background "#fb566b"))))
 '(ansi-color-bright-green ((t (:foreground "#8ee597" :background "#8ee597"))))
 '(ansi-color-bright-yellow ((t (:foreground "#ebd89d" :background "#ebd89d"))))
 '(ansi-color-bright-blue ((t (:foreground "#c2fbfb" :background "#c2fbfb"))))
 '(ansi-color-bright-magenta ((t (:foreground "#e395ff" :background "#e395ff"))))
 '(ansi-color-bright-cyan ((t (:foreground "#69f0e1" :background "#69f0e1"))))
 '(ansi-color-bright-white ((t (:foreground "#ffffff" :background "#ffffff"))))
 '(tab-bar ((t (:foreground "#060418" :background "#ebd89d"))))
 '(tab-bar-tab ((t (:foreground "#060418" :background "#fef9fe"))))
 '(tab-bar-tab-inactive ((t (:foreground "#060418" :background "#d4b352"))))
 '(rainbow-delimiters-depth-1-face ((t (:foreground "#fef9fe"))))
 '(rainbow-delimiters-depth-2-face ((t (:foreground "#d4d8dd"))))
 '(rainbow-delimiters-depth-3-face ((t (:foreground "#fb566b"))))
 '(rainbow-delimiters-depth-4-face ((t (:foreground "#ffa754"))))
 '(rainbow-delimiters-depth-5-face ((t (:foreground "#d4b352"))))
 '(rainbow-delimiters-depth-6-face ((t (:foreground "#8ee597"))))
 '(rainbow-delimiters-depth-7-face ((t (:foreground "#69f0e1"))))
 '(rainbow-delimiters-depth-8-face ((t (:foreground "#c2fbfb"))))
 '(rainbow-delimiters-depth-9-face ((t (:foreground "#e395ff"))))
 '(fringe ((t (:background "#141322"))))
 '(default ((t (:foreground "#fef9fe" :background "#060418")))))

(provide-theme 'adora)

;;; adora-theme.el ends here
