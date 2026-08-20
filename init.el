;;; init.el --- primary Emacs configuration -*- fill-column: 80; lexical-binding: t; -*-

;;; Commentary:

;;;; TODO: apply stuff from Karthinks' Batteries Included With Emacs series.

;; <https://karthinks.com/software/even-more-batteries-included-with-emacs/>
;; Look into `dictionary-tooltip-mode' and Wiktionary integration,
;; `compare-windows', `highlight-changes-mode', `kmacro-edit-lossage',
;; `refill-mode', `scroll-all-mode'.

;;;; TODO: Look into hyperbole.

;;;; TODO: Key combination to toggle fringe. Globally and per-window?

;;;; TODO: Custom shortdoc for `mipc-commands-to-remember'.

;;;; TODO: Changes to make once Emacs 31 lands:

;; See
;; (magit-find-file "emacs-31" (expand-file-name "../etc/NEWS" find-function-C-source-directory))
;; for a list of expected changes.

;; 1. Make use of `mode-line-collapse-minor-modes'. I'm tired of not having a
;;    built-in way to disable minor mode lighters! (Mucking around with alists
;;    notwithstanding.) I love me some minor modes, but I do NOT need visual
;;    confirmation of all eight hundred of them at once. hideshow and sub-word,
;;    you're gonna get it...

;; 2. Don't need to add user-lisp/**/ to `load-path' any more.

;; 3. Enable treesit modes with the `treesit-enabled-modes' user option.

;; 4. Bind `unfill-paragraph' to M-Q, delete `mipc-unfill-paragraph'.

;; 5. Delete `mipc-other-window-backward', this is built in now.

;; 6. Decide if we want to set `y-or-n-p-use-read-key' (Probably? If the new
;;    default requires y RET and n RET -- as the brief description in /etc/NEWS
;;    seems to imply -- that's really annoying.)

;; 7. Learn the following:
;;    - 'C-x w t' and 'C-x w r <left>/<right>' rotate the window layout.
;;    - 'C-x w o <left>/<right>' rotate the windows within the current layout.
;;    - 'C-x w f <left>/<right>/<up>/<down>' flip window layouts.

;; 8. Start using `split-window-preferred-direction'

;; 9. Set `kill-region-dwim'

;; 10. Look into changes to 'electric-pair-pairs' and 'electric-pair-text-pairs'

;; 11. Set `exchange-point-and-mark-highlight-region'.

;; 12. Look into `treesit-simple-indent-add-rules'.

;; 13. Think about `c-ts-mode-enable-doxygen'. Do we want to try doxygen?

;; 14. Set `rust-ts-mode-fontify-number-suffix-as-type'.

;; 15. Set `elisp-fontify-semantically'.

;; 16. Maybe enable `speedbar-prefer-window'?

;; 17. `'FOO-ts-mode-indent-offset' renamed to `'FOO-ts-indent-offset' -- apply
;;     changes accordingly.

;; 18. Apply the new 'R' code letter for 'interactive' forms where appropriate.

;; 19. Look into where `with-work-buffer' might be a good replacement for
;;     `with-temp-buffer'.

;;;; Targets

;; I intend this configuration work well without modification for the latest
;; release version of GNU Emacs, on both my Desktop, with GUI frames and a
;; server-client setup; and on my Android smartphone, with one TUI frame inside
;; Termux.

;; You may encounter problems trying to use this config in any other way, for
;; any other purpose, in any other context. I can only test so much...

;;;; General Conventions

;; Follow advice at C-h R elisp RET g Tips RET

;; Use `elisp-autofmt-buffer' to make life easier.

;; ~use-package~ statements should follow this order:
;; 1.  `:load_path'
;; 2.  `:vc'
;; 3.  `:ensure'
;; 4.  `:requires'
;; 5.  `:after'
;; 6.  `:demand'
;; 7.  `:defer'
;; 8.  `:init'
;; 9.  `:custom'
;; 10. `:bind'
;; 11. `:hook'
;; 12. `:config'

;;;; Key Bindings

;; Throughout this file I use a lot of bindings that involve the "H" modifier.

;; This is the "hyper" key, the next in the logical progression from Meta to
;; Super. It's defined in X for historical reasons (Lisp machines, etc.) but
;; AFAICT nobody has ever sold a PC keyboard with one. Not /commercially,/
;; anyway.

;; Though it isn't officially reserved for user keybinds -- only ~C-c letter~ is
;; -- /I've/ never seen an Emacs package that uses them, so it's pretty safe for
;; user keybinds and (potentially) more ergonomic.

;; If you aren't me, you'll need to modify your keyboard layout in order to bind
;; something to it. Personally, as an X user, I've got an ~.Xmodmap~ that sets
;; my Caps Lock key to ~Control_L~ and my left Control key to ~Hyper_L~. Nobody
;; *needs* Caps Lock, that's what ~C-x C-u~ is for!

;; (Actually, for the rare times that I *do* need to toggle Caps Lock -- like
;; sometimes a script will mess up my modifier state and I need to turn it back
;; off -- I've bound the Menu key to Caps Lock. Nobody needs Caps Lock, but
;; *nobody* needs Menu.)

;;; Code:

;;; Put ~debug-on-*~ Calls Here

;; (debug-on-entry 'get-scratch-buffer-create)

;;; Meta-Configuration

;; Rather than spread everything out into a billion little if-feature-detected
;; guards with no coordination, I've chosen to define a number of named feature
;; flags right up top here, so that later parts of the configuration may
;; reference them as they please.

(defconst mipc-sym-prefix "mipc-"
  "Prefix for all symbols defined in this init file.")

;;;; Keys and Input

(defconst mipc-commands-to-remember
  '((global-text-scale-adjust)
    (ibuffer-filter-by-used-mode ibuffer-mode-map ibuffer)
    (isearch-forward-word)
    (isearch-repeat-forward isearch-mode-map)
    (isearch-toggle-case-fold isearch-mode-map)
    (same-window-prefix)
    (vc-region-history))
  "Alist of commands I use rarely but don't want to forget.

Each entry takes the form (COMMAND &optional MAP REQUIRE), where MAP
will be passed to `where-is-internal' as the key map(s) to look in, and
REQUIRE will be `require'-ed to load the keymap if non-nil.")

(defconst mipc-home-to-hyper
  (not (or (daemonp) (display-graphic-p)))
  "Should we translate <home> to H-?.")

(defconst mipc-swap-backspace-and-del
  (not (or (daemonp) (display-graphic-p)))
  "Should we swap <Backspace> and <DEL>?

This will resolve the \"Backspace invokes help\" problem.")

;;;; Appearance

(defconst mipc-assume-small-screen (eq system-type 'android)
  "Should we should assume our frame is going to be very small?")

(defconst mipc-configure-fonts (or (daemonp) (display-graphic-p))
  "Should we configure fonts?")

(defconst mipc-configure-graphical-background
  (or (daemonp) (display-graphic-p))
  "Should we configure the frame background (transparency and hints)?")

;;;; Packages

(defconst mipc-ext-deps
  (pcase system-type
    ('gnu/linux '(ls
                  bash
                  esbuild
                  git
                  html-tidy
                  libvterm
                  rust-analyzer
                  slint-lsp
                  (jdks . [(:name
                            "JavaSE-17"
                            :path
                            "/usr/lib/jvm/java-17-openjdk/"
                            :default
                            t)
                           (:name
                            "JavaSE-21"
                            :path
                            "/usr/lib/jvm/java-21-openjdk/")])
                  eclipse-jdt-ls
                  xdg-open
                  tree-sitter
                  clang
                  mupdf))
    ('android   '(ls bash git)))
  "Pseudo-alist of external (outside Emacs) dependencies we'll rely on.

See `assoc-default' for what I mean by \"pseudo-alist.\" Values will be
picked out of this list with a call like:

(assoc-default 'foo mipc-ext-deps #'eq t)

Expected formats of associated values are key-specific, I'll document them here:

 'jdks   should be usable as the value of `lsp-java-configuration-runtimes'

Some of these dependencies are fetched or created automatically by
relevant tools, like libvterm, others are system-wide. Either way: if
they aren't listed here, we shouldn't do anything that needs them. (If
we can help it.)")

