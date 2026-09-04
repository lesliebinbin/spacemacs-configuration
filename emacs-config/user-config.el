;; -*- mode: emacs-lisp; lexical-binding: t -*-

(defun dotspacemacs/user-config ()
  "Configuration for user code:
This function is called at the very end of Spacemacs startup, after layer
configuration.
Put your configuration code here, except for variables that should be set
before packages are loaded."
  (custom/spacemacs-load-user-custom-via-org
   "user-config/native-compile.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/shell-path.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/terminal-clipboard.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/yas-snippets.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/vscode.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/logo-animation.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/mpvi.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/atomic-chrome.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/apple-music.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/tree-sitter.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/copilot.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/xwidget.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/agent-shell-clipboard.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/meson.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/clangd.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/general-gc.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/custom-xwidget.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/jupyter-eval.org")
  (custom/spacemacs-load-user-custom-via-org
   "user-config/remote-tramp.org"))
  ;; origami.el freezes `(face-attribute 'highlight :background)` into its
  ;; origami-fold-header-face defface at load time.  When origami loads
  ;; before the theme applies, that freezes `unspecified` into the :box spec,
  ;; and creating any later frame (e.g. the company completion popup via
  ;; posframe) fails with "Invalid face box".  Re-register the face with a
  ;; concrete spec (see origami.el `defface origami-fold-header-face`).
  (let ((bg (or (face-background 'highlight) "grey70")))
    (custom-set-faces
     `(origami-fold-header-face ((t (:box (:line-width 1 :color ,bg)
                                          :background ,bg))))))
