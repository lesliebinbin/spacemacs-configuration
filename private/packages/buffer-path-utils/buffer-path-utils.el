(defun vscode/buffer-full-path ()
  "Return the full path of the current buffer's file."
  (or (buffer-file-name)))

(defun vscode/buffer-full-lsp-workspace-path ()
  (when (and (bound-and-true-p lsp-mode)
             (fboundp 'lsp-workspace-root)))
  (lsp-workspace-root))

(defun vscode/buffer-project-full-path ()
  "Return the full path of the current buffer's project."
  (when (fboundp 'project-current)
    (let ((project (project-current)))
      (when project
        (car (project-roots project))))))


(provide 'buffer-path-utils)
