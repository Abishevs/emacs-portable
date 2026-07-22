;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-
;;; Commentary:
;; Runs before init.el. Disables package.el (we vendor everything)
;; and removes UI clutter for faster startup.
;;; Code:

;; Disable package.el — we manage packages manually
(setq package-enable-at-startup nil)

;; Disable native (JIT) compilation if libgccjit is not available
;; Emacs still works fine interpreted — native-comp is just an optimization
(when (featurep 'native-compile)
  (setq native-comp-jit-compilation nil
        native-comp-async-report-warnings-errors nil))

;; Prevent the glimpse of un-styled Emacs
(setq inhibit-redisplay t
      inhibit-message t)
(add-hook 'window-setup-hook
          (lambda ()
            (setq inhibit-redisplay nil
                  inhibit-message nil)
            (redisplay)))

;; UI clutter removal (before frame is drawn)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq frame-inhibit-implied-resize t)

;; Faster startup: increase GC threshold during init
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Reset GC after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)  ; 16MB
                  gc-cons-percentage 0.1)))

;;; early-init.el ends here
