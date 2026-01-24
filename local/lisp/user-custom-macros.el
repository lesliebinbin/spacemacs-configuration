(defmacro osx/with-app (app &rest actions)
  "Execute AppleScript for APP with ACTIONS (symbols, strings, or variables)."
  `(if (and (fboundp 'spacemacs/system-is-mac) (spacemacs/system-is-mac))
       (let* ((app-name ,app)
              ;; Evaluate the actions so variables are resolved to their values
              (evaluated-actions (list ,@actions))
              (action-list (mapcar (lambda (act)
                                     (cond ((symbolp act) (symbol-name act))
                                           ((stringp act) act)
                                           (t (format "%s" act))))
                                   evaluated-actions))
              (script (mapconcat (lambda (act)
                                   (format "tell application \"%s\" to %s" app-name act))
                                 action-list "\n")))
         (shell-command-to-string (format "osascript -e %s" (shell-quote-argument script))))
     (message "AppleScript commands are only supported on macOS.")))

(provide 'user-custom-macros)
