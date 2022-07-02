#!/usr/bin/env -S emacs -Q --script

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

(package-initialize)
(when (not (package-installed-p 'package-build))
  (package-refresh-contents)
  (package-install 'package-build))

(setq package-build--melpa-base default-directory)
(setq package-build-working-dir (expand-file-name "working/" package-build--melpa-base))
(setq package-build-archive-dir (expand-file-name "packages/" package-build--melpa-base))
(setq package-build-recipes-dir (expand-file-name "recipes/" package-build--melpa-base))

(package-build-all)
