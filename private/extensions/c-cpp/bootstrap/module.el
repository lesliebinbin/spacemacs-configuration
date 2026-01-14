(when (and (fboundp 'module-load) module-file-suffix)
  (module-load "/home/basf/.spacemacs.d/private/extensions/c-cpp/bootstrap/build/src/libbootstrap.so")
  (message "Emacs module loaded: bootstrap"))
