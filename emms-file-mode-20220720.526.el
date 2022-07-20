;;; emms-file-mode.el --- Play Media File with EMMS       -*- lexical-binding: t; -*-

;; Copyright (C) 2022  c1-g

;; Author: c1-g <char1iegordon@protonmail.com>
;; Homepage: https://github.com/cbpnk/emms-file-mode
;; Keywords: emms multimedia
;; Package-Version: 20220720.526
;; Package-Commit: 0070fe62b0f4239be3454434459c2425a4a2531e
;; Package-Requires: ((emms "11"))
;; Version: 0.1

;; This file is not part of EMMS.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:
(require 'emms)

(defun emms-file-mode-playing-p ()
  (string-equal buffer-file-name
                (emms-track-name (emms-playlist-current-selected-track))))

(defun emms-file-mode-paused-p ()
  (or (not emms-player-playing-p) emms-player-paused-p))


(defun emms-file-mode-toggle-play (&rest ignore)
  (interactive)
  (if (emms-file-mode-playing-p)
      (progn
        (if (not (emms-file-mode-paused-p))
            (widget-put widget :tag "Play")
          (widget-put widget :tag "Pause"))
        (custom-redraw widget)
        (set-buffer-modified-p nil)
        (emms-pause))
    (widget-put widget :tag "Pause")
    (custom-redraw widget)
    (set-buffer-modified-p nil)
    (emms-play-file buffer-file-name)
    (emms-seek-to current-time)))

(defun emms-file-mode-format-time (value)
  (format-seconds "%h:%z%.2m:%.2s" value))

(defun emms-file-mode-update-info (track)
  (when-let ((value (emms-track-get track 'info-playing-time nil)))
    (widget-put length-widget :value (emms-file-mode-format-time value))
    (custom-redraw length-widget))

  (mapc
   (lambda (label)
     (when-let ((value (emms-track-get track label nil)))
       (let ((widget (cdr (assoc label info-widgets))))
         (widget-put widget :value value)
         (custom-redraw widget))))
   '(info-album
     info-artist
     info-albumartist
     info-composer
     info-date
     info-originaldate
     info-performer
     info-title
     info-tracknumber
     info-discnumber
     info-year
     info-originalyear
     info-note
     info-genre
     info-label))
  (set-buffer-modified-p nil))

(defvar emms-file-mode-map (make-sparse-keymap))
(set-keymap-parent emms-file-mode-map widget-keymap)

(put 'emms-file-mode 'mode-class 'special)
(defun emms-file-mode()
  "Major mode to play media file"
  (interactive)
  (kill-all-local-variables)
  (major-mode-suspend)
  (setq-local global-linum-mode nil
              display-line-numbers-mode nil
              view-read-only nil)
  (setq mode-name "EMMS File Mode"
        buffer-read-only nil
        major-mode 'emms-file-mode)

  (custom--initialize-widget-variables)

  (setq-local current-time 0)
  (setq-local time-widget (widget-create 'item :format "%t%v\n" :tag "" :value "")
              length-widget (widget-create 'item :format "%t%v\n" :tag "" :value "")
              widget (widget-create
                      'push-button
                      :notify 'emms-file-mode-toggle-play
                      "Loading ..."))

  (widget-insert "\n")

  (setq-local
   info-widgets
   (mapcar
    (lambda (label)
      (cons (intern (format "info-%s" label))
            (widget-create 'item :format "%t: %v\n" :tag (format "%s" label) :value "")))
    '(title
      artist
      genre
      album
      year
      date
      tracknumber
      discnumber
      albumartist
      composer
      performer
      originaldate
      originalyear
      note
      label)))
  (widget-setup)

  (use-local-map emms-file-mode-map)

  (if (emms-file-mode-playing-p)
      (progn
        (if (emms-file-mode-paused-p)
            (widget-put widget :tag "Play")
          (widget-put widget :tag "Pause"))
        (custom-redraw widget)
        (set-buffer-modified-p nil))
    (widget-put widget :tag "Pause")
    (custom-redraw widget)
    (set-buffer-modified-p nil)
    (emms-play-file buffer-file-name))
  (emms-file-mode-update-info (emms-playlist-current-selected-track)))

(defun emms-file-mode-seek-to-start ()
  (interactive)
  (if (emms-file-mode-playing-p)
      (emms-seek-to 0)))

(defun emms-file-mode-seek-forward ()
  (interactive)
  (if (emms-file-mode-playing-p)
      (emms-seek-forward)))

(defun emms-file-mode-seek-backward ()
  (interactive)
  (if (emms-file-mode-playing-p)
      (emms-seek-backward)))

(defun emms-file-mode-seek (time)
  (interactive
   (list
    (save-match-data
      (let (s sec)
        (while (progn
                 (setq s (read-string "Time: "))
                 (not (string-match "\\([0-9]+\\)\\(?::\\([0-5]?[0-9]\\)\\(?::\\([0-5]?[0-9]\\)\\)?\\)?" s))))
        (setq sec (string-to-number (match-string 1 s)))
        (when-let ((sec2 (match-string 2 s)))
          (setq sec (+ (* 60 sec) (string-to-number sec2)))
          (when-let ((sec3 (match-string 3 s)))
            (setq sec (+ (* 60 sec) (string-to-number sec3)))))
        sec))))
  (if (emms-file-mode-playing-p)
      (emms-seek-to time)))

(define-key emms-file-mode-map (kbd "<") 'emms-file-mode-seek-to-start)
(define-key emms-file-mode-map (kbd "n") 'emms-file-mode-seek-forward)
(define-key emms-file-mode-map (kbd "p") 'emms-file-mode-seek-backward)
(define-key emms-file-mode-map (kbd "g") 'emms-file-mode-seek)
(define-key emms-file-mode-map (kbd "SPC") 'emms-file-mode-toggle-play)

(defun emms-file-mode-stopped ()
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and (eq major-mode 'emms-file-mode)
                 (emms-file-mode-playing-p))
        (widget-put widget :tag "Play")
        (custom-redraw widget)
        (set-buffer-modified-p nil)))))

(defun emms-file-mode-updated (track)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and (eq major-mode 'emms-file-mode)
                 (string-equal buffer-file-name (emms-track-name track)))
        (emms-file-mode-update-info track)))))

(defun emms-file-mode-time-set (value)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and (eq major-mode 'emms-file-mode)
                 (string-equal buffer-file-name (emms-track-name (emms-playlist-current-selected-track))))
        (setq-local current-time value)
        (widget-put time-widget :value (emms-file-mode-format-time value))
        (custom-redraw time-widget)
        (set-buffer-modified-p nil)))))

(add-hook 'emms-player-stopped-hook 'emms-file-mode-stopped)
(add-hook 'emms-player-finished-hook 'emms-file-mode-stopped)
(add-hook 'emms-track-updated-functions 'emms-file-mode-updated)
(add-hook 'emms-player-time-set-functions 'emms-file-mode-time-set)

(defun my-find-file-noselect-1 (buf filename nowarn rawfile truename number)
  (when (emms-player-for (emms-track 'file (expand-file-name filename)))
    (with-current-buffer buf
      (setq buffer-auto-save-file-name nil)
      (setq buffer-saved-size -1)
      (set-visited-file-name (expand-file-name filename))
      (setq default-directory (file-name-directory buffer-file-name))
      (emms-file-mode)
      (current-buffer))))

(advice-add 'find-file-noselect-1 :before-until 'my-find-file-noselect-1)
(provide 'emms-file-mode)
;;; emms-file-mode.el ends here
