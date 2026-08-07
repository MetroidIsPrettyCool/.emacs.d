;;; oxhtmlcleanup.el --- cleanup filters for Org-mode export  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Joseph Burke

;; Author: Joseph Burke
;; Maintainer: Joseph Burke
;; Created: 23 Jan 2026
;; Version: 0.1.1
;; Package-Requires: (org-mode cl-macs css-mode js xmltok)
;; Keywords: tools

;; This file is not part of GNU Emacs.

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;; This package provides a number of export filter functions for Org mode
;; intended to improve the quality and validity of its (X)HTML output.
;;
;; To use them, simply add them to the appropriate org-export-filter-*-functions
;; list. See Info node `(org) Advanced Export Configuration' for more.
;;
;; TODO: clean up all of these initial implementations, maybe merge some of the
;; simpler ones. Fix some of the bugs.

;;; Code:

(require 'cl-macs)
(require 'css-mode)
(require 'js)
(require 'ox-html)
(require 'package)
(require 'xmltok)

(defgroup oxhtmlcleanup nil
  "Org mode (X)HTML export cleanup filters."
  :group 'tools)

(defcustom oxhtmlcleanup-tidy-exe "tidy"
  "Name of the HTML tidy executable to run for `oxhtmlcleanup-tidy'.
Will be passed to `executable-find'."
  :group 'oxhtmlcleanup
  :type 'string)

(defcustom oxhtmlcleanup-tidy-message-warnings nil
  "Should `oxhtmlcleanup-tidy' `lwarn' on warnings, or just `message'?
As in, should the warnings produced by the tidy executable be displayed
in Emacs with `display-warning', or with `message'? nil means the
former, t means the latter."
  :group 'oxhtmlcleanup
  :type 'boolean)

(defcustom oxhtmlcleanup-tidy-args
  '("-language" :language)
  "A list of arguments to pass to html-tidy for `oxhtmlcleanup-tidy'.
This should be a list of strings, communication channel string option
keywords and/or functions.

Strings will be passed through as-is, keywords will be looked up in the
filter communication channel (e.g. :language will get the language of
the file), and functions will be passed the final output to be
transformed, the name of the backend, and the export communication
channel; then evaluated. Functions should return a list of strings.

A list of communication channel properties can be found at
<https://orgmode.org/worg/dev/org-export-reference.html#communication>.

Don't pass the -output or -file arguments, this will break the filter."
  :group 'oxhtmlcleanup
  :type '(repeat (choice string function
                         (const :author)
                         (const :creator)
                         (const :date)
                         (const :description)
                         (const :email)
                         (const :input-buffer)
                         (const :keywords)
                         (const :language))))