(defconst mipc-use-lsp (not (eq system-type 'android))
  "Should we install and configure LSP-related packages?")

(defconst mipc-default-assembly-language
  (pcase (car (split-string system-configuration "-" nil nil))
    ("m68k"                             ; my beloved
     '68000)

    ((or "aarch64"   "aarch64_be"  "arm"           "arm64_32"
         "armeb"     "armebv7r"    "armv4t"        "armv5te"
         "armv6"     "armv6k"      "armv7"         "armv7a"
         "armv7k"    "armv7r"      "armv7s"        "thumbv4t"
         "thumbv5te" "thumbv6m"    "thumbv7a"      "thumbv7em"
         "thumbv7m"  "thumbv7neon" "thumbv8m.base" "thumbv8m.main")
     'arm)

    ((or "mips"        "mips64"        "mips64el"    "mipsel"
         "mipsisa32r6" "mipsisa32r6el" "mipsisa64r6" "mipsisa64r6el")
     'mips)

    ((or "riscv32gc"   "riscv32i"   "riscv32im"
         "riscv32imac" "riscv32imc" "riscv64gc" "riscv64imac")
     'riscv)

    ((or "powerpc" "powerpc64" "powerpc64le") ; would love to have one day...
     'power)

    ("s390x"
     'system/390)

    ((or "sparc" "sparc64" "sparcv9")
     'sparc)

    ((or "wasm32" "wasm64")
     'wasm)

    ((or "i386" "i586" "i686" "x86_64") ; my beloathed
     'x86))

  "What kind of assembler should we configure?")

;;;; Behavior

(defconst mipc-force-single-width-characters nil
  "Should we force Emacs to never treat any character wider than one cell?

Not a very good idea. Appealing, though...")

;;; Set Up Sources

;;;; Load Paths

;; I like to put my manually-installed or self-written Elisp under the "lisp"
;; directory of my user's Emacs data dir.

(defconst mipc-lisp-dir (expand-file-name "user-lisp" user-emacs-directory))
(defconst mipc-data-dir (expand-file-name "user-etc" user-emacs-directory))

(defconst mipc-3rdparty-lisp-dir (expand-file-name "3rdparty" mipc-lisp-dir))
(defconst mipc-themes-dir (expand-file-name "themes" mipc-lisp-dir))

(add-to-list 'load-path mipc-lisp-dir)
(dolist (dir (seq-filter #'file-directory-p
                         (directory-files-recursively mipc-lisp-dir "." t)))
    (add-to-list 'load-path dir))
(add-to-list 'custom-theme-load-path mipc-themes-dir)

;;;; Packages

;; I like up-to-date packages, and I like having lots of packages. I don't,
;; however, completely /trust/ MELPA. So let's prefer gnu and nongnu, even if it
;; means slightly older packages.

;; We're also going to use the use-package macro for as much configuration as
;; possible.

(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(setopt package-install-upgrade-built-in t
        package-archive-priorities       '(("gnu"    . 30)
                                           ("nongnu" . 20)
                                           ("melpa"  . 10)))

(package-initialize)

(require 'use-package)

;;;; Custom File

;; I don't dislike Customize as much as a lot of people seem to, but I also
;; don't really want to just commit its contents to my dotfiles repo. Nobody
;; needs to know my local safe variable lists, do they? /I/ don't even really
;; need to know that.

;; So we'll stick that gobbledygook somewhere else.

(use-package cus-edit
  :demand t
  :custom (custom-file (expand-file-name "custom.el" mipc-lisp-dir))
  :config (load custom-file))

;;; Appearance

;;;; Theme and Default Font

(use-package custom
  :custom (custom-enabled-themes '(adora))
  :config
  (custom-set-faces
   '(default ((t (:family "SauceCode Pro NFM" :height 104))))))

;;;; Background

;; Thank god we don't just have to make the whole frame transparent anymore.
;; Thank you, Po Lu and Emacs 29!

;; Also, dark mode hint.

(when mipc-configure-graphical-background
  (use-package frame
    :custom (frame-background-mode 'dark)
    :config
    (set-frame-parameter (selected-frame) 'alpha-background 90)
    (add-to-list 'default-frame-alist '(alpha-background . 90))))

;;;; Font / Text Settings

;; I'm not particular about very many things, but I really, really despise
;; inconsistent character widths and heights in otherwise monospace contexts.
;; Here lie my vain, hacky attempts to force this issue.

;;;;; Fallback Font

(when mipc-configure-fonts
  (setopt inhibit-compacting-font-caches t
          use-default-font-for-symbols t)

  (defconst mipc-fallback-fonts
    `(,(font-spec :name "Sarasa Mono J")
      ,(font-spec :name "Noto Sans CJK SC")
      ,(font-spec :name "Noto Sans Mono")
      ;; ,(font-spec :name "Noto Sans CJK TC")
      ,(font-spec :name "Symbola")))

  (defconst mipc-font-rescales
    `((,(rx "Noto Sans CJK")  . 0.9)
      ;; (,(rx "Noto Sans Math") . 0.9)
      ))

  (dolist (elt mipc-font-rescales)
    (add-to-list 'face-font-rescale-alist elt))

  (defun mipc-force-default-fontset (frame)
    (with-selected-frame frame
      (dolist (font mipc-fallback-fonts)
        (set-fontset-font t 'unicode font nil 'append))
      (message "Forced fontset for frame %s" (frame-parameter frame 'name))))

  (if (daemonp)
      (add-hook 'after-make-frame-functions 'mipc-force-default-fontset)
    (mipc-force-default-fontset (selected-frame))))

;;;;; HACK: Make All Characters <= 1 Wide

(when mipc-force-single-width-characters
  (setopt cjk-ambiguous-chars-are-wide nil)

  (map-char-table
   (lambda (range width)
     (when (> width 1)
       (set-char-table-range char-width-table range 1)))
   char-width-table))

;;;; Initial Buffer

;; (setopt inhibit-startup-screen t
;;         initial-buffer-choice (expand-file-name "startup-file.org"
;;                                                 mipc-data-dir))

(setopt inhibit-startup-screen t)

;;;; Mode Line

;; On Android, we just want to compress the mode line. There's not a lot of
;; screen space on that thing!

;; On desktop, I want to split up the default mode bar to separate my major mode
;; from my minor modes. The proper way to do this is to write your own
;; functions. I have not done this.

;; Don't do what I'm doing. It's bad. There's no reason to go rummaging around
;; in these internal data structures like this. It works (for now) but you
;; shouldn't do it. I'm just lazy.

(when mipc-assume-small-screen
  (setopt mode-line-compact          t
          mode-line-percent-position nil)) ; Who ever needs this?

(unless mipc-assume-small-screen
  (setopt
   mode-line-compact 'long              ; `list-packages' wigs out otherwise,
                                        ; IDK why. INREQ!
   mode-line-percent-position nil

   mode-line-format
   '("%e"
     mode-line-front-space
     (:propertize
      (""
       mode-line-mule-info
       mode-line-client
       mode-line-modified
       mode-line-remote
       mode-line-window-dedicated)
      display (min-width (6.0)))

     mode-line-frame-identification
     mode-line-buffer-identification

     " "                                       ; Reduced from 3 spaces.

     mode-line-position

     " "                                       ; Spacer I've kept

     ;; Ugly HACK To Pull Out Compilation / Recursive Edit Status & Major Mode

     ;; I tried using backquote, but it didn't work. I clearly messed it up
     ;; somehow. :/ Really should just write this all explicitly...
     (:eval
      (format-mode-line
       (list
        (nth 0 mode-line-modes)                ; Compilation status
        (nth 1 mode-line-modes)                ; Recursive edit open brackets
        ;; ...                                 ; Literal ")"
        (nth 3 mode-line-modes)                ; Major mode
        (nth 4 mode-line-modes)                ; Process status
        (car (last mode-line-modes 2)))))      ; Recursive edit closing brackets

     " "                                       ; Spacer I've added.

     (project-mode-line project-mode-line-format)
     (vc-mode vc-mode)

     mode-line-format-right-align

     ;; Ugly HACK To Pull Out Minor Modes
     (:eval
      (format-mode-line
       (append
        (butlast (nthcdr 5 mode-line-modes) 3) ; List of minor modes
        ;; ...                                 ; Literal ")"
        ;; ...                                 ; Recursive edit closing brackets
        (last mode-line-modes))))              ; Literal spacer " "

     mode-line-misc-info
     " "                                       ; Extra spacer I've added.
     mode-line-end-spaces)))

;;; Configuring Editor Behaviors

;;;; Disable GUI Dialog Boxes

(setopt use-dialog-box nil)

;;;; Window-Splitting

;; I'd rather see a vertical split than a horizontal one.

(unless mipc-assume-small-screen
  (use-package window
    :custom (split-width-threshold 160) (split-height-threshold 90)))

;;;; Enable Some Disabled Commands

(defconst mipc-disabled-to-enable
  '(upcase-region downcase-region narrow-to-region)
  "Disabled commands to enable on startup.")

(dolist (command mipc-disabled-to-enable)
  (put command 'disabled nil))

;;;; Formatting Style

;; One space after a period, fill to about half a frame.

(setopt sentence-end-double-space nil
        fill-column (if mipc-assume-small-screen 50 120))

;;;; Trash, Don't Delete

;; Just to be safe. I always delete things I don't mean to...

(setopt delete-by-moving-to-trash t)

;;; Global Commands and Keys

;; Global commands and key definitions that don't have anything to do with any
;; specific modes.

;; I want easy access to `query-replace-regexp', since it's the most powerful of
;; the *-replace-* functions. Follow it up with !, and it's the same as
;; `replace-regexp'; escape your regexp syntax, and it's the same as
;; `query-replace-string' or `replace-string';

;; I want some convenient opposites of my commonly-used commands,

;; and I also want a few extra convenience helpers.

;;;; But First, Some Housekeeping

(when mipc-swap-backspace-and-del
  ;; (keyboard-translate ?\C-h ?\C-?)
  (key-translate "C-h" "<DEL>")
  (keymap-set global-map "C-x ?" 'help-command))

(when mipc-home-to-hyper
  (unbind-key "<home>" global-map)

  ;; The definition of this function was adapted from an example in the Emacs
  ;; manual, (info "(elisp) Translation Keymaps")
  (defun mipc-hyperify-next-event (prompt)
    (let ((e (read-event)))
      (vector
       (cond ((memq 'hyper (event-modifiers e))
              e)
             ((numberp e)
              (logior (ash 1 24) e))
             ((symbolp e)
              (intern (concat "H-" (symbol-name e))))
             ((consp e)
              (cons (intern (concat "H-" (symbol-name (car e)))) (cdr e)))))))

  (keymap-set function-key-map "<home>" #'mipc-hyperify-next-event))

(cl-loop for c upfrom ?a to ?z
         do (keymap-set function-key-map
                        (format "C-c %c" c) (format "H-%c" c)))

;;;; Global Map / Unbound

(require 'mipc-opposite-day)
(keymap-set global-map "M-Q" #'mipc-unfill-paragraph)
(keymap-set global-map "M-Y" #'mipc-yank-pop-forwards)
(keymap-set global-map "C-x O" #'mipc-other-window-backward)

(keymap-set global-map "<mouse-9>" #'next-buffer)
(keymap-set global-map "<mouse-8>" #'previous-buffer)

(require 'mipc-align-untabify)

(require 'mipc-superscript-region)

(require 'mipc-misc)
(keymap-set global-map "H-y" #'mipc-yank-with-target)
(mipc-toggle-display-zero-width-chars)

;; (use-package mipc-ff-hline :custom (mipc-ff-hline-global-mode t))

;;;; Toggles Map

(defvar-keymap mipc-toggle-map :doc "Keymap for toggle commands.")
(keymap-set global-map "H-t" mipc-toggle-map)

;;;; Search and Replace Map

(defvar-keymap mipc-search-and-replace-map
  :repeat t
  :doc "Keymap for search and replace commands.")
(keymap-set global-map "H-s" mipc-search-and-replace-map)

(keymap-set mipc-search-and-replace-map "H-s" #'search-forward-regexp)
(keymap-set mipc-search-and-replace-map "s"   #'search-forward-regexp)

(keymap-set mipc-search-and-replace-map "H-r" #'query-replace-regexp)
(keymap-set mipc-search-and-replace-map "r"   #'query-replace-regexp)

(keymap-set mipc-search-and-replace-map "H-l" #'list-matching-lines)
(keymap-set mipc-search-and-replace-map "l"   #'list-matching-lines)

(keymap-set mipc-search-and-replace-map "H-g" #'rgrep)
(keymap-set mipc-search-and-replace-map "g"   #'rgrep)

;;;; Insert Map (Ficticious)

(defvar-keymap mipc-insert-map :repeat t :doc "Keymap for insertion commands.")
(keymap-set global-map "H-i" mipc-insert-map)

(keymap-set mipc-insert-map "H-s" "¯ \\ _ ( ツ ) _ / ¯")
(keymap-set mipc-insert-map "s"   "¯ \\ _ ( ツ ) _ / ¯")

(dolist (elt `(("z" . ,(char-to-string (char-from-name "ZERO WIDTH SPACE")))
               ("#" . "█")
               ("," . "‚")
               ("1" . "Ʈ")))
  (keymap-set key-translation-map (concat "H-i H-" (car elt)) (cdr elt))
  (keymap-set key-translation-map (concat "H-i "   (car elt)) (cdr elt)))

;;;; List Map
(defvar-keymap mipc-list-map :doc "Keymap for commands that list things.")
(keymap-set global-map "H-l" mipc-list-map)

(keymap-set mipc-list-map "H-d" #'dired)
(keymap-set mipc-list-map "d"   #'dired)

(keymap-set mipc-list-map "H-p" #'proced)
(keymap-set mipc-list-map "p"   #'proced)

(keymap-set mipc-list-map "H-P" #'list-processes)
(keymap-set mipc-list-map "P"   #'list-processes)

(keymap-set mipc-list-map "H-e" #'list-packages)
(keymap-set mipc-list-map "e"   #'list-packages)

(keymap-set mipc-list-map "H-b" #'ibuffer)
(keymap-set mipc-list-map "b"   #'ibuffer)

(keymap-set mipc-list-map "H-m" #'bookmark-bmenu-list)
(keymap-set mipc-list-map "m"   #'bookmark-bmenu-list)

(keymap-set mipc-list-map "H-r" #'list-registers)
(keymap-set mipc-list-map "r"   #'list-registers)

(keymap-set mipc-list-map "H-t" #'list-tags)
(keymap-set mipc-list-map "t"   #'list-tags)

(keymap-set mipc-list-map "H-u" #'url-cookie-list)
(keymap-set mipc-list-map "u"   #'url-cookie-list)

;;;; Miscellaneous Map

(defvar-keymap mipc-misc-map :doc "Keymap for miscellaneous commands.")
(keymap-set global-map "H-x" mipc-misc-map)

(when (assoc-default 'xdg-open mipc-ext-deps #'eq t)
  (keymap-set mipc-misc-map "H-w H-t" #'mipc-wiktionary-dwim)
  (keymap-set mipc-misc-map "w t"     #'mipc-wiktionary-dwim)

  (keymap-set mipc-misc-map "H-w H-p" #'mipc-wikipedia-dwim)
  (keymap-set mipc-misc-map "w p"     #'mipc-wikipedia-dwim))

(keymap-set mipc-misc-map "H-m" #'mipc-copy-messages)
(keymap-set mipc-misc-map "m"   #'mipc-copy-messages)

;;; Global Mode / Package Configuration

;; That is, configuration for global minor modes, global configuration for
;; /local/ minor modes, global configuration for heavily-derived major modes
;; (y'know, like special-mode or comint-mode), and configuration for packages
;; that don't provide any modes.

;;;; `advice-patch'

(use-package advice-patch :defer t :ensure t)

;;;; `align' (built-in)

(use-package align
  :defer t
  :bind
  (:map mipc-misc-map
        ("H-a" . align-regexp)
        ("a" . align-regexp)))

;;;; `auto-revert-mode' (built-in)

;; Globally automatically revert any buffer associated with a file when that
;; file changes on disk.

(use-package autorevert :custom (global-auto-revert-mode t))

;;;; `bookmark' (built-in)

(use-package bookmark
  :defer t
  :custom
  (bookmark-save-flag 1)
  (bookmark-use-annotations t))

;;;; `column-number-mode' (built-in)

;; Display column number in the mode line, next to the line number. Looks like
;; this: (1245,15)

(use-package simple :custom (column-number-mode t))

;;;; `company-mode'

;; Completion.

(use-package company
  :ensure t
  :custom (company-idle-delay 0.1)      ; how long to wait until popup
  :bind (:map mipc-toggle-map
              ("H-c" . company-mode)
              ("c" . company-mode)))

;;;; `compilation-mode' (built-in)
(use-package compile
  :defer t
  :bind (("H-c" . compile)))

;;;; `conf-mode' (built-in)

(defconst mipc-equals-header-regexp
  (rx (not "=")                         ; no leading =s
      (group-n 1
        (group-n 2 (>= 2 "="))          ; some # of =s
        " "
        (minimal-match (one-or-more (any upper digit punct ?\s)))
        " "
        (backref 2))                    ; same # of =s as the left side
      (not "="))                        ; and no more
  "Match strings of uppercase letters surrounded by balanced \"=\" signs.

Actual match is contained within capture group 1.")

(require 'cl-macs)

(defun mipc-comment-header-p (bound)
  "Comment header matcher for `font-lock-keywords'.

Returns non-nil and updates `match-data' if it matches, as prescribed by
font-lock-keywords."
  (let ((case-fold-search nil))
    (cl-loop while (re-search-forward mipc-equals-header-regexp bound t)
             ;; See `parse-partial-sexp' value 4. Non-nil if in comment.
             if (save-excursion (nth 4 (syntax-ppss (match-beginning 1))))
             return t)))

(defun mipc-conf-mode-font-lock-add-keywords ()
  (font-lock-add-keywords nil
                          '((mipc-comment-header-p
                             1
                             '(:weight bold :foreground "#60afef")
                             prepend))))

(use-package conf-mode
  :defer t
  :hook ((conf-mode . mipc-conf-mode-font-lock-add-keywords)))

;;;; `display-fill-column-indicator' (built-in)

;; Displays a visual indication of where the fill column is. We're gonna enable
;; it for modes where we write a lot besides prose text.

(use-package display-fill-column-indicator
  :defer t
  :hook
  ((conf-mode
    prog-mode
    ;; Derives from `text-mode' instead of either of the previous two, for
    ;; whatever reason.
    gitattributes-mode
    rec-edit-mode)
   .
   display-fill-column-indicator-mode))

;;;; `display-line-numbers-mode' (built-in)

;; Enable line numbers (just the usual style) in modes where it makes sense.

(defvar mipc-display-line-numbers-exempt-modes
  '(comint-mode
    compilation-mode
    doc-view-mode
    dun-mode
    image-mode
    magit-status-mode
    special-mode
    speedbar-mode
    term-mode
    tetris-mode
    vterm-mode)
  "List of major modes to exempt from `global-display-line-numbers-mode'.

Each entry is either a major mode, or a cons pair of the form (MODE .
CHILDREN-P). A major mode by itself is equivalent to (MODE . t)

If CHILDREN-P is non-nil, then any modes derived from the given major
mode will also be exempted from global-display-line-numbers-mode. For
example, if we specify `comint-mode', then `shell-mode' will be implied,
as it is derived from the latter. A list of a given mode's parents can
be found with the function `derived-mode-all-parents'.")

(defun mipc-display-line-numbers-unless-exempt (original-fun &rest args)
  "Advice for `display-line-numbers--turn-on'.

Turn on line numbers unless the current major-mode (or one of its
parents) is listed in `mipc-display-line-numbers-exempt-modes'."
  (if (not
       (or (memq major-mode
                 (mapcar (lambda (m) (if (consp m) (car m) m))
                         mipc-display-line-numbers-exempt-modes))
           (derived-mode-p
            (seq-mapcat (lambda (m)
                          (if (consp m) (when (cdr m) (list (car m))) (list m)))
                        mipc-display-line-numbers-exempt-modes))
           (minibufferp)))
      (apply original-fun args)))

(use-package display-line-numbers
  :custom (global-display-line-numbers-mode t)
  :config
  (advice-add
   #'display-line-numbers--turn-on
   :around #'mipc-display-line-numbers-unless-exempt))

;;;; `edit-indirect'

(use-package edit-indirect
  :ensure t
  :bind
  (:map mipc-misc-map
        ("H-e H-r" . edit-indirect-region)
        ("e r" . edit-indirect-region)))

;;;; `editorconfig-mode'

(use-package editorconfig :custom (editorconfig-mode t))

;;;; The `electric-*-mode's (built-in)

(use-package elec-pair
  :defer t
  :custom
  (electric-pair-mode t)
  (electric-pair-open-newline-between-pairs nil)
  :bind
  (:map mipc-toggle-map
        ("H-e H-p" . electric-pair-mode)
        ("e p" . electric-pair-mode)))

(use-package electric
  :defer t
  :bind
  (:map mipc-toggle-map
        ("H-e H-i" . electric-indent-mode)
        ("e i" . electric-indent-mode)
        ("H-e H-l" . electric-layout-mode)
        ("e l" . electric-layout-mode)))

;;;; `files' (built-in)

;; Low-level file saving and loading stuff. I want trailing newlines but NO
;; other trailing whitespace.

(defvar mipc-whitespace-cleanup-exempt-modes '()
  "Major modes to exempt from `mipc-whitespace-cleanup'.

Modes which are derived (parented by) from listed modes will also be
exempted. For example, if we specify `comint-mode', then `shell-mode'
will be implied, as it is derived from the latter. A list of a given
mode's parents can be found with the function
`derived-mode-all-parents'.")

(defun mipc-whitespace-cleanup-unless-exempt ()
  "Wrapper around `whitespace-cleanup'.

Delete trailing whitespace unless the current major-mode is a member of,
or is derived from a member of, `mipc-whitespace-cleanup-exempt-modes'."
  (interactive)
  (if (not
       (or (memq major-mode mipc-whitespace-cleanup-exempt-modes)
           (derived-mode-p mipc-whitespace-cleanup-exempt-modes)
           (minibufferp)))
      (whitespace-cleanup)))

(use-package files
  :custom (require-final-newline t)
  :bind (:map mipc-misc-map
         ("H-f H-s" . find-sibling-file)
         ("f s" . find-sibling-file))
  :hook (before-save . mipc-whitespace-cleanup-unless-exempt))

;;;; `flycheck-mode'

;; Automatic syntax checking.

(use-package flycheck :ensure t :defer t)

;;;; `flyspell-mode' (built-in)

;; Automatic spell-checking. We'll just let it default to whatever backend it
;; wants, 'cause I'm lazy.

;; Oh, and turn it on for comments and strings in programming modes, too!

(use-package flyspell
  :defer t
  :hook
  (((prog-mode conf-mode) . flyspell-prog-mode)
   (text-mode . flyspell-mode)))

;;;; `frameshot-mode'

;; Screenshots!

(use-package frameshot :ensure t :defer t)

;;;; `font-lock-mode'

(setq redisplay-skip-fontification-on-input t)

;;;; `hl-todo-mode'

;; Highlight keywords like TODO and FAIL and FIXME and HACK and so forth.
;; Enabling globally enables for prog- and text-mode (besides org) derived major
;; modes.

(use-package hl-todo
  :ensure t
  :custom
  (global-hl-todo-mode t)
  (hl-todo-keyword-faces                 ; default definitions + a few of my own
   '(("HOLD"       . "#d0bf8f")
     ("TODO"       . "#cc9393")
     ;; ("NEXT"       . "#dca3a3")
     ("THEM"       . "#dc8cc3")
     ;; ("PROG"       . "#7cb8bb")
     ("OKAY"       . "#7cb8bb")
     ("DONT"       . "#5f7f5f")
     ("FAIL"       . "#8c5353")
     ("DONE"       . "#afd8af")
     ("NOTE"       . "#d0bf8f")
     ("MAYBE"      . "#d0bf8f")
     ("KLUDGE"     . "#d0bf8f")
     ("HACK"       . "#d0bf8f")
     ("TEMP"       . "#d0bf8f")
     ("FIXME"      . "#cc9393")
     ("XXXX*"      . "#cc9393")
     ;; my own additions begin here
     ("INREQ"      . "#9beeef")
     ("NEEDS? INFO" . "#9beeef")
     ("REQUIRES"   . "#9eef00")
     ("PROVENANCE" . "#9eef00")))
  (hl-todo-highlight-punctuation "!:"))

;;;; `hs-minor-mode' (built-in)

;; Hide and Show blocks within curly braces (or whatever a major mode defines).

;; More specifically: if you place the point inside something like this:
;; function foobar { # does something... }
;; and then you C-c @ C-c or S-<middle mouse>, it becomes this:
;; function foobar {...}
;; Just do it again to toggle back.

(use-package hideshow
  :defer t
  ;; :hook (prog-mode . hs-minor-mode)
  :bind
  (:map mipc-toggle-map
        ("H-h" . hs-minor-mode)
        ("h"   . hs-minor-mode)))

;;;; `ibuffer-mode' (built-in)

;; `list-buffers' but strictly more powerful.

(use-package ibuffer :defer t :bind ("C-x C-b" . ibuffer))

;;;; `icomplete-mode' (built-in)

;; Automatic completion of things in the minibuffer.

(use-package icomplete :defer t :custom (icomplete-mode t))

;;;; `indent-tabs-mode' (built-in)

(use-package simple :defer t :custom (indent-tabs-mode nil))

;;;; `inheritenv'

;; Allows background processes to inherit environment variables from their
;; calling buffers.

(use-package inheritenv :ensure t :defer t)

;;;; kill ring

(setq kill-do-not-save-duplicates t)

;;;;; `kill-ring-deindent-mode'

;; Exactly what it sounds like. De-indent the kill ring.

(use-package indent-aux
  :custom (kill-ring-deindent-mode t)
  :bind
  (:map mipc-toggle-map
        ("H-k H-d" . kill-ring-deindent-mode)
        ("k d" . kill-ring-deindent-mode)))

;;;; `lsp-mode'

;; The other Language Server Protocol implementation for Emacs. Arguably the
;; better one.

;; I really don't like it when automatic punctuation matching is on all the
;; time, so I've disabled this LSP "feature".

(setq read-process-output-max (* 4 1024 1024))

(when mipc-use-lsp
  (use-package lsp-mode
    :ensure t
    :defer t
    :custom (lsp-enable-on-type-formatting nil)
    :config
    (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]fetched\\'")))

(when mipc-use-lsp (use-package lsp-ui :ensure t :after lsp-mode))

;;;; `mipc-ff-hline-mode'

(require 'mipc-ff-hline)

;;;; `misc' (built-in)

(use-package misc
  :defer t
  :custom (duplicate-line-final-position -1)
  :bind (("H-d" . duplicate-dwim)))

;;;; `menu-bar-mode' (built-in)

;; I don't hate the menu bar. /But/ I do want an easy-to-remember way to turn it
;; off.

(use-package menu-bar
  :defer t
  :custom (menu-bar-mode nil)
  :bind
  (:map mipc-toggle-map
        ("H-m H-b" . menu-bar-mode)
        ("m b"     . menu-bar-mode)))

;;;; `outline-minor-mode' (built-in)

;; That which spawned our savior org-mode, useful in its own right for
;; headline-izing Elisp code. Let's turn on backtab cycling!

(use-package outline :defer t :custom (outline-minor-mode-cycle t))

;;;; `prog-mode' (built-in)

;; Highlight markdown-style equals sign headers in comments, just like
;; we did in `conf-mode'.

(defun mipc-prog-mode-font-lock-add-keywords ()
  (font-lock-add-keywords nil
                          '((mipc-comment-header-p
                             1
                             '(:weight bold :foreground "#60afef")
                             prepend))))

(use-package prog-mode
  :defer t
  :hook ((prog-mode . mipc-prog-mode-font-lock-add-keywords)))

;;;; `project' (built-in)

;; I like Emacs' new lightweight project system. I don't fully understand it,
;; but I like it.

(use-package project
  :defer t
  :custom
  (project-mode-line t)
  (project-buffers-viewer #'project-list-buffers-ibuffer))

;;;; `rainbow-delimiters'

(use-package rainbow-delimiters :ensure t :defer t :hook prog-mode)

;;;; `rainbow-mode'

;; Colorize RGB hex strings like #b51a43 or #667a76 with that color as the
;; background face.

;; For whatever reason, this package does not obey the typical minor-mode
;; conventions. You can't toggle it off with numeric arguments, for example.
;; PITA! One day I'll wrap or fork it.

(use-package rainbow-mode :ensure t :defer t)

;;;; `savehist-mode' (built-in)

;; Saves your minibuffer history. `recentf-mode' always gave me headaches, but
;; this is great!

(use-package savehist :custom (savehist-mode t))

;;;; `scroll-bar-mode' (built-in)

(use-package scroll-bar :custom (scroll-bar-mode nil))

;;;; `subword-mode' (built-in)

;; Treat CamelCase strings as multiple words for the purpose of `forward-word',
;; and `backward-word' etc.

(use-package subword :custom (global-subword-mode t))

;;;; `tab-bar-mode' (built-in)

;; Tabs!

(use-package tab-bar
  :defer t
  :custom (tab-bar-new-tab-to 'rightmost)
  :bind
  (:map mipc-toggle-map
        ("H-t H-b" . tab-bar-mode)
        ("t b"     . tab-bar-mode)))

(use-package project :defer t :bind ("C-x t p" . tab-bar-switch-to-prev-tab))

;;;; `text-scale-mode' (built-in)

;; Not the best for scaling text, but not the worst.

(use-package face-remap :custom (global-text-scale-adjust-resizes-frames t))

;;;; `titlecase'

;; I'm sick of doing `capitalize-region' and then manually adjusting. This is,
;; as it's author states, a best-effort attempt to do it right. It hasn't given
;; me any problems, so I appreciate that.

(use-package titlecase
  :vc (:url "https://codeberg.org/acdw/titlecase.el.git"
       :rev :newest)
  :ensure t
  :custom
  ;; Wikipedia-style is actually already the default, but I respect it enough
  ;; that I want to explicitly agree.
  ((titlecase-style 'wikipedia)
   (titlecase-downcase-sentences t))
  :bind
  (:map mipc-misc-map
        ("H-t" . titlecase-dwim)
        ("t"   . titlecase-dwim)))

;;;; `tool-bar-mode' (built-in)

(use-package tool-bar :custom (tool-bar-mode nil))

;;;; `tramp-rpc'

;; TODO: pull from ELPA instead of VC once it becomes available

(use-package tramp-rpc
  :vc (:url "https://github.com/ArthurHeymans/emacs-tramp-rpc"
       :rev :newest
       :lisp-dir "lisp")
  :ensure t
  :after tramp)

;;;; `vlf-mode'

;; Specialized mode for opening Very Large Files. Works... okay.

(use-package vlf :ensure t :config (require 'vlf-setup))

;;;; `wgrep-mode'

(use-package wgrep :ensure t :defer t)

;;;; `yas-minor-mode'

;; Snippets. We want them in the minibuffer, and we want them now!

(use-package yasnippet
  :ensure t
  :custom
  (yas-global-mode t)
  (yas-snippet-dirs (list (expand-file-name "3rdparty/snippets" mipc-data-dir)
                          (expand-file-name "snippets" mipc-data-dir)))
  :hook (minibuffer-setup . yas-minor-mode)

  ;; We have to do our keybinding here because `use-package' won't unquote
  ;; `yas-maybe-expand'.
  :config
  ;; (advice-patch #'yas--parse-template
  ;;             '((or "contributor" "SPDX-License-Identifier") nil)
  ;;             '("contributor" nil))
  (require 'mipc-snippet-ccstd)
  (keymap-set minibuffer-local-map "<tab>" yas-maybe-expand)
  (add-to-list 'mipc-whitespace-cleanup-exempt-modes 'snippet-mode))

;; (use-package yasnippet-snippets
;;   :ensure t
;;   :after yasnippet)

;;; Topic-Wide Major and Minor Mode Configuration

;;;; Ada

;; The Ada programming language. I usually prefer `lsp-mode' over `eglot', but
;; I'm not touching this until I remember what these settings mean.

(when mipc-use-lsp
  (use-package ada-mode
    :ensure t
    :custom
    (ada-indent-backend 'eglot)
    (ada-statement-backend 'eglot)))

;;;; Assembly

;; Always use `nasm-mode' over `asm-mode' on x86. Not touching gas with a
;; ten-meter pole...

(when (eq mipc-default-assembly-language 'x86)
  (use-package nasm-mode :ensure t :defer t)
  (add-to-list 'major-mode-remap-alist '(asm-mode . nasm-mode)))

;;;; BASIC

(use-package basic-mode :ensure t :defer t)

;;;; C/C++

(when (assoc-default 'tree-sitter mipc-ext-deps #'eq t)
  (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode))
  (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode))
  (add-to-list 'major-mode-remap-alist '(c-or-c++-mode . c-or-c++-ts-mode))

  (use-package treesit
    :defer t
    :config
    (add-to-list 'treesit-language-source-alist
                 '(c "https://github.com/tree-sitter/tree-sitter-c"))
    (add-to-list 'treesit-language-source-alist
                 '(cpp "https://github.com/tree-sitter/tree-sitter-cpp"))
    (unless (treesit-language-available-p 'c)
      (treesit-install-language-grammar 'c))
    (unless (treesit-language-available-p 'cpp)
      (treesit-install-language-grammar 'cpp)))

  (use-package c-ts-mode
    :defer t
    :after mipc-c-ts
    :custom
    (c-ts-mode-indent-offset 4)
    (c-ts-mode-indent-style #'mipc-c-ts-indent-style))

  (use-package mipc-c-ts
    :defer t
    :hook ((c-ts-mode . mipc-c-ts-extra-font-lock-rules)
           (c-ts-mode . mipc-c-ts-adjust-syntax-table))))

;; (when (assoc-default 'clang mipc-ext-deps #'eq t)
;;   (use-package company-clang
;;     :defer t
;;     :custom
;;     (company-clang-arguments '("-std=c23"))))

;; (when (and mipc-use-lsp (assoc-default 'clang mipc-ext-deps #'eq t))
;;   (use-package lsp-clangd
;;     :defer t
;;     :custom
;;     (lsp-clients-clangd-args '("--header-insertion-decorators=0"))))

(use-package files
  :defer t
  :config
  (dolist (rule `((,(rx (group-n 1 (+ (not ?/))) ".c" eos) "\\1.h")
                  (,(rx (group-n 1 (+ (not ?/))) ".h" eos) "\\1.c")))
    (add-to-list 'find-sibling-rules rule)))

;;;; CSV / TSV

(use-package csv-mode
  :ensure t
  :custom (csv-align-padding 4)
  :config (add-to-list 'mipc-whitespace-cleanup-exempt-modes 'tsv-mode))

;;;; CUDA

;; We'll just inherit from our `cc-mode' settings.

(use-package cuda-mode :ensure t :defer t)

;;;; Diffs

(use-package diff-mode
  :defer t
  :config (add-to-list 'mipc-whitespace-cleanup-exempt-modes 'diff-mode))

;;;; Dired / Filesystem More Generally

;; TODO: figure out how to add advice to dired-omit where it won't toggle on if
;; a buffer doesn't contains any files (files, not directories) that would be
;; visible.

(when (assoc-default 'ls mipc-ext-deps #'eq t)
  (use-package dired
    :defer t
    :custom
    (dired-use-ls-dired t)
    (dired-maybe-use-globstar t)
    (dired-vc-rename-file t)
    (dired-listing-switches
     (string-join
      '("-l"          ; long output format, required
        "--all"       ; duh
        "--si"        ; same as ~--human-readable~, but powers of 10 not 2
        "--classify") ; "append indicator (one of */=>@|) to entries"
      " "))
    :config
    (add-to-list 'mipc-display-line-numbers-exempt-modes 'dired-mode)
    (add-to-list 'mipc-display-line-numbers-exempt-modes 'wdired-mode))

  (use-package dired-x :after dired :hook (dired-mode . dired-extra-startup)))

(use-package speedbar
  :defer t
  :bind
  (:map mipc-toggle-map
        ("H-s H-b" . speedbar)
        ("s b" . speedbar)))

;;;; Emacs Lisp

;; Turn on outlines for Elisp.

(use-package outline :hook (emacs-lisp-mode . outline-minor-mode))

;; (use-package elisp-autofmt
;;   :ensure t
;;   :defer t
;;   :hook emacs-lisp-mode)

;;;; Eshell

(use-package eshell
  :defer t
  :init (require 'mipc-eshell)
  :custom
  (eshell-prompt-function #'mipc-eshell-prompt-function)
  (eshell-aliases-file (expand-file-name "eshell/alias" mipc-data-dir))
  :config
  (add-to-list 'mipc-display-line-numbers-exempt-modes 'eshell-mode))

(use-package esh-mode
  :defer t
  :config
  (keymap-set eshell-mode-map "<tab>" yas-maybe-expand))

;;;; git

;; Gotta love `magit'. Let's pull in git-modes too, to give us some major-modes
;; for .gitattributes and .gitignore and so forth.

(use-package git-modes :ensure t :defer t)

(when (assoc-default 'git mipc-ext-deps #'eq t)
  (use-package magit
    :ensure t
    :defer t
    :bind
    (:map mipc-toggle-map
          ("H-g" . magit-status)
          ("g" . magit-status))
    :config
    (dolist (command '(magit-diff-edit-hunk-commit magit-edit-line-commit))
      (put command 'disabled nil))))

;;;; GLSL

(use-package glsl-mode :ensure t :defer t :mode ("\\.vsh\\'" "\\.fsh\\'"))

;;;; Gopher

;; (As in the application protocol.)

(use-package elpher :ensure t :defer t)

;;;; gnuplot

;; There's a gnuplot package and a gnuplot-mode package, I'm not sure what the
;; difference is. This one seems reasonable?

(use-package gnuplot :ensure t :defer t)

;;;; Java

;; Java is not a language I want to write without a language server.

(when (and mipc-use-lsp
           (assoc-default 'eclipse-jdt-ls mipc-ext-deps #'eq t)
           (assoc-default 'jdks           mipc-ext-deps #'eq t))
  (use-package lsp-java
    :ensure t
    :after lsp-mode
    :custom
    (lsp-java-vmargs
     '("-XX:+UseParallelGC"
       "-XX:GCTimeRatio=4"
       "-XX:AdaptiveSizePolicyWeight=90"
       "-Dsun.zip.disableMemoryMapping=true"
       "-Xmx2G"                         ; locks up _really_ easily without this
       "-Xms100m"))
    (lsp-java-configuration-runtimes
     (assoc-default 'jdks mipc-ext-deps #'eq nil)))

  (use-package lsp-mode :ensure t :defer t :hook java-mode))

;;;; JSON

(use-package js
  :defer t
  :mode ("\\.mcmeta\\'" . js-json-mode)
  :custom (js-indent-level 2))

;;;; Kotlin

;; I may or may not set up LSP here too at some point. For now, all I want is
;; syntax highlighting.

(use-package kotlin-mode :ensure t :defer t)

;;;; LaTeX

(use-package auctex :ensure t)

(use-package reftex :hook LaTeX-mode)

;;;; Makefile

(use-package make-mode
  :defer t
  :mode ("/Makefile\\.include\\'" . makefile-gmake-mode))

;;;; Man / Help / Info / Other Documentation

;; Unless I choose otherwise, I want all documentation to share one window.

;; TODO:
;; 1. Make Man-mode behave how I want it to. Is 'thrifty really the right
;;    notification method?
;;
;; 2. Find out if I can leverage the category action argument to make this
;;    behave nicer. See (info "(elisp) Choosing Window")

(unbind-key "C-f" help-map)

(defun mipc-display-buffer-maybe-same-window-by-related-modes (buffer alist)
  "Conditionally display BUFFER in the selected window.

If the major-mode of the selected window is either equal to, or a member
of, the related-modes entry of the action alist, display BUFFER in the selected
window. Sort of like `display-buffer--maybe-same-window', but broader.

See (info \"(elisp) Buffer Display Action Alists\") for more about the
mode entry."
  (when-let* ((related-modes (alist-get 'related-modes alist)))
    (when (with-selected-window (selected-window)
            (memq major-mode related-modes))
      (display-buffer-same-window buffer alist))))

(defvar mipc-doc-buffer-modes
  '(help-mode apropos-mode finder-mode Man-mode Info-mode shortdoc-mode)
  "Major-modes we'll consider \"Documentation\".")

(defun mipc-doc-buffer-p (buffer-or-name &rest _args)
  "Return non-nil if BUFFER-NAME is a documentation buffer.
This checks `mipc-doc-buffer-modes'.

As a workaround for M-x man being weird, if `mipc-doc-buffer-modes'
contains `Man-mode', any buffer in `fundamental-mode' whose name starts
with \"*Man\" will also be matched."
  (let ((name (if (stringp buffer-or-name)
                  buffer-or-name
                (buffer-name buffer-or-name))))
    (unless (when (bufferp buffer-or-name) (minibufferp buffer-or-name))
      (with-current-buffer buffer-or-name
        (or (memq major-mode mipc-doc-buffer-modes)
            (and (eq major-mode 'fundamental-mode)
                 (string-prefix-p "*Man" name)
                 (memq 'Man-mode mipc-doc-buffer-modes)))))))

(add-to-list
 'display-buffer-alist
 `(;; (or . ,(mapcar (lambda (m) (cons 'derived-mode m)) mipc-doc-buffer-modes))
   mipc-doc-buffer-p
   .
   ((display-buffer--maybe-same-window
     mipc-display-buffer-maybe-same-window-by-related-modes
     display-buffer-reuse-window
     display-buffer-reuse-mode-window
     display-buffer--maybe-pop-up-frame-or-window
     display-buffer-in-previous-window
     display-buffer-use-some-window
     display-buffer-pop-up-frame)
    .
    ((related-modes   . ,mipc-doc-buffer-modes)
     (reusable-frames . visible)))))

(use-package help-mode
  :defer t
  :custom
  (describe-bindings-show-prefix-commands t)
  (help-enable-symbol-autoload t)
  (help-window-keep-selected t)
  (help-window-select t))

(use-package find-func
  :defer t
  :custom (find-function-C-source-directory
           (let ((path (expand-file-name "~/.local/src/emacs/src/")))
             (when (file-exists-p path) path))))

(defvar-keymap mipc-apropos-map
  :doc "Keymap for apropos subcommands."
  "a"   #'apropos
  "l"   #'apropos-library
  "f"   #'apropos-function
  "x"   #'apropos-command
  "v"   #'apropos-variable
  "V"   #'apropos-local-variable
  "u"   #'apropos-user-option
  "d"   #'apropos-documentation
  "C-f" #'customize-apropos-faces
  "g"   #'customize-apropos-groups
  "o"   #'customize-apropos-options
  "c"   #'customize-apropos
  "i"   #'info-apropos)
(keymap-set help-map "a" mipc-apropos-map)

(use-package man
  :defer t
  :custom (Man-notify-method 'thrifty)
  :bind ("C-h M" . man))

;;;; Org

;; Good 'ol `org-mode'. Here's what I think are some reasonable defaults, plus
;; some extension packages I wrote.

(defconst mipc-oxhtml-cleanup-stylesheet
  (expand-file-name "CSS/oxhtmlcleanup-extra-stylesheet.css"
                    mipc-data-dir))

(defconst mipc-oxhtml-cleanup-minified-stylesheet
  (expand-file-name "CSS/oxhtmlcleanup-extra-stylesheet-minified.css"
                    mipc-data-dir))

(defun mipc-get-oxhtml-stylesheet ()
  (let ((stylesheet-path mipc-oxhtml-cleanup-stylesheet)
        (minified-path mipc-oxhtml-cleanup-minified-stylesheet))
    (if (file-newer-than-file-p minified-path stylesheet-path)
        (with-temp-buffer
          (insert-file-contents minified-path)
          (buffer-substring-no-properties (point-min) (point-max)))
      (with-temp-buffer
        (insert-file-contents stylesheet-path)
        (when (assoc-default 'esbuild mipc-ext-deps #'eq t)
          (call-process-region (point-min) (point-max)
                               "esbuild"
                               t '(t nil) nil
                               "--color=false"
                               "--log-override:unsupported-@namespace=silent"
                               "--minify"
                               "--loader=css"))
        (goto-char (point-max))
        (while (= (char-before) ?\n) (delete-char -1))
        (goto-char (point-min))
        (insert "/* SPDX-License-Identifier: MPL-2.0 */\n")
        (let ((case-fold-search nil))
          (save-match-data
            (while (search-forward-regexp (rx "@namespace \"") nil t)
              (unless (nth 3 (save-excursion (goto-char (match-beginning 0))
                                             (syntax-ppss)))
                (replace-match "@namespace\"" t t)))))
        (write-region nil nil minified-path)
        (buffer-substring-no-properties (point-min) (point-max))))))

(use-package oxhtmlcleanup
  :custom
  (oxhtmlcleanup-tidy-args '("-language"                :language
                             "--mute-id"                "yes"
                             "--add-xml-decl"           "yes"
                             "--output-xhtml"           "yes"
                             "--char-encoding"          "utf8"
                             "--output-bom"             "no"
                             "--clean"                  "yes"
                             "--drop-empty-elements"    "yes"
                             "--drop-empty-paras"       "yes"
                             "--merge-divs"             "auto"
                             "--merge-spans"            "auto"
                             "--numeric-entities"       "yes"
                             "--fix-style-tags"         "yes"
                             "--fix-uri"                "yes"
                             "--lower-literals"         "yes"
                             "--repeated-attributes"    "keep-last"
                             "--strict-tags-attributes" "yes"
                             "--escape-cdata"           "no"
                             "--join-styles"            "yes"
                             "--merge-emphasis"         "yes"
                             "--replace-color"          "yes"
                             "--indent"                 "yes"
                             "--indent-with-tabs"       "no"
                             "--keep-tabs"              "no"
                             "--tidy-mark"              "yes"))
  (oxhtmlcleanup-tidy-message-warnings t)
  (oxhtmlcleanup-extra-stylesheet (mipc-get-oxhtml-stylesheet)))

(use-package org
  :ensure t
  :defer t
  :custom
  (org-agenda-files nil)
  (org-agenda-loop-over-headlines-in-active-region nil)
  ;; (org-cite-activate-processor 'basic)
  (org-cite-export-processors
   `((html csl ,(expand-file-name "3rdparty/ieee.csl" mipc-data-dir))
     (t basic)))
  ;; (org-cite-follow-processor 'basic)
  ;; (org-cite-insert-processor 'basic)
  (org-confirm-babel-evaluate nil)
  (org-descriptive-links nil)
  (org-entities-user '(("hash" "\\#" nil "#" "#" "#" "#")))
  (org-enforce-todo-dependencies t)
  (org-export-allow-bind-keywords t)
  (org-export-with-smart-quotes t)
  (org-html-doctype "xhtml5")
  (org-html-extension "xhtml")
  (org-html-html5-fancy t)
  (org-html-postamble t)
  (org-html-postamble-format '(("en" "<oxhtmlcleanup-postamble-here />")))
  (org-html-xml-declaration
   '(("xhtml" .
      "<?xml version=\"1.0\" encoding=\"%s\"?>")
     ("html" .
      "<?xml version=\"1.0\" encoding=\"%s\"?>")
     ("php" .
      "<?php echo \"<?xml version=\\\"1.0\\\" encoding=\\\"%s\\\" ?>\"; ?>")))
  (org-latex-default-packages-alist
   '(("AUTO" "inputenc" t ("pdflatex"))
     ("T1" "fontenc" t ("pdflatex"))
     ("" "graphicx" t nil)
     ("" "longtable" nil nil)
     ("" "wrapfig" nil nil)
     ("" "rotating" nil nil)
     ("normalem" "ulem" t nil)
     ("" "amsmath" t nil)
     ("" "amssymb" t nil)
     ("" "capt-of" nil nil)
     ("" "hyperref" nil nil)
     ("" "siunitx" nil nil)))
  (org-latex-hyperref-template
   "\\hypersetup{
 pdfauthor={%a},
 pdftitle={%t},
 pdfkeywords={%k},
 pdfsubject={%d},
 pdfcreator={%c},
 pdflang={%L},
 colorlinks = true,
 urlcolor = blue,
 linkcolor = blue,
 citecolor = red}
")
  (org-list-allow-alphabetical t)
  (org-startup-indented t)
  ;; Moved down here to prevent some weird loading dependency issues
  :config
  (add-to-list 'org-src-lang-modes '("json" . js-json))
  (add-to-list 'org-src-lang-modes '("JSON" . js-json))

  (when (eq mipc-default-assembly-language 'x86)
    (add-to-list 'org-babel-tangle-lang-exts '("nasm" . "s")))

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t) (C . t) (gnuplot . t) (shell . t) (latex . t)))

  (setq org-export-filter-final-output-functions
        (append
         (list #'oxhtmlcleanup-zwsp
               #'oxhtmlcleanup-dedup-ids
               #'oxhtmlcleanup-extra-style
               #'oxhtmlcleanup-details-toc
               #'oxhtmlcleanup-postamble)
         (when (assoc-default 'html-tidy mipc-ext-deps #'eq t)
           (list #'oxhtmlcleanup-tidy))
         (list #'oxhtmlcleanup-foreign-lang)))

  (setq org-export-filter-example-block-functions
        '(oxhtmlcleanup-trim-examples)))

(use-package citeproc :ensure t)

(use-package ol-tel :after org-mode)

;; (use-package org-contrib :ensure t :after org-mode)

(use-package org-present :ensure t :after org-mode)

;;;; PDF / EPUB / ODF / Documents

;; TODO: Look into this package ↓

;; (when (assoc-default 'mupdf mipc-ext-deps #'eq t)
;;   (use-package reader
;;     :vc (:url "https://codeberg.org/MonadicSheep/emacs-reader"
;;          :make "all")
;;     :ensure t
;;     :defer t))

;;;; PHP

;; I don't like PHP whatsoever, but I'd rather have the mode than lack it.

;; (use-package php-mode :ensure t :defer t)

;;;; Python

;; All we need is to avoid clobbering our whitespace.

(use-package python
  :defer t
  :config (add-to-list 'mipc-whitespace-cleanup-exempt-modes 'python-mode))

;;;; Racket

(use-package racket-mode :ensure t :defer t :mode "\\.rkt\\'")
(use-package scribble :load-path mipc-3rdparty-lisp-dir :defer t)

(use-package geiser :ensure t :defer t :hook (racket-mode . geiser-mode))
(use-package geiser-racket
  :ensure t
  :defer t
  :config
  (setq auto-mode-alist (delete '("\\.rkt\\'" . scheme-mode) auto-mode-alist)))

;; `geiser-racket' and `racket-mode' have conflicting autoloads which add rkt to
;; `auto-mode-alist'. I would prefer to use the dedicated mode and not
;; `scheme-mode', thank you.
(add-hook 'after-init-hook
          (lambda ()
            (setq auto-mode-alist
                  (delete '("\\.rkt\\'" . scheme-mode) auto-mode-alist))))

;;;; Raku

;; I don't much like Raku either

;; (use-package raku-mode :ensure t :defer t :custom (raku-indent-offset 8))

;;;; Rust

;; Oh baby gimmie that LSP functionality.

(use-package rust-mode
  :ensure t
  :defer t
  :custom (rust-rustfmt-switches '("--edition" "2024")))

(when (and mipc-use-lsp (assoc-default 'rust-analyzer mipc-ext-deps #'eq t))

  (use-package rustic
    :ensure t
    :after (lsp-mode rust-mode)
    :custom
    (rustic-compile-backtrace "1")
    (rustic-rustfmt-config-alist '(("edition" . "2024")))
    :config (add-to-list 'compilation-environment "RUST_BACKTRACE=1"))

  (use-package lsp-mode
    :ensure t
    :defer t
    :custom (lsp-rust-analyzer-diagnostics-disabled ["inactive-code"])))

;;;; rec

;; Simple flat file database format

(defun mipc-rec-edit-field-inherit-fill-column ()
  (setq-local fill-column (with-current-buffer rec-prev-buffer fill-column)))

(use-package rec-mode
  :ensure t
  :defer t
  :hook (rec-edit-field-mode . mipc-rec-edit-field-inherit-fill-column)
  :config
  (add-to-list 'mipc-display-line-numbers-exempt-modes '(rec-mode)))

;;;; SGML

(use-package display-fill-column-indicator :hook sgml-mode)

;; (use-package psgml
;;   :ensure t
;;   :custom
;;   (sgml-set-face t)
;;   (sgml-auto-activate-dtd nil))

;;;; Shell

;; TODO: Lots to improve here, haven't gotten around to any of it.

(when (assoc-default 'bash mipc-ext-deps #'eq t)
  (use-package shell
    :defer t
    :custom (explicit-shell-file-name "/usr/bin/bash")))

(when (assoc-default 'libvterm mipc-ext-deps #'eq t)
  (use-package vterm :ensure t :defer t))

(use-package comint
  :defer t
  :config
  (add-to-list 'comint-output-filter-functions #'comint-osc-process-output))

;;;; Shell Scripts

(use-package executable
  :demand t
  :hook (after-save . executable-make-buffer-file-executable-if-script-p))

;;;; Slint

;; I have no need to write slint macros in-line, so we'll just leave it for
;; slint source files only.

;; Oh, and we'll turn on LSP + rainbow modes.

;; TODO: Hook and binding for the slint LSP's format-file functionality.

(use-package slint-mode :defer t :ensure t)

(when (and mipc-use-lsp
           (assoc-default 'slint-lsp mipc-ext-deps #'eq t))
  (use-package lsp-mode :ensure t :defer t :hook slint-mode))

;; (use-package rainbow-mode
;;   :ensure t
;;   :defer t
;;   :hook (slint-mode . (lambda () (unless rainbow-mode (rainbow-mode)))))

;;;; Web (HTML/XHTML, CSS, ECMAScript/JavaScript)

;; HTMLize is a neat package that "renders" an HTML buffer in-Emacs.

(use-package htmlize :ensure t :demand t)

(use-package eww
  :defer t
  :custom (eww-bookmarks-directory (expand-file-name "eww/" mipc-data-dir)))

;; Always close tags
(use-package sgml-mode :defer t :custom (sgml-xml-mode t))

(when (assoc-default 'tree-sitter mipc-ext-deps #'eq t)
  (add-to-list 'major-mode-remap-alist '(css-mode . css-ts-mode))
  (use-package treesit
    :defer t
    :config
    (add-to-list 'treesit-language-source-alist
                 '(css "https://github.com/tree-sitter/tree-sitter-css"))
    (unless (treesit-language-available-p 'css)
      (treesit-install-language-grammar 'css))))

;;;; YAML

;; Friggin' YAML. Well, we want a major mode and we don't want any significant
;; whitespace getting merked.

(use-package yaml-mode
  :ensure t
  :defer t
  :config (add-to-list 'mipc-whitespace-cleanup-exempt-modes 'yaml-mode))

;;;; Other

;; ...

;;;;; Multiple Major Modes

;; TODO: I intend to one day use this to allow me to explicitly use org-mode in
;; program comments. I have yet to do so.

;; (use-package mmm-mode :ensure t)

;;; Finally...

;;;; Automatically generate aliases for commands prefixed mipc-

;; TODO: replace this with a custom wrapper around `defun' like
;; `def-mipc-command'.

(mapatoms
 (lambda (sym)
   (when-let*
       ((cmd-name (and (commandp sym) (symbol-name sym)))
        (alias    (and (string-prefix-p mipc-sym-prefix cmd-name)
                       (intern (substring cmd-name (length mipc-sym-prefix))))))
     (unless (fboundp alias) (defalias alias sym)))))

;;; init.el ends here
