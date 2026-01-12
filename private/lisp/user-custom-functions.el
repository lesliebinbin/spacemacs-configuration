(defun custom/spacemacs-banner-simple ()
  (let* ((base-dir (or (and (boundp 'dotspacemacs-directory)
                            dotspacemacs-directory)
                       user-emacs-directory))
         (path (expand-file-name "logos/emacs.jpeg" base-dir)))
    (if (file-exists-p path)
        path
      'official)))

(defun custom/spacemacs-load-user-custom-via-org (file-name)
  (require 'org)
  (when-let* ((base-dir (or (and (boundp 'dotspacemacs-directory)
                                 dotspacemacs-directory)
                            user-emacs-directory))
              (path (expand-file-name file-name base-dir)))
    (org-babel-load-file path)))

(defun custom/font-size-based-on-pixel-width ()
  (let ((frame-width (display-pixel-width)))
    (cond
     ((< frame-width 1600)
     16.0)
     ((< frame-width 2048)
     18.0)
     ((< frame-width 2560)
     20.0)
     ((t 22.0)))))


(defun custom/wsl-p ()
  "Return non-nil if running inside WSL (any version)."
  (and (eq system-type 'gnu/linux)
       (let ((release (ignore-errors (with-temp-buffer
                                       (insert-file-contents "/proc/sys/kernel/osrelease")
                                       (buffer-string)))))
         (and release
              (string-match-p "[Mm]icrosoft" release)))))

(provide 'user-custom-functions)
