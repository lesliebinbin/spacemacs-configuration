;; -*- mode: emacs-lisp; lexical-binding: t -*-
;;; packages.el --- agent-shell layer packages file for Spacemacs

(defconst agent-shell-packages
  '(
    (shell-maker :location (recipe :fetcher github :repo "xenodium/shell-maker"))
    (acp         :location (recipe :fetcher github :repo "xenodium/acp.el"))
    (agent-shell :location (recipe :fetcher github :repo "lesliebinbin/agent-shell"))
    ))

(defun agent-shell/init-shell-maker ()
  (use-package shell-maker
    :demand t))

(defun agent-shell/init-acp ()
  (use-package acp
    :demand t))


(defun agent-shell/init-agent-shell ()
  (use-package agent-shell
    :defer t
    :after (shell-maker acp)
    :init
    (spacemacs/set-leader-keys "as" 'agent-shell)
    :config
    )
  )
