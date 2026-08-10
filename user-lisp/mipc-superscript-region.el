;;; mipc-superscript-region.el --- superscript and subscript region functions -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;;; Code:

(defconst mipc-superscript--monographs
  (concat
   "²³¹ʰʱʲʳʴʵʶʷʸˠˡˢˣˤჼᴬᴭᴮᴰᴱᴲᴳᴴᴵᴶᴷᴸᴹᴺᴼᴽᴾᴿᵀᵁᵂᵃᵄᵅᵆᵇᵈᵉᵊᵋᵍᵏᵐᵑᵒᵓᵔᵕᵖᵗᵘᵙᵚᵛᵜᵝᵞᵟᵠᵡᵸᶛᶜᶝᶞᶟᶠ"
   "ᶡᶢᶣᶤᶥᶦᶧᶨᶩᶪᶫᶬᶭᶮᶯᶰᶱᶲᶳᶴᶵᶶᶷᶸᶹᶺᶻᶼᶽᶾᶿ⁰ⁱ⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿⱽⵯ㆒㆓㆔㆕㆖㆗㆘㆙㆚㆛㆜㆝㆞㆟"
   "ꚜꚝꝰꟲꟳꟴꟸꟹꭜꭝꭞꭟꭩ𐞁𐞂𐞃𐞄𐞅𐞇𐞈𐞉𐞊𐞋𐞌𐞍𐞎𐞏𐞐𐞑𐞒𐞓𐞔𐞕𐞖𐞗𐞘𐞙𐞚𐞛𐞜𐞝𐞞𐞟𐞠𐞡𐞢𐞣𐞤𐞥𐞦𐞧𐞨𐞩𐞪𐞫𐞬𐞭𐞮𐞯𐞰𐞲𐞳𐞴𐞵𐞶𐞷𐞸𐞹𐞺𞀰𞀱𞀲𞀳𞀴𞀵𞀶"
   "𞀷𞀸𞀹𞀺𞀻𞀼𞀽𞀾𞀿𞁀𞁁𞁂𞁃𞁄𞁅𞁆𞁇𞁈𞁉𞁊𞁋𞁌𞁍𞁎𞁏𞁐𞁫𞁬𞁭")
  "List of superscript characters which decompose to a single glyph.

Found via:

(seq-into
 (cl-loop for i from 0 upto #x10FFFF
          if (let ((decomp (get-char-code-property i \='decomposition)))
               (and (seq-contains-p decomp \='super #\='eq)
                    (length= decomp 2)))
          collect i)
 \='string)

and checked for duplicates with

(let ((ht (make-hash-table :test #\='equal)))
  (cl-labels ((f (c decomp)
                (format \"U+%04X %s %S\"
                        c (get-char-code-property c \='name) decomp))
              (g (c)
                (let* ((decomp (get-char-code-property c \='decomposition))
                       (other (gethash decomp ht)))
                  (cond ((eq other t) (list (f c decomp)))
                        (other (prog1 (list (f other decomp) (f c decomp))
                                 (puthash decomp t ht)))
                        (t (puthash decomp c ht) nil)))))
    (seq-mapcat #\='g THE-STRING)))

then curated to remove U+00AA FEMININE ORDINAL INDICATOR, U+00BA
MASCULINE ORDINAL INDICATOR, and U+1D4C MODIFIER LETTER SMALL TURNED
OPEN E; which duplicated U+1D43 MODIFIER LETTER SMALL A, U+1D52 MODIFIER
LETTER SMALL O, and U+1D9F MODIFIER LETTER SMALL REVERSED OPEN E,
respectively.")

(defconst mipc-superscript--multigraphs
  "℠™🅪🅫🅬"
  "List of superscript characters which decompose to multiple glyphs.
Found via:

(seq-into
 (sort (cl-loop for i from 0 upto #x10FFFF
         if (let ((decomp (get-char-code-property i \='decomposition)))
              (and (seq-contains-p decomp \='super #\='eq)
                   (length> decomp 2)))
         collect i)
       :key (lambda (c) (length (get-char-code-property c \='decomposition))))
 \='string)")

(defun mipc-superscript-region
    (beg end &optional digraphs region-noncontiguous)
  "Convert characters in region to superscript.

More specifically, for every character C, if there exists a character
C\=' which decomposes (see `get-char-code-property') to \='(super C), C
is replaced with C\='.

If the optional argument DIGRAPHS is non-nil (interactively, if the
prefix arg is non-nil), then for any characters C_0, C_1, C_n for which
there exists a single codepoint C\=' that decomposes to \='(super C_0
C_1 ... C_n), they will be replaced by C\='.

In other words, TM will become U+2122 TRADE MARK SIGN instead of U+1D40
MODIFIER LETTER CAPITAL T, U+1D39 MODIFIER LETTER CAPITAL M; MC will
become U+1F16A RAISED MC SIGN instead of U+1D39 MODIFIER LETTER CAPITAL
M, U+A7F2 MODIFIER LETTER CAPITAL C; etc."
  (interactive
   (list (region-beginning)
         (region-end)
         current-prefix-arg
         (region-noncontiguous-p)))
  (let ((beg (set-marker (make-marker) beg))
        (end (set-marker (make-marker) end)))
   (dolist (r (if region-noncontiguous (region-bounds) (list (cons beg end))))
    (seq-do (lambda (c)
              (replace-string-in-region
               (seq-into (cdr (get-char-code-property c 'decomposition))
                         'string)
               (char-to-string c)
               (car r)
               (cdr r)))
            (concat (if digraphs mipc-superscript--multigraphs "")
                    mipc-superscript--monographs)))
   (set-marker beg nil)
   (set-marker end nil)))

(defun mipc-unsuperscript-region (beg end &optional region-noncontiguous)
  "Convert superscript characters in region to their decompositions.

More specifically, for every character C\=' which decomposes (see
`get-char-code-property') to \='(super C_0 C_1 ... C_n), C\=' is
replaced with C_0 C_1 ... C_n."
  (interactive
   (list (region-beginning)
         (region-end)
         (region-noncontiguous-p)))
  (let ((beg (set-marker (make-marker) beg))
        (end (set-marker (make-marker) end)))
    (dolist (r (if region-noncontiguous (region-bounds) (list (cons beg end))))
      (seq-do (lambda (c)
                (replace-string-in-region
                 (char-to-string c)
                 (seq-into (cdr (get-char-code-property c 'decomposition))
                           'string)
                 (car r)
                 (cdr r)))
              (concat mipc-superscript--multigraphs
                      mipc-superscript--monographs)))
    (set-marker beg nil)
    (set-marker end nil)))

(defconst mipc-subscript--monographs
  "ᵢᵣᵤᵥᵦᵧᵨᵩᵪ₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎ₐₑₒₓₔₕₖₗₘₙₚₛₜⱼ𞁑𞁒𞁓𞁔𞁕𞁖𞁗𞁘𞁙𞁚𞁛𞁜𞁝𞁞𞁟𞁠𞁡𞁢𞁣𞁤𞁥𞁦𞁧𞁨𞁩𞁪"
  "List of subscript characters which decompose to a single glyph.

Found via:

(seq-into
 (cl-loop for i from 0 upto #x10FFFF
          if (let ((decomp (get-char-code-property i \='decomposition)))
               (and (seq-contains-p decomp \='sub #\='eq)
                    (length= decomp 2)))
          collect i)
 \='string)")

(defconst mipc-subscript--multigraphs
  ""
  "List of subscript characters which decompose to multiple glyphs.

Found via:

(seq-into
 (sort (cl-loop for i from 0 upto #x10FFFF
         if (let ((decomp (get-char-code-property i \='decomposition)))
              (and (seq-contains-p decomp \='sub #\='eq)
                   (length> decomp 2)))
         collect i)
       :key (lambda (c) (length (get-char-code-property c \='decomposition))))
 \='string)")

(defun mipc-subscript-region
    (beg end &optional digraphs region-noncontiguous)
  "Convert characters in region to subscript.

More specifically, for every character C, if there exists a character
C\=' which decomposes (see `get-char-code-property') to \='(sub C), C is
replaced with C\='.

If the optional argument DIGRAPHS is non-nil (interactively, if the
prefix arg is non-nil), then for any characters C_0, C_1, C_n for which
there exists a single codepoint C\=' that decomposes to \='(sub C_0 C_1
... C_n), they will be replaced by C\='.

At time of writing, there are no such digraphs, so this is unnecessary."
  (interactive
   (list (region-beginning)
         (region-end)
         current-prefix-arg
         (region-noncontiguous-p)))
  (let ((beg (set-marker (make-marker) beg))
        (end (set-marker (make-marker) end)))
   (dolist (r (if region-noncontiguous (region-bounds) (list (cons beg end))))
    (seq-do (lambda (c)
              (replace-string-in-region
               (seq-into (cdr (get-char-code-property c 'decomposition))
                         'string)
               (char-to-string c)
               (car r)
               (cdr r)))
            (concat (if digraphs mipc-subscript--multigraphs "")
                    mipc-subscript--monographs)))
   (set-marker beg nil)
   (set-marker end nil)))

(defun mipc-unsubscript-region (beg end &optional region-noncontiguous)
  "Convert subscript characters in region to their decompositions.

More specifically, for every character C\=' which decomposes (see
`get-char-code-property') to \='(sub C_0 C_1 ... C_n), C\=' is replaced
with C_0 C_1 ... C_n."
  (interactive
   (list (region-beginning)
         (region-end)
         (region-noncontiguous-p)))
  (let ((beg (set-marker (make-marker) beg))
        (end (set-marker (make-marker) end)))
    (dolist (r (if region-noncontiguous (region-bounds) (list (cons beg end))))
      (seq-do (lambda (c)
                (replace-string-in-region
                 (char-to-string c)
                 (seq-into (cdr (get-char-code-property c 'decomposition))
                           'string)
                 (car r)
                 (cdr r)))
              (concat mipc-subscript--multigraphs
                      mipc-subscript--monographs)))
    (set-marker beg nil)
    (set-marker end nil)))

(provide 'mipc-superscript-region)

;;; mipc-superscript-region.el ends here
