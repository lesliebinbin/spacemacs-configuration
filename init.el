;; -*- mode: emacs-lisp; lexical-binding: t -*-
;; This file is loaded by Spacemacs at startup.
;; It must be stored in your home directory.
(add-to-list 'load-path (expand-file-name "private/lisp" dotspacemacs-directory))
(setq user-packages-directory (expand-file-name "private/packages" dotspacemacs-directory))
(require 'user-custom-functions)

;;spacemacs layers
(load-file (expand-file-name "private/configuration/layers.el" dotspacemacs-directory))
;;spacemacs init
(load-file (expand-file-name "private/configuration/init.el" dotspacemacs-directory))
;;spacemacs user-init
(load-file (expand-file-name "private/configuration/user-init.el" dotspacemacs-directory))
;;spacemacs user-config
(load-file (expand-file-name "private/configuration/user-config.el" dotspacemacs-directory))
;;spacemacs user-env
(load-file (expand-file-name "private/configuration/user-env.el" dotspacemacs-directory))





;; Do not write anything past this comment. This is where Emacs will
;; auto-generate custom variable definitions.
(defun dotspacemacs/emacs-custom-settings ()
  "Emacs custom settings.
This is an auto-generated function, do not modify its content directly, use
Emacs customize menu instead.
This function is called at the very end of Spacemacs initialization."
  (custom-set-variables
   ;; custom-set-variables was added by Custom.
   ;; If you edit it by hand, you could mess it up, so be careful.
   ;; Your init file should contain only one such instance.
   ;; If there is more than one, they won't work right.
   '(ignored-local-variable-values
     '((js2-basic-offset . 2) (web-mode-indent-style . 2)
       (web-mode-block-padding . 2) (web-mode-script-padding . 2)
       (web-mode-style-padding . 2)))
   )
  (custom-set-faces
   ;; custom-set-faces was added by Custom.
   ;; If you edit it by hand, you could mess it up, so be careful.
   ;; Your init file should contain only one such instance.
   ;; If there is more than one, they won't work right.
   )
  )
