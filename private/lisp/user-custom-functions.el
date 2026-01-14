(require 'cl-lib)
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
     ((= frame-width 1920) 14.0)
     ((= frame-width 2560) 18.0)
     (t 22.0))))


(defun custom/wsl-p ()
  "Return non-nil if running inside WSL (any version)."
  (and (eq system-type 'gnu/linux)
       (let ((release (ignore-errors (with-temp-buffer
                                       (insert-file-contents "/proc/sys/kernel/osrelease")
                                       (buffer-string)))))
         (and release
              (string-match-p "[Mm]icrosoft" release)))))

(defun custom/with-pgtk-p ()
  (string-match-p "--with-pgtk" system-configuration-options))



(defun custom/apple-intel-p ()
  (string-match-p "x86_64-apple-darwin" system-configuration))

(defun custom/dynamic-module-p ()
  (and (fboundp 'module-load)
       module-file-suffix))

(cl-defun custom/load-dynamic-module
    (&key (module-name (error "Module name is required"))
          (extension-dir (expand-file-name "lib/c" dotspacemacs-directory))
          (module-file-prefix "libmodule"))
  (when-let* ((extension-suffix (custom/dynamic-module-p))
              (module-path (file-name-concat extension-dir
                                             module-name
                                             (format "%s%s" module-file-prefix extension-suffix))))
    (if (file-exists-p module-path)
        (progn
          (message "Loading dynamic module %s from %s"
                   module-name module-path)
          (module-load module-path))
      (message "Dynamic module %s not found at %s"
               module-name module-path))))


(provide 'user-custom-functions)
