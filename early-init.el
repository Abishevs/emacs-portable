;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-
;;; Commentary:
;; Runs before init.el. Disables package.el (we vendor everything)
;; and removes UI clutter for faster startup.
;;; Code:

;; Disable native (JIT) compilation FIRST — before anything else loads.
;; Without libgccjit, native-comp errors cascade and break the entire config.
(setq native-comp-jit-compilation nil
      native-comp-async-report-warnings-errors nil
      comp-deferred-compilation nil)

;; Suppress any native-comp warnings that slip through
(setq native-comp-async-report-warnings-errors 'silent)

;; Disable trampolines compilation (Emacs 29+)
(setq native-comp-deferred-compilation nil)

;; Point eln-cache to /dev/null so nothing gets written/read
(when (boundp 'native-comp-eln-load-path)
  (setcar native-comp-eln-load-path (expand-file-name "eln-cache" temporary-file-directory)))

;; Disable package.el — we manage packages manually
(setq package-enable-at-startup nil)

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