(defcustom oxhtmlcleanup-extra-stylesheet
  "pre.src-C\\+\\+::before{content:\"C++\"}"
  "Style tag content for `oxhtmlcleanup-extra-style'.
Will be automatically wrapped in a <style> element and a comment-escaped
/*<![CDATA[*/ /*]]>*/ marked section."
  :group 'oxhtmlcleanup
  :type 'string)

(defcustom oxhtmlcleanup-extra-style-when 'always
  "When should `oxhtmlcleanup-extra-style' inject the extra style tag?
Always means always, when-default means when the default style is
detected, unless-default means when the default style isn't detected."
  :group 'oxhtmlcleanup
  :type '(choice (const always) (const when-default) (const unless-default)))

(defcustom oxhtmlcleanup-details-toc-details-id "toc-details"
  "ID that `oxhtmlcleanup-details-toc' applies to the <details> element.
If you change this setting, you'll probably want to update
`oxhtmlcleanup-details-toc-style', too."
  :group 'oxhtmlcleanup
  :type 'string)

(defcustom oxhtmlcleanup-details-toc-summary-class "summary-text"
  "Class that `oxhtmlcleanup-details-toc' applies to the summary text.
If you change this setting, you'll probably want to update
`oxhtmlcleanup-details-toc-style', too."
  :group 'oxhtmlcleanup
  :type 'string)

(defcustom oxhtmlcleanup-details-toc-style
  "@namespace\"http://www.w3.org/1999/xhtml\";#toc-details{padding:0 1ch}#toc-details:not([open]) > summary .summary-text::after{content:\"…\"}#toc-details summary h2{display:inline}#toc-details summary{font-size:90%;margin:0.2em}#toc-details summary,#toc-details[open] > :last-child{margin-block-end:0.25em;padding-block-end:0.25em;border-block-end:inset 2px gray}#toc-details dl{display:block;margin-block-start:1em;margin-block-end:1em;margin-inline-start:0;margin-inline-end:0}#toc-details dt{display:block;font-weight:bold}#toc-details dd{display:block;margin-inline-start:40px}#toc-details dl p,#toc-details ol p,#toc-details ul p{margin-block-start:0;margin-block-end:0}#toc-details dl:has( > dd > p + p) > dt{margin-block-start:1em}#toc-details dl:has( > dd > p + p) > dd{margin-block-end:1em}#toc-details dl:has( > dd > p + p) > * > p,#toc-details ol:has( > li > p + p) > * > p,#toc-details ol:has( > li > p + p) > li,#toc-details ul:has( > li > p + p) > * > p,#toc-details ul:has( > li > p + p) > li{margin-block-start:1em;margin-block-end:1em}#toc-details ul{display:block;margin-block-start:0;margin-block-end:0;padding-inline-start:40px;list-style-type:disc}#toc-details li{display:list-item}"
  "Extra style tag that `oxhtmlcleanup-details-toc' adds to the document.
This may be a string, or else nil, in which case no style will be
applied.

If you change `oxhtmlcleanup-details-toc-summary-class' or
`oxhtmlcleanup-details-toc-details-id', you'll probably want to change
this setting, too.

Will be automatically wrapped in a <style> element and a comment-escaped
/*<![CDATA[*/ /*]]>*/ marked section."
  :group 'oxhtmlcleanup
  :type '(choice string (const nil)))

(defcustom oxhtmlcleanup-postamble-details-id "export-details"
  "ID that `oxhtmlcleanup-postamble' applies to the <details> element.
If you change this setting, you'll probably want to update
`oxhtmlcleanup-postamble-style', too."
  :group 'oxhtmlcleanup
  :type 'string)

(defcustom oxhtmlcleanup-postamble-functions
  '(oxhtmlcleanup-postamble-author
    oxhtmlcleanup-postamble-export-time
    ("Created with:"
     oxhtmlcleanup-postamble-emacs-version
     oxhtmlcleanup-postamble-org-version
     oxhtmlcleanup-postamble-citeproc-version
     oxhtmlcleanup-postamble-htmlize-version
     oxhtmlcleanup-postamble-tidy-version
     oxhtmlcleanup-postamble-themes))
  "Functions that `oxhtmlcleanup-postamble' makes the export details with.
This is a nested list of functions defining term/details pairs which
will become <dt><dd> elements in a nested definition list.

Each element of every list should either be a function which returns a
cons pair of strings (TERM . DETAILS), which will be formatted into
<dt>TERM</dt><dd>DETAILS</dd>, or a list starting with a term string.

The idea is that a list like (foo bar (\"baz\" fee fie foe)), where each
is a function that returns something like (\"foo term\" . \"foo
details\"), will be processed into this:

<dl>
  <dt>foo term</dt><dd>foo details</dd>
  <dt>bar term</dt><dd>bar details</dd>
  <dt>baz</dt>
  <dd>
    <dt>fee term</dt><dd>fee details</dd>
    <dt>fie term</dt><dd>fie details</dd>
    <dt>foe term</dt><dd>foe details</dd>
  </dd>
</dl>

Every function will be passed the same arguments as the filter: the
final output to be transformed, the name of the backend, and the export
communication channel.

Functions may also return nil, to indicate their output should be skipped.

If you change this setting, you'll probably want to update
`oxhtmlcleanup-postamble-style', too."
  :group 'oxhtmlcleanup
  :type 'sexp)

(defcustom oxhtmlcleanup-postamble-summary
  "<span class=\"summary-text\">Export Details</span>"
  "Summary of the `oxhtmlcleanup-postamble' <details> element.

If you change this setting, you might want to update
`oxhtmlcleanup-postamble-style', too."
  :group 'oxhtmlcleanup
  :type 'string)

(defcustom oxhtmlcleanup-postamble-footer
  "<div class=\"org-center\">
<p><a href=\"https://validator.w3.org/check?uri=referer\">Validate me</a>!
<a href=\"https://jigsaw.w3.org/css-validator/check/referer\">
<img style=\"border:0;width:88px;height:31px\"
src=\"https://jigsaw.w3.org/css-validator/images/vcss\"
alt=\"Valid CSS!\" />
</a>
</p>
</div>"
  "More (X)HTML to put at the bottom of `oxhtmlcleanup-postamble'."
  :group 'oxhtmlcleanup
  :type 'string)

(defcustom oxhtmlcleanup-postamble-style
  "@namespace\"http://www.w3.org/1999/xhtml\";#export-details{padding:0 1ch}#export-details:not([open]) > summary .summary-text::after{content:\"…\"}#export-details summary{font-size:90%;margin:0.2em}#export-details summary,#export-details[open] > :last-child{margin-block-end:0.25em;padding-block-end:0.25em;border-block-end:inset 2px gray}#export-details dl{display:block;margin-block-start:0;margin-block-end:0;margin-inline-start:0;margin-inline-end:0}#export-details dt{display:block;font-weight:bold}#export-details dd{display:block;margin-inline-start:40px}#export-details dl p,#export-details ol p,#export-details ul p{margin-block-start:0;margin-block-end:0}#export-details dl:has( > dd > p + p) > dt{margin-block-start:1em}#export-details dl:has( > dd > p + p) > dd{margin-block-end:1em}#export-details dl:has( > dd > p + p) > * > p,#export-details ol:has( > li > p + p) > * > p,#export-details ol:has( > li > p + p) > li,#export-details ul:has( > li > p + p) > * > p,#export-details ul:has( > li > p + p) > li{margin-block-start:1em;margin-block-end:1em}#export-details ol{display:block;margin-block-start:0;margin-block-end:0;padding-inline-start:40px;list-style-type:decimal}#export-details ul{display:block;margin-block-start:0;margin-block-end:0;padding-inline-start:40px;list-style-type:disc}#export-details li{display:list-item}"
  "Extra style tag that `oxhtmlcleanup-postamble' adds to the document.
This may be a string, or else nil, in which case no style will be
applied.

Will be automatically wrapped in a <style> element and a comment-escaped
/*<![CDATA[*/ /*]]>*/ marked section.

You'll probably want to change this setting if you change
`oxhtmlcleanup-postamble-details-id' or
`oxhtmlcleanup-postamble-summary'."
  :group 'oxhtmlcleanup
  :type '(choice string (const nil)))

(defvar oxhtmlcleanup-tidy-disable nil
  "Disable `oxhtmlcleanup-tidy'.
Intended to be set locally; per-file or per-project. If you just want to
turn the filter off globally, remove it from
`org-export-filter-final-output-functions'.")

(defvar oxhtmlcleanup-trim-examples-disable nil
  "Disable `oxhtmlcleanup-trim-examples'.
Intended to be set locally; per-file or per-project. If you just want to
turn the filter off globally, remove it from
`org-export-filter-example-block-functions'.")

(defvar oxhtmlcleanup-dedup-ids-disable nil
  "Disable `oxhtmlcleanup-dedup-ids'.
Intended to be set locally; per-file or per-project. If you just want to
turn the filter off globally, remove it from
`org-export-filter-final-output-functions'.")

(defvar oxhtmlcleanup-zwsp-disable nil
  "Disable `oxhtmlcleanup-zwsp'.
Intended to be set locally; per-file or per-project. If you just want to
turn the filter off globally, remove it from
`org-export-filter-final-output-functions'.")

(defvar oxhtmlcleanup-extra-style-disable nil
  "Disable `oxhtmlcleanup-extra-style'.
Intended to be set locally; per-file or per-project. If you just want to
turn the filter off globally, remove it from
`org-export-filter-final-output-functions'.")

(defvar oxhtmlcleanup-foreign-lang-disable nil
  "Disable `oxhtmlcleanup-foreign-lang'.
Intended to be set locally; per-file or per-project. If you just want to
turn the filter off globally, remove it from
`org-export-filter-final-output-functions'.")

(defvar oxhtmlcleanup-details-toc-disable nil
  "Disable `oxhtmlcleanup-details-toc'.
Intended to be set locally; per-file or per-project. If you just want to
turn the filter off globally, remove it from
`org-export-filter-final-output-functions'.")

(defvar oxhtmlcleanup-postamble-disable nil
  "Disable `oxhtmlcleanup-postamble'.
Intended to be set locally; per-file or per-project. If you just want to
turn the filter off globally, remove it from
`org-export-filter-final-output-functions'.")

(defun oxhtmlcleanup-tidy (string backend comm-channel)
  "Clean Org mode (X)HTML export with the html-tidy CLI tool.
Add this function to `org-export-filter-final-output-functions' to use
it. This can be done on a per-file basis with the #+BIND keyword, if you
enable the `org-export-allow-bind-keywords' user option.

You can selectively disable this filter by setting
`oxhtmlcleanup-tidy-disable' to t."
  (when (and (not oxhtmlcleanup-tidy-disable)
             (org-export-derived-backend-p backend 'html)
             (or (executable-find oxhtmlcleanup-tidy-exe)
                 (progn
                   (lwarn "oxhtmlcleanup-tidy" :warning
                          "oxhtmlcleanup-tidy filter applied, but oxhtmlcleanup-tidy-exe does not exist. Skipping...")
                   nil)))
    (when-let* ((stderr-tmp-file (make-temp-file "oxhtmlcleanup-tidy"))
                (output-file (plist-get comm-channel :output-file))
                (input-file (plist-get comm-channel :input-file)))
      (message "oxhtmlcleanup-tidy: processing %S" output-file)
      (with-temp-buffer
        (insert string)
        (let ((exit-status
               (apply #'call-process-region nil nil
                      oxhtmlcleanup-tidy-exe
                      t (list t stderr-tmp-file) nil
                      (mapcan (lambda (e) (cond
                                           ((stringp e) (list e))
                                           ((keywordp e) (list (plist-get comm-channel e)))
                                           ((functionp e) (funcall e string backend comm-channel))))
                              oxhtmlcleanup-tidy-args))))
          (with-temp-buffer
            (insert-file-contents stderr-tmp-file)
            (save-match-data
              (while (re-search-forward
                      (rx "line" (*? space) (group-n 1 (+ digit))
                          (*? space)
                          "column" (*? space) (group-n 2 (+ digit))
                          (*? space) ?- (*? space)
                          (group-n 3 (or "Warning" "Error")) ?:
                          (group-n 4 (*? anything))
                          eol)
                      nil t)
                (cond
                 ((and (string-equal (match-string 3) "Warning")
                       oxhtmlcleanup-tidy-message-warnings)
                  (message "oxhtmlcleanup-tidy: %s:%s:%s - %s:%s"
                           output-file
                           (match-string-no-properties 1) (match-string-no-properties 2)
                           (match-string-no-properties 3) (match-string-no-properties 4)))
                 ((string-equal (match-string 3) "Warning")
                  (lwarn "oxhtmlcleanup-tidy" :warning
                         "%s:%s:%s -%s"
                         output-file                    (match-string-no-properties 1)
                         (match-string-no-properties 2) (match-string-no-properties 4)))
                 ((string-equal (match-string 3) "Error")
                  (lwarn "oxhtmlcleanup-tidy" :error
                         "%s:%s:%s -%s"
                         output-file                    (match-string-no-properties 1)
                         (match-string-no-properties 2) (match-string-no-properties 4)))))))

          (delete-file stderr-tmp-file nil)
          (when (= exit-status 2) (error "oxhtmlcleanup-tidy: tidy exited with code 2, indicating errors!")))
        (buffer-substring-no-properties (point-min) (point-max))))))

(defun oxhtmlcleanup-trim-examples (string backend comm-channel)
  "Trim excess newlines from example blocks in Org (X)HTML export.
Add this function to `org-export-filter-example-block-functions' to use
it. This can be done on a per-file basis with the #+BIND keyword if you
enable the `org-export-allow-bind-keywords' user option.

You can selectively disable this filter by setting
`oxhtmlcleanup-trim-examples-disable' to t."
  (when (and (not oxhtmlcleanup-trim-examples-disable)
             (org-export-derived-backend-p backend 'html))
    (with-temp-buffer
      (insert string)
      (goto-char (point-min))
      (xmltok-forward)
      (message
       "oxhtmlcleanup-trim-example-blocks: trimming example %S in %S"
       (xmltok-attribute-value (oxhtmlcleanup--get-xmltok-attr "id"))
       (plist-get comm-channel :output-file))
      (when (= (char-after) ?\C-j) (delete-char 1))
      (xmltok-forward)
      (when (= (char-before) ?\C-j) (delete-char -1))
      (buffer-substring-no-properties (point-min) (point-max)))))

(defun oxhtmlcleanup-dedup-ids (string backend comm-channel)
  "Fix duplicate element ids in Org (X)HTML export.
Just naïvely looks for elements with the qname id, and notes down if it
finds multiple examples of the same thing. The first element (from the
top of the document) with a given id is assumed to be the \"correct\"
element for that id, all subsequent elements with the same id are
assumed to be the duplicates.

If the id follows the format PREFIX(.NUMBER+), e.g. \"fnr.1.1\", then
the rewriting engine will continue this format to de-duplicate.
Otherwise, they will be suffixed _NUMBER, with NUMBER starting at 1 for
the first encountered duplicate and increasing by one for every
subsequent duplicate -- skipping any values that were found in the
document.

For example, running this filter on the document

<foo id=\"alice\">
  <bar id=\"bob\">
    <baz id=\"bob\"></baz>
  </bar>
  <bar id=\"fnr.1\"></bar>
  <bar id=\"fnr.1.1\"></bar>
  <bar id=\"fnr.1\">
    <baz></baz>
  </bar>
  <bar id=\"fnr.1\">
    <baz></baz>
  </bar>
  <qux id=\"bob_1\"/>
  <qux id=\"bob_1\"/>
  <qux id=\"bob_2\"/>
</foo>

produces the result

<foo id=\"alice\">
  <bar id=\"bob\">
    <baz id=\"bob_3\"></baz>
  </bar>
  <bar id=\"fnr.1\"></bar>
  <bar id=\"fnr.1.1\"></bar>
  <bar id=\"fnr.1.1.1\">
    <baz></baz>
  </bar>
  <bar id=\"fnr.1.1.1.1\">
    <baz></baz>
  </bar>
  <qux id=\"bob_1\"/>
  <qux id=\"bob_3\"/>
  <qux id=\"bob_2\"/>
</foo>

Does not perform any hyperlink rewriting, it is assumed that all links
to a given id were meant to point to the first such instance.

Add this function to `org-export-filter-final-output-functions' to use
it. This can be done on a per-file basis with the #+BIND keyword if you
enable the `org-export-allow-bind-keywords' user option.

You can selectively disable this filter by setting
`oxhtmlcleanup-dedup-ids-disable' to t."
  (when (and (not oxhtmlcleanup-dedup-ids-disable)
             (org-export-derived-backend-p backend 'html))
    (message "oxhtmlcleanup-dedup-ids: processing %S" (plist-get comm-channel :output-file))
    (with-temp-buffer
      (insert string)
      (xmltok-save
        (goto-char (point-min))
        (xmltok-forward-prolog)
        ;; same format as `dup-ids', but for the rewritten ids.
        (let ((new-ids))
          (let (;; set of encountered attribute values for the id attribute.
                (seen-ids (make-hash-table :test 'equal))
                ;; list of (ATTR-VAL ATTR-VAL-START ATTR-VAL-END) lists, one
                ;; entry for every id value that already existed in
                ;; first-occurrence when we encountered it. The list is in
                ;; reverse order -- i.e. from the bottom of the file to the top.
                (dup-ids))
            ;; step 1: get a list of all the ids in the document.
            (while-let ((kind (xmltok-forward)))
              (when (or (eq kind 'start-tag) (eq kind 'empty-element))
                (when-let* ((id-attr (oxhtmlcleanup--get-xmltok-attr "id"))
                            (value   (xmltok-attribute-value id-attr)))
                  (if (not (gethash value seen-ids))
                      (puthash value t seen-ids)
                    (push (list value
                                (xmltok-attribute-value-start id-attr)
                                (xmltok-attribute-value-end   id-attr))
                          dup-ids)))))
            ;; step 2: come up with the new ids
            (let (;; map of the values of PREFIX for id values of the format
                  ;; PREFIX(.NUMBER+) we've seen to the associated suffix for
                  ;; the number of duplicates so far.
                  (recurring-dups (make-hash-table :test 'equal))
                  ;; map of the values of PREFIX for id values of the format
                  ;; PREFIX_NUMBER we've seen to the number of duplicates so
                  ;; far.
                  (underscore-dups (make-hash-table :test 'equal)))
              (dolist (id (nreverse dup-ids))
                (cond
                 ((when-let* ((id-value (car id))
                              (parsed (oxhtmlcleanup--recurring-fmt-id-p id-value))
                              (prefix       (nth 0 parsed))
                              (number       (nth 1 parsed))
                              (suffix (concat (gethash prefix recurring-dups "")
                                              "." number))
                              (new-id (concat prefix suffix)))
                    (while (gethash new-id seen-ids)
                      (setq suffix (concat suffix "." number))
                      (setq new-id (concat new-id "." number)))
                    (setcar id new-id)
                    (push id new-ids)
                    (puthash prefix suffix recurring-dups)
                    t))
                 ((let* ((id-value (car id))
                         (parsed (oxhtmlcleanup--underscore-fmt-id-parse id-value))
                         (prefix (car parsed))
                         (number (1+ (or (cdr parsed) 0)))
                         (new-id (format "%s_%d" prefix number)))
                    (while (gethash new-id seen-ids)
                      (setq number (1+ number))
                      (setq new-id (format "%s_%d" prefix number)))
                    (setcar id new-id)
                    (push id new-ids)
                    (puthash prefix number underscore-dups)
                    t))))))
          ;; step 3: write them back into the document
          (dolist (id new-ids)
            (goto-char (nth 1 id))
            (delete-region (nth 1 id) (nth 2 id))
            (insert (nth 0 id)))))
      (buffer-substring (point-min) (point-max)))))

(defun oxhtmlcleanup-zwsp (string _backend comm-channel)
  "Remove Zero-Width Space characters from Org mode (X)HTML export.
Add this function to `org-export-filter-final-output-functions' to use
it. This can be done on a per-file basis with the #+BIND keyword if you
enable the `org-export-allow-bind-keywords' user option.

You can selectively disable this filter by setting
`oxhtmlcleanup-zwsp-disable' to t."
  (unless oxhtmlcleanup-zwsp-disable
    (message "oxhtmlcleanup-zwsp: processing %S" (plist-get comm-channel :output-file))
    (string-replace (char-to-string ?\x200b) "" string)))

(defun oxhtmlcleanup-extra-style (string backend comm-channel)
  "Add an extra style tag to Org (X)HTML output.
Intended as a slightly smarter alternative to setting `org-html-head'.

Behavior depends on the `oxhtmlcleanup-extra-style-when' user option.

If it is set to \='always, then the extra style tag will always be added.
If it is set to \='when-default, it will only be added if the default
style is detected. If it is set to \='unless-default, it will only be
added if the default style ISN'T detected. In every case, it will always
be placed before the first non-default style tag in the document, or
just before the <head> closing tag if there are no such other style
tags.

This default style detection works by looking for style tags with the
same content as `org-html-style-default', so this filter should be
placed relatively early in your filter list to avoid any interference
from indentation passes or the like.

Add this function to `org-export-filter-final-output-functions' to use
it. This can be done on a per-file basis with the #+BIND keyword if you
enable the `org-export-allow-bind-keywords' user option.

You can selectively disable this filter by setting
`oxhtmlcleanup-extra-style-disable' to t."
  (when (and (not oxhtmlcleanup-extra-style-disable)
             (org-export-derived-backend-p backend 'html))
    (let ((output-file (plist-get comm-channel :output-file)))
      (message "oxhtmlcleanup-extra-style: processing %S" output-file)
      (with-temp-buffer
        (insert string)
        (xmltok-save
          (goto-char (point-min))
          (xmltok-forward-prolog)
          (when (oxhtmlcleanup--inject-style-element oxhtmlcleanup-extra-stylesheet
                                                     oxhtmlcleanup-extra-style-when)
            (message "oxhtmlcleanup-extra-style: added extra style into %S" output-file)
            (buffer-substring-no-properties (point-min) (point-max))))))))

(defun oxhtmlcleanup-foreign-lang (string backend comm-channel)
  "Clean up <style> and <script> elements in Org (X)HTML export.
Intended only for HTML5 or XHTML5 doctypes.

Strips type attributes, and escapes <![CDATA[ ]]> marked sections with
the comment delimiters /**/, if they were not already present.

Because, at time of writing, HTML tidy automatically applies the
attribute type=\"css\" to the style tags it generates, you should place
this filter after `oxhtmlcleanup-tidy' in your filter list.

Add this function to `org-export-filter-final-output-functions' to use
it. This can be done on a per-file basis with the #+BIND keyword if you
enable the `org-export-allow-bind-keywords' user option.

You can selectively disable this filter by setting
`oxhtmlcleanup-foreign-lang-disable' to t."
  (when (and (not oxhtmlcleanup-foreign-lang-disable)
             (org-export-derived-backend-p backend 'html))
    (message "oxhtmlcleanup-style-type-attrs: processing %S" (plist-get comm-channel :output-file))
    (catch 'early-return
      (with-temp-buffer
        (insert string)
        (xmltok-save
          (goto-char (point-min))
          (xmltok-forward-prolog)
          (while (xmltok-forward)
            (when (and (eq xmltok-type 'start-tag)
                       (or (string-equal (xmltok-start-tag-qname) "style")
                           (string-equal (xmltok-start-tag-qname) "script")))
              (when-let* ((type-attr (oxhtmlcleanup--get-xmltok-attr "type")))
                (delete-region (- (xmltok-attribute-name-start type-attr)
                                  (if (= ?\x20 (char-before (xmltok-attribute-name-start type-attr)))
                                      1 0))
                               (+ (xmltok-attribute-value-end type-attr)
                                  (if (and (= ?\" (char-after  (xmltok-attribute-value-end   type-attr)))
                                           (= ?\" (char-before (xmltok-attribute-value-start type-attr))))
                                      1 0)))
                (goto-char xmltok-start)
                (xmltok-forward))
              (let ((content-start (point)))
                (while (not (eq (xmltok-forward) 'end-tag))
                  (unless xmltok-type (throw 'early-return nil)))
                (goto-char xmltok-start)
                (let ((tag-name (xmltok-end-tag-qname))
                      (content (delete-and-extract-region content-start
                                                          xmltok-start)))
                  (insert
                   (with-temp-buffer
                     (insert content)
                     (goto-char (point-min))
                     (if (string-equal tag-name "style")
                         (css-mode) (js-mode))
                     (when (search-forward "<![CDATA[" nil t)
                       (unless (nth 4 (syntax-ppss))
                         (insert "*/")
                         (backward-char 11)
                         (insert "/*"))
                       (search-forward "]]>")
                       (unless (nth 4 (syntax-ppss))
                         (insert "*/")
                         (backward-char 5)
                         (insert "/*")))
                     (buffer-substring-no-properties (point-min) (point-max)))))))))
        (buffer-substring-no-properties (point-min) (point-max))))))

(defun oxhtmlcleanup-details-toc (string backend comm-channel)
  "Reformat table of contents in Org (X)HTML export as a <details>.
Intended only for the HTML5 or XHTML5 doctypes, as the <details> element
did not exist previously.

This filter can add an additional style tag to the document, you can
customize this with the user option `oxhtmlcleanup-details-toc-style'.

Add this function to `org-export-filter-final-output-functions' to use
it. This can be done on a per-file basis with the #+BIND keyword if you
enable the `org-export-allow-bind-keywords' user option.

You can selectively disable this filter by setting
`oxhtmlcleanup-details-toc-disable' to t."
  (when (and (not oxhtmlcleanup-details-toc-disable)
             (org-export-derived-backend-p backend 'html))
    (let ((output-file (plist-get comm-channel :output-file)))
      (message "oxhtmlcleanup-details-toc: processing %S" output-file)
      (catch 'early-return
        (with-temp-buffer
          (insert string)
          (xmltok-save
            (goto-char (point-min))
            (xmltok-forward-prolog)

            (when oxhtmlcleanup-details-toc-style
              (if (oxhtmlcleanup--inject-style-element oxhtmlcleanup-details-toc-style 'always)
                  (message "oxhtmlcleanup-details-toc: added style to %S" output-file)
                (error "oxhtmlcleanup-details-toc: unable to add requested style element to %S!"
                       output-file)))

            (while (not (and (eq (xmltok-forward) 'start-tag)
                             (when-let* ((id (oxhtmlcleanup--get-xmltok-attr "id")))
                               (string-equal
                                (xmltok-attribute-value id)
                                "table-of-contents"))))
              (unless xmltok-type (throw 'early-return nil)))
            (insert "<details id=\"" oxhtmlcleanup-details-toc-details-id "\"><summary>")
            (while (not (and (eq (xmltok-forward) 'start-tag)
                             (string-equal (xmltok-start-tag-qname) "h2")))
              (unless xmltok-type (throw 'early-return nil)))
            (insert "<span class=\"" oxhtmlcleanup-details-toc-summary-class "\">")
            (while (not (and (eq (xmltok-forward) 'end-tag)
                             (string-equal (xmltok-end-tag-qname) "h2")))
              (unless xmltok-type (throw 'early-return nil)))
            (insert "</summary>")
            (goto-char xmltok-start)
            (insert "</span>")
            (while (not (and (eq (xmltok-forward) 'end-tag)
                             (string-equal (xmltok-end-tag-qname) "nav")))
              (unless xmltok-type (throw 'early-return nil)))
            (goto-char xmltok-start)
            (insert "</details>"))
          (buffer-substring-no-properties (point-min) (point-max)))))))

(defun oxhtmlcleanup-postamble (string backend comm-channel)
  "Inject a better postamble into Org (X)HTML export.
Intended only for the HTML5 or XHTML5 doctypes, as the <details> element
did not exist previously.

This filter can add an additional style tag to the document, you can
customize this with the user option `oxhtmlcleanup-postamble-style'.

Add this function to `org-export-filter-final-output-functions' and set
`org-html-postamble-format' to \"<oxhtmlcleanup-postamble-here />\" in
order to use it. This can be done on a per-file basis with the #+BIND
keyword if you enable the `org-export-allow-bind-keywords' user option.

You can selectively disable this filter by setting
`oxhtmlcleanup-postamble-disable' to t."
  (when (and (not oxhtmlcleanup-postamble-disable)
             (org-export-derived-backend-p backend 'html))
    (let ((output-file (plist-get comm-channel :output-file)))
      (message "oxhtmlcleanup-postamble: processing %S" output-file)
      (with-temp-buffer
        (insert string)
        (xmltok-save
          (goto-char (point-min))
          (xmltok-forward-prolog)

          (when oxhtmlcleanup-postamble-style
            (if (oxhtmlcleanup--inject-style-element oxhtmlcleanup-postamble-style 'always)
                (message "oxhtmlcleanup-postamble: added style to %S" output-file)
              (error "oxhtmlcleanup-postamble: unable to add requested style element to %S!"
                     output-file)))

          (while (xmltok-forward)
            (when (and (eq xmltok-type 'empty-element)
                       (string-equal (xmltok-start-tag-qname)
                                     "oxhtmlcleanup-postamble-here"))
              (delete-region xmltok-start (point))
              (insert
               "<details id=\"" oxhtmlcleanup-postamble-details-id "\">\n<summary>"
               oxhtmlcleanup-postamble-summary "</summary>\n")

              (let ((children))
                (dolist (e oxhtmlcleanup-postamble-functions)
                  (when-let* ((child (oxhtmlcleanup--postamble-dl-recursive e string backend comm-channel)))
                    (push child children)))
                (when children
                  (push "</dl>\n" children)
                  (insert (apply #'concat "<dl>\n" (nreverse children)))))

              (insert oxhtmlcleanup-postamble-footer
                      "</details>"))))
        (buffer-substring-no-properties (point-min) (point-max))))))

(defun oxhtmlcleanup-postamble-author (_ _ comm-channel)
  "Returns author info for `oxhtmlcleanup-postamble-functions'."
  (when-let* ((author (car (plist-get comm-channel :author))))
    (cons "Author:" author)))

(defun oxhtmlcleanup-postamble-export-time (_ _ _)
  "Returns export date info for `oxhtmlcleanup-postamble-functions'."
    (cons "Last Exported:" (format-time-string "%Y-%m-%d %H:%M:%S")))

(defun oxhtmlcleanup-postamble-emacs-version (_ _ _)
  "Returns emacs version info for `oxhtmlcleanup-postamble-functions'."
  (cons "<a href=\"https://www.gnu.org/software/emacs/\">GNU Emacs</a>"
        (concat "version " (string-trim-left (emacs-version) "GNU Emacs "))))

(defun oxhtmlcleanup-postamble-org-version (_ _ _)
  "Returns Org version info for `oxhtmlcleanup-postamble-functions'."
  (cons "<a href=\"https://orgmode.org\">Org</a> mode"
        (concat "version " (if (fboundp 'org-version) (org-version) "unknown"))))

(defun oxhtmlcleanup-postamble-citeproc-version (_ _ _)
  "Returns citeproc version info for `oxhtmlcleanup-postamble-functions'."
  (cons "<a href=\"https://github.com/andras-simonyi/citeproc-el\">citeproc-el</a>"
        (concat "version " (or (when-let* ((pkg (cadr (assq 'citeproc package-alist))))
                                 (package-version-join (package-desc-version pkg)))
                               "unknown"))))

(defun oxhtmlcleanup-postamble-htmlize-version (_ _ _)
  "Returns htmlize version info for `oxhtmlcleanup-postamble-functions'."
  (cons "<a href=\"https://elpa.nongnu.org/nongnu/htmlize.html\">htmlize</a>"
        (concat "version " (or (and (boundp 'htmlize-version) htmlize-version) "unknown"))))

(defun oxhtmlcleanup-postamble-tidy-version (_ _ _)
  "Returns HTML tidy version info for `oxhtmlcleanup-postamble-functions'."
  (with-temp-buffer
    (call-process "tidy" nil t nil "--version")
    (goto-char 0)
    (insert "<a href=\"https://www.html-tidy.org/\">")
    (search-forward "HTML Tidy")
    (insert "</a>")
    (search-forward " version")
    (cons (buffer-substring-no-properties (point-min) (- (point) 8))
          (buffer-substring-no-properties (- (point) 7) (1- (point-max))))))

(defun oxhtmlcleanup-postamble-themes (_ _ _)
  "Returns info on enabled themes for `oxhtmlcleanup-postamble-functions'."
  (cons "and the following Emacs themes:"
        (concat "<ul>"
                (mapconcat (lambda (e) (format "<li><code>%s</code></li>\n" e)) custom-enabled-themes)
                "</ul>")))

(defun oxhtmlcleanup--inject-style-element (style inject-when)
  (let ((default-style-content
         (string-trim org-html-style-default (rx "<style type=\"text/css\">") (rx "</style>")))
        (first-non-default-style))
    (catch 'done
      (while (xmltok-forward)
        (cond
         ((and (eq xmltok-type 'start-tag)
               (string-equal (xmltok-start-tag-qname) "style"))
          (let ((content-start (point)))
            (cl-loop until (eq (xmltok-forward) 'end-tag)
                     unless xmltok-type do (throw 'done nil))
            (when (string-equal (buffer-substring content-start xmltok-start) default-style-content)
              (if (eq inject-when 'unless-default)
                  (throw 'done nil)
                (oxhtmlcleanup--inject-style-finish style)))
            (unless first-non-default-style (setq first-non-default-style content-start))))

         ((and (eq xmltok-type 'end-tag)
               (string-equal (xmltok-end-tag-qname) "head"))
          (when (not (eq inject-when 'when-default))
            (goto-char (or first-non-default-style xmltok-start))
            (oxhtmlcleanup--inject-style-finish style))
          (throw 'done nil))

         ((or (and (eq xmltok-type 'start-tag)
                   (string-equal (xmltok-start-tag-qname) "body"))
              (and (eq xmltok-type 'end-tag)
                   (string-equal (xmltok-end-tag-qname) "html")))
          (when (not (eq inject-when 'when-default))
            (goto-char (or first-non-default-style xmltok-start))
            (insert "<head></head>")
            (backward-char 7)
            (oxhtmlcleanup--inject-style-finish style))
          (throw 'done nil)))))))

(defun oxhtmlcleanup--inject-style-finish (style)
  (insert "<style>/*<![CDATA[*/" style "/*]]>*/</style>")
  (throw 'done t))

(defun oxhtmlcleanup--get-xmltok-attr (attr-name)
  (catch 'found
    (dolist (attr xmltok-attributes)
      (when (string-equal (buffer-substring-no-properties (xmltok-attribute-name-start attr)
                                                          (xmltok-attribute-name-end   attr))
                          attr-name)
        (throw 'found attr)))))

(defun oxhtmlcleanup--recurring-fmt-id-p (id)
  "Return (PREFIX NUMBER COUNT) for PREFIX(.NUMBER+) ids, else nil
where
    NUMBER    is the string form of NUMBER, and
    COUNT     is the number of times the .NUMBER appears."
  (when-let* ((i (string-match-p (rx "." (+ digit) eos) id)))
    (let* ((count 1)
           (number (substring id (1+ i)))
           (suffix (substring id i))
           (prefix
            (substring id nil
                       (cl-loop for j from i downto 0 by (- (length id) i)
                                while (string-suffix-p suffix
                                                       (substring id nil j))
                                do (setq count (1+ count))
                                finally return j))))
      (list prefix number count))))

(defun oxhtmlcleanup--underscore-fmt-id-parse (id)
  "Return (PREFIX . NUMBER-OR-NIL) for PREFIX(_NUMBER?) ids
where
    NUMBER-OR-NIL    is either the number (as an integer) after the
                     underscore, or nil if the underscore was omitted."
  (let ((i (string-match-p (rx "_" (+ digit) eos) id)))
    (cons (substring id nil i)
          (when i (string-to-number (substring id (1+ i)))))))

(defun oxhtmlcleanup--postamble-dl-recursive (fn-or-list string backend comm-channel)
  (cond
   ((functionp fn-or-list)
    (when-let* ((pair (funcall fn-or-list string backend comm-channel)))
      (concat "<dt>" (car pair) "</dt><dd>" (cdr pair) "</dd>\n")))
   ((and (listp fn-or-list) (stringp (car fn-or-list)))
    (let ((children))
      (dolist (e (cdr fn-or-list))
        (when-let* ((child (oxhtmlcleanup--postamble-dl-recursive e string backend comm-channel)))
          (push child children)))
      (when children
        (push "</dl></dd>\n" children)
        (apply #'concat "<dt>" (car fn-or-list) "</dt>\n<dd><dl>\n" (nreverse children)))))))

(provide 'oxhtmlcleanup)

;;; oxhtmlcleanup.el ends here
