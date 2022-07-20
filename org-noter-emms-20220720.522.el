;;; org-noter-emms.el --- Modules for EMMS  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  c1-g

;; Author: c1-g <char1iegordon@protonmail.com>
;; Homepage: https://github.com/cbpnk/org-noter-emms
;; Keywords: org-noter pdf
;; Package-Version: 20220720.522
;; Package-Commit: b79a77b077079949f5ddc5d7a8c298612b709848
;; Package-Requires: ((org-noter-core "1.4.2") (emms-file-mode "0.1"))
;; Version: 1.4.2

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:
(defun org-noter-emms--mode-supported (major-mode)
  (eq major-mode 'emms-file-mode))

(add-hook 'org-noter--mode-supported-hook #'org-noter-emms--mode-supported)

(defun org-noter-emms--set-up-document (major-mode)
  (org-noter-emms--mode-supported major-mode))

(add-hook 'org-noter--set-up-document-hook #'org-noter-emms--set-up-document)

(defun org-noter-emms--get-current-view (mode)
  (when (org-noter-emms--mode-supported mode)
    (vector 'emms (cdr (org-noter-doc-view--doc-approx-location mode)))))

(add-hook 'org-noter--get-current-view-hook #'org-noter-emms--get-current-view)

(defun org-noter-emms--time-p (location)
  (and
   location
   (consp location)
   (symbolp (car location))
   (eq (car location) 'emms)))

(defun org-noter-emms--check-location-property (property)
  (org-noter--with-valid-session
   (when (org-noter-emms--mode-supported (org-noter--session-doc-mode session))
     (let ((value (car (read-from-string property))))
       (org-noter-emms--time-p value)))))

(add-hook 'org-noter--check-location-property-hook
          #'org-noter-emms--check-location-property)

(defun org-noter-emms--parse-location-property (property)
  (org-noter--with-valid-session
   (when (org-noter-emms--mode-supported (org-noter--session-doc-mode session))
     (let ((value (car (read-from-string property))))
       (when (org-noter-emms--time-p value)
         value)))))

(add-hook 'org-noter--parse-location-property-hook
          #'org-noter-emms--parse-location-property)

(defun org-noter-emms--pretty-print-location (location)
  (org-noter--with-valid-session
   (when (org-noter-emms--mode-supported (org-noter--session-doc-mode session))
     (format "%s" location))))

(add-hook 'org-noter--pretty-print-location-hook
          #'org-noter-emms--pretty-print-location)

(defun org-noter-emms--doc-goto-location (mode location)
  (when (org-noter-emms--mode-supported mode)
    (when (org-noter-emms--time-p location)
      (org-noter--with-valid-session
       (with-current-buffer (org-noter--session-doc-buffer session)
         (if (emms-file-mode-playing-p)
             (emms-seek-to (cdr location))))))))

(add-hook 'org-noter--doc-goto-location-hook
          #'org-noter-emms--doc-goto-location)

(defun org-noter-emms--doc-approx-location (mode precise-info force-new-ref)
  (when (org-noter-emms--mode-supported mode)
    (org-noter--with-valid-session
     (with-current-buffer (org-noter--session-doc-buffer session)
       (cons 'emms current-time)))))
(add-hook 'org-noter--doc-approx-location-hook
          #'org-noter-emms--doc-approx-location)

(defun org-noter-emms--note-after-tipping-point (point location view)
  (when (eq (aref view 0) 'emms)
    (> (cdr location) (aref view 1))))

(add-hook 'org-noter--note-after-tipping-point-hook #'org-noter-emms--note-after-tipping-point)

(defun org-noter-emms--relative-position-to-view (location view)
  (when (eq (aref view 0) 'emms)
    (let ((time (aref view 1)))
      (cond ((<  (cdr location) time) 'before)
            ((<= (cdr location) time) 'inside)
            (t                        'after)))))

(add-hook 'org-noter--relative-position-to-view-hook #'org-noter-emms--relative-position-to-view)
(provide 'org-noter-emms)
;;; org-noter-emms.el ends here

