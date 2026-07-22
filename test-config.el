;;; test-config.el --- Tests for emacs-portable -*- lexical-binding: t; -*-
;;; Commentary:
;; Run with: emacs --batch -l early-init.el -l init.el -l test-config.el
;; Exit code 0 = all pass, 1 = failure
;;; Code:

(defvar test-failures nil "List of failed test names.")
(defvar test-passes 0 "Count of passed tests.")

(defmacro test-assert (name condition)
  "Assert CONDITION is true, report NAME on failure."
  `(if ,condition
       (progn
         (princ (format "  PASS: %s\n" ,name))
         (setq test-passes (1+ test-passes)))
     (princ (format "  FAIL: %s\n" ,name))
     (push ,name test-failures)))

;;; --- Package Loading ---
(princ "=== Package Loading ===\n")
(test-assert "evil loaded" (featurep 'evil))
(test-assert "general loaded" (featurep 'general))
(test-assert "which-key loaded" (featurep 'which-key))
(test-assert "vertico loaded" (featurep 'vertico))
(test-assert "consult loaded" (featurep 'consult))
(test-assert "orderless loaded" (featurep 'orderless))
(test-assert "magit loaded" (featurep 'magit))
(test-assert "transient loaded" (featurep 'transient))
(test-assert "markdown-mode loaded" (featurep 'markdown-mode))

;;; --- Evil Mode ---
(princ "\n=== Evil Mode ===\n")
(test-assert "evil-mode is active" evil-mode)
(test-assert "default state is normal" (eq evil-default-state 'normal))
(test-assert "C-u scrolls (evil-want-C-u-scroll)" evil-want-C-u-scroll)
(test-assert "undo system is undo-redo" (eq evil-undo-system 'undo-redo))

;; Check ESC works in insert state
(test-assert "ESC exits insert mode"
             (eq (lookup-key evil-insert-state-map [escape]) 'evil-normal-state))

;; Check jk escape is set up (j in insert map is a lambda)
(test-assert "jk escape configured"
             (functionp (lookup-key evil-insert-state-map (kbd "j"))))

;;; --- SPC Leader (General.el) ---
(princ "\n=== SPC Leader Keybindings ===\n")

;; Verify the leader definer was set up
(test-assert "my/leader-def is defined" (fboundp 'my/leader-def))
(test-assert "my/local-leader-def is defined" (fboundp 'my/local-leader-def))

;; Verify key commands exist and are callable
(test-assert "find-file is a command" (commandp 'find-file))
(test-assert "consult-ripgrep is a command" (commandp 'consult-ripgrep))
(test-assert "magit-status is a command" (commandp 'magit-status))
(test-assert "consult-buffer is a command" (commandp 'consult-buffer))
(test-assert "evil-window-vsplit is a command" (commandp 'evil-window-vsplit))
(test-assert "consult-recent-file is a command" (commandp 'consult-recent-file))
(test-assert "consult-find is a command" (commandp 'consult-find))
(test-assert "project-find-file is a command" (commandp 'project-find-file))

;;; --- Normal Mode Keybindings ---
(princ "\n=== Normal Mode Keys ===\n")

;; General puts override keys in an auxiliary keymap for normal state
(let ((aux-map (evil-get-auxiliary-keymap general-override-mode-map 'normal)))
  (test-assert "gd → xref-find-definitions"
               (eq (lookup-key aux-map (kbd "gd")) 'xref-find-definitions))
  (test-assert "gr → xref-find-references"
               (eq (lookup-key aux-map (kbd "gr")) 'xref-find-references))
  (test-assert "K → eldoc"
               (eq (lookup-key aux-map (kbd "K")) 'eldoc))
  (test-assert "gcc → comment-line"
               (eq (lookup-key aux-map (kbd "gcc")) 'comment-line)))

;;; --- Magit Evil Integration ---
(princ "\n=== Magit Evil Integration ===\n")
(test-assert "magit-status uses motion state"
             (eq (evil-initial-state 'magit-status-mode) 'motion))
(test-assert "magit-log uses motion state"
             (eq (evil-initial-state 'magit-log-mode) 'motion))
(test-assert "magit-diff uses motion state"
             (eq (evil-initial-state 'magit-diff-mode) 'motion))

;;; --- Vertico ---
(princ "\n=== Vertico ===\n")
(test-assert "vertico-mode is active" (bound-and-true-p vertico-mode))
(test-assert "C-j navigates next"
             (eq (lookup-key vertico-map (kbd "C-j")) 'vertico-next))
(test-assert "C-k navigates previous"
             (eq (lookup-key vertico-map (kbd "C-k")) 'vertico-previous))

;;; --- Orderless ---
(princ "\n=== Orderless ===\n")
(test-assert "orderless in completion-styles"
             (memq 'orderless completion-styles))

;;; --- Eglot (LSP) ---
(princ "\n=== Eglot ===\n")
(test-assert "eglot available" (featurep 'eglot))
(test-assert "python-mode has eglot hook"
             (memq 'eglot-ensure (default-value 'python-mode-hook)))

;;; --- General Settings ---
(princ "\n=== Settings ===\n")
(test-assert "relative line numbers"
             (eq display-line-numbers-type 'relative))
(test-assert "scroll-margin is 20" (= scroll-margin 20))
(test-assert "no backup files" (null make-backup-files))
(test-assert "no auto-save" (null auto-save-default))
(test-assert "indent with spaces" (null (default-value 'indent-tabs-mode)))

;;; --- Verilog Mode ---
(princ "\n=== Verilog ===\n")
(test-assert "verilog-mode available" (locate-library "verilog-mode"))
(test-assert ".sv associated with verilog-mode"
             (eq (cdr (assoc "\\.sv\\'" auto-mode-alist)) 'verilog-mode))
(test-assert ".svh associated with verilog-mode"
             (eq (cdr (assoc "\\.svh\\'" auto-mode-alist)) 'verilog-mode))

;;; --- Markdown ---
(princ "\n=== Markdown ===\n")
(test-assert ".md associated with markdown-mode"
             (eq (cdr (assoc "\\.md\\'" auto-mode-alist)) 'markdown-mode))

;;; --- Results ---
(princ (format "\n=== Results: %d passed, %d failed ===\n"
               test-passes (length test-failures)))

(when test-failures
  (princ "\nFailed tests:\n")
  (dolist (f (reverse test-failures))
    (princ (format "  ✗ %s\n" f))))

(kill-emacs (if test-failures 1 0))

;;; test-config.el ends here
