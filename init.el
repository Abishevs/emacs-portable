;;; init.el --- Portable Emacs config -*- lexical-binding: t; -*-
;;; Commentary:
;; Minimal, portable Emacs config with vendored packages.
;; SPC-leader keybindings matching Doom Emacs / Neovim muscle memory.
;; All elisp — no binaries, no network needed.
;; External tools: ripgrep (rg) for consult-ripgrep
;;; Code:

;;;; --- Load Path Setup ---
;; Add all vendored packages to load-path
(let ((vendor-dir (expand-file-name "vendor" user-emacs-directory)))
  (when (file-directory-p vendor-dir)
    (dolist (dir (directory-files vendor-dir t "\\`[^.]"))
      (when (file-directory-p dir)
        (add-to-list 'load-path dir)
        ;; Also add to theme path (for catppuccin etc.)
        (add-to-list 'custom-theme-load-path dir)
        ;; Also add lisp/ subdirectory if it exists (magit convention)
        (let ((lisp-dir (expand-file-name "lisp" dir)))
          (when (file-directory-p lisp-dir)
            (add-to-list 'load-path lisp-dir)))))))

;;;; --- General Settings ---
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror))

;; Basics
(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function #'ignore
      use-short-answers t
      confirm-kill-emacs #'y-or-n-p)

;; Files
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; Better defaults
(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 80)

;; Relative line numbers (like your nvim)
(setq display-line-numbers-type 'relative)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(column-number-mode 1)

;; Scrolloff (like vim scrolloff = 20)
(setq scroll-margin 20
      scroll-conservatively 101)

;; Auto-revert files when changed on disk
(global-auto-revert-mode 1)

;; Remember recent files
(recentf-mode 1)
(setq recentf-max-saved-items 100)

;; Save minibuffer history
(savehist-mode 1)

;; Highlight matching parens
(show-paren-mode 1)

;; Electric pairs
(electric-pair-mode 1)

;; UTF-8 everywhere
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;;;; --- Theme (Catppuccin Macchiato) ---
(setq catppuccin-flavor 'macchiato)
(require 'catppuccin-theme)
(load-theme 'catppuccin t)

;;;; --- Evil Mode (Vim keybindings) ---
(setq evil-want-integration t
      evil-want-keybinding t
      evil-want-C-u-scroll t
      evil-want-C-i-jump nil           ; don't steal TAB for jump-forward
      evil-undo-system 'undo-redo)
(require 'evil)
(evil-mode 1)

;; jk to escape insert mode (like many vim configs)
(define-key evil-insert-state-map (kbd "j")
  (lambda ()
    (interactive)
    (let ((next-char (read-event nil nil 0.15)))
      (if (eq next-char ?k)
          (evil-normal-state)
        (insert "j")
        (when next-char
          (push next-char unread-command-events))))))

;; C-g also escapes
(define-key evil-insert-state-map (kbd "C-g") #'evil-normal-state)

;; Keep Emacs bindings in special modes
(dolist (mode '(custom-mode
               eshell-mode
               term-mode))
  (add-to-list 'evil-emacs-state-modes mode))

;; Make magit use evil motion state (j/k work, but magit keys preserved)
(dolist (mode '(magit-status-mode
               magit-log-mode
               magit-diff-mode
               magit-refs-mode
               magit-stash-mode
               magit-stashes-mode
               magit-cherry-mode
               magit-reflog-mode
               magit-process-mode
               magit-revision-mode
               magit-log-select-mode))
  (evil-set-initial-state mode 'motion))

;; Magit keybindings that work in motion state
(with-eval-after-load 'magit
  (evil-define-key 'motion magit-mode-map
    "j" #'magit-next-line
    "k" #'magit-previous-line
    (kbd "RET") #'magit-visit-thing
    (kbd "TAB") #'magit-section-toggle
    "q" #'magit-mode-bury-buffer
    "gr" #'magit-refresh
    "s" #'magit-stage
    "S" #'magit-stage-modified
    "u" #'magit-unstage
    "U" #'magit-unstage-all
    "c" #'magit-commit
    "p" #'magit-push
    "F" #'magit-pull
    "b" #'magit-branch
    "l" #'magit-log
    "d" #'magit-diff
    "z" #'magit-stash
    "x" #'magit-discard
    "?" #'magit-dispatch))

;;;; --- General.el (SPC leader key system) ---
(require 'general)

;; Define SPC as leader in normal/visual/motion states (like Doom)
(general-create-definer my/leader-def
  :states '(normal visual motion)
  :keymaps 'override
  :prefix "SPC")

;; Define , as local leader (like Doom's SPC m)
(general-create-definer my/local-leader-def
  :states '(normal visual motion)
  :keymaps 'override
  :prefix ",")

;;;; --- Which-Key ---
(require 'which-key)
(which-key-mode 1)
(setq which-key-idle-delay 0.3
      which-key-separator " → ")

;;;; --- Vertico (vertical completion UI) ---
(require 'vertico)
(vertico-mode 1)
(setq vertico-cycle t
      vertico-count 15)

;; Navigate vertico candidates with C-j/C-k (works in insert state)
(define-key vertico-map (kbd "C-j") #'vertico-next)
(define-key vertico-map (kbd "C-k") #'vertico-previous)
(define-key vertico-map (kbd "C-n") #'vertico-next)
(define-key vertico-map (kbd "C-p") #'vertico-previous)
(define-key vertico-map (kbd "M-j") #'vertico-next)
(define-key vertico-map (kbd "M-k") #'vertico-previous)

;;;; --- Orderless (flexible matching) ---
(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion))))

;;;; --- Consult (search, navigation, ripgrep) ---
(require 'consult)

;; Use project.el as project backend
(setq consult-project-function
      (lambda (_)
        (when-let ((project (project-current)))
          (car (project-roots project)))))

;;;; --- Magit ---
(require 'magit)

;;;; --- Markdown ---
(require 'markdown-mode)
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(setq markdown-command "none"
      markdown-fontify-code-blocks-natively t)

;;;; =========================================================
;;;; --- SPC Leader Keybindings (Doom/Nvim style) ---
;;;; =========================================================

(my/leader-def
  ;; Top-level quick access
  "SPC" '(execute-extended-command :wk "M-x")  ; SPC SPC = command palette
  "."   '(find-file :wk "Find file")
  ":"   '(eval-expression :wk "Eval expression")
  "x"   '(scratch-buffer :wk "Scratch buffer")
  "X"   '(org-capture :wk "Org capture")

  ;; --- File ---
  "f"   '(:ignore t :wk "file")
  "ff"  '(find-file :wk "Find file")
  "fr"  '(consult-recent-file :wk "Recent files")
  "fs"  '(save-buffer :wk "Save file")
  "fS"  '(write-file :wk "Save as...")
  "fp"  '((lambda () (interactive)
             (find-file user-emacs-directory)) :wk "Open config dir")

  ;; --- Buffer ---
  "b"   '(:ignore t :wk "buffer")
  "bb"  '(consult-buffer :wk "Switch buffer")
  "bd"  '(kill-current-buffer :wk "Kill buffer")
  "bk"  '(kill-current-buffer :wk "Kill buffer")
  "bn"  '(next-buffer :wk "Next buffer")
  "bp"  '(previous-buffer :wk "Previous buffer")
  "br"  '(revert-buffer :wk "Revert buffer")
  "bs"  '(save-buffer :wk "Save buffer")

  ;; --- Search (ripgrep, grep, line) ---
  "s"   '(:ignore t :wk "search")
  "ss"  '(consult-line :wk "Search in buffer")
  "sp"  '(consult-ripgrep :wk "Ripgrep project")
  "sf"  '(consult-find :wk "Find file in project")
  "sg"  '(consult-grep :wk "Grep")
  "si"  '(consult-imenu :wk "Imenu symbols")
  "sl"  '(consult-line :wk "Search lines")

  ;; --- Project ---
  "p"   '(:ignore t :wk "project")
  "pp"  '(project-switch-project :wk "Switch project")
  "pf"  '(project-find-file :wk "Find file in project")
  "ps"  '(consult-ripgrep :wk "Search in project")
  "pb"  '(project-switch-to-buffer :wk "Project buffers")
  "pd"  '(project-dired :wk "Project dired")
  "pe"  '(project-eshell :wk "Project eshell")

  ;; --- Git (Magit) ---
  "g"   '(:ignore t :wk "git")
  "gg"  '(magit-status :wk "Magit status")
  "gb"  '(magit-blame :wk "Blame")
  "gl"  '(magit-log-current :wk "Log current")
  "gd"  '(magit-diff-dwim :wk "Diff")
  "gf"  '(magit-fetch :wk "Fetch")
  "gp"  '(magit-push :wk "Push")

  ;; --- Window ---
  "w"   '(:ignore t :wk "window")
  "wv"  '(evil-window-vsplit :wk "Vertical split")
  "ws"  '(evil-window-split :wk "Horizontal split")
  "wd"  '(evil-window-delete :wk "Close window")
  "ww"  '(other-window :wk "Other window")
  "wh"  '(evil-window-left :wk "Window left")
  "wj"  '(evil-window-down :wk "Window down")
  "wk"  '(evil-window-up :wk "Window up")
  "wl"  '(evil-window-right :wk "Window right")
  "w="  '(balance-windows :wk "Balance windows")

  ;; --- Org ---
  "o"   '(:ignore t :wk "org")
  "oa"  '(org-agenda :wk "Agenda")
  "oc"  '(org-capture :wk "Capture")
  "ol"  '(org-store-link :wk "Store link")

  ;; --- Code / LSP ---
  "c"   '(:ignore t :wk "code")
  "cd"  '(xref-find-definitions :wk "Go to definition")
  "cr"  '(xref-find-references :wk "Find references")
  "cR"  '(eglot-rename :wk "Rename")
  "ca"  '(eglot-code-actions :wk "Code actions")
  "cf"  '(eglot-format :wk "Format")
  "cl"  '(eglot :wk "Start LSP")

  ;; --- Toggle ---
  "t"   '(:ignore t :wk "toggle")
  "tl"  '(display-line-numbers-mode :wk "Line numbers")
  "tw"  '(whitespace-mode :wk "Whitespace")
  "tt"  '(consult-theme :wk "Theme")

  ;; --- Help ---
  "h"   '(:ignore t :wk "help")
  "hf"  '(describe-function :wk "Describe function")
  "hv"  '(describe-variable :wk "Describe variable")
  "hk"  '(describe-key :wk "Describe key")
  "hm"  '(describe-mode :wk "Describe mode")

  ;; --- Quit ---
  "q"   '(:ignore t :wk "quit")
  "qq"  '(save-buffers-kill-terminal :wk "Quit Emacs")
  "qQ"  '(kill-emacs :wk "Quit without saving")

  ;; --- Yank (clipboard) ---
  "y"   '(clipboard-yank :wk "Paste from clipboard")
  "Y"   '((lambda () (interactive)
             (clipboard-kill-ring-save (point) (mark))) :wk "Copy to clipboard"))

;; --- Normal state g-prefixed (Vim muscle memory) ---
(general-define-key
 :states '(normal)
 :keymaps 'override
 "gd" #'xref-find-definitions      ; go to definition
 "gr" #'xref-find-references       ; go to references
 "K"  #'eldoc                       ; hover / docs (like vim K)
 "gcc" #'comment-line)              ; comment line (like vim-commentary)

;; Visual mode comment
(general-define-key
 :states '(visual)
 :keymaps 'override
 "gc" #'comment-dwim)

;; --- Escape quits minibuffers and popups (Doom behavior) ---
;; Don't override [escape] globally — that breaks evil's ESC in insert mode.
;; Only catch ESC in specific non-evil contexts.
(define-key minibuffer-local-map [escape] #'abort-minibuffers)
(define-key minibuffer-local-ns-map [escape] #'abort-minibuffers)
(define-key minibuffer-local-completion-map [escape] #'abort-minibuffers)

;; ESC in normal state quits popups/prompts
(general-define-key
 :states '(normal)
 :keymaps 'override
 "<escape>" #'keyboard-quit)

;;;; --- Org Mode (built-in, just configure) ---
(setq org-directory "~/org"
      org-default-notes-file "~/org/inbox.org"
      org-startup-indented t
      org-hide-leading-stars t
      org-return-follows-link t
      org-src-fontify-natively t
      org-src-tab-acts-natively t
      org-confirm-babel-evaluate nil
      org-agenda-files '("~/org"))

(setq org-capture-templates
      '(("t" "Todo" entry (file+headline "~/org/inbox.org" "Tasks")
         "* TODO %?\n  %i\n  %a")
        ("n" "Note" entry (file+headline "~/org/inbox.org" "Notes")
         "* %? :note:\n  %i\n  %a")))

;; Evil keybindings for org-mode
(with-eval-after-load 'org
  (evil-define-key 'normal org-mode-map
    [tab]         #'org-cycle              ; GUI tab key
    (kbd "TAB")   #'org-cycle              ; terminal TAB
    [backtab]     #'org-shifttab           ; S-TAB (GUI)
    (kbd "S-TAB") #'org-shifttab           ; S-TAB (terminal)
    (kbd "RET")   #'org-return             ; follow links / newline
    [return]      #'org-return             ; GUI return
    "zo"          #'org-show-subtree       ; vim-style open fold
    "zc"          #'org-hide-subtree       ; vim-style close fold
    "za"          #'org-cycle              ; vim-style toggle fold
    "zM"          #'org-content            ; close all folds
    "zR"          #'org-show-all           ; open all folds
    "t"           #'org-todo               ; cycle TODO state
    "H"           #'org-shiftleft          ; demote / prev TODO
    "L"           #'org-shiftright         ; promote / next TODO
    "J"           #'org-move-subtree-down  ; move heading down
    "K"           #'org-move-subtree-up)   ; move heading up

  ;; Insert state — TAB should indent/cycle in src blocks
  (evil-define-key 'insert org-mode-map
    [tab]       #'org-cycle
    (kbd "TAB") #'org-cycle))

;;;; --- Dired ---
(setq dired-listing-switches "-alh --group-directories-first"
      dired-dwim-target t)

;;;; --- Eglot (LSP, built-in Emacs 29+) ---
(when (require 'eglot nil t)
  ;; Python — pyright
  ;; Install: pip install --user pyright
  (add-hook 'python-mode-hook #'eglot-ensure)

  ;; SystemVerilog — DVT Eclipse LSP
  (defvar dvt-lsp-command '("dvt_cli" "lsp")
    "Command to start DVT LSP server for SystemVerilog.
Adjust path if dvt_cli is not in PATH, e.g.:
  '(\"/opt/dvt/bin/dvt_cli\" \"lsp\")")

  (add-to-list 'eglot-server-programs
               `((verilog-mode) . ,dvt-lsp-command))

  ;; Uncomment to auto-start LSP for SV files:
  ;; (add-hook 'verilog-mode-hook #'eglot-ensure)
  )

;;;; --- Python ---
(setq python-shell-virtualenv-root nil)
;; Pyright auto-detects .venv/ in project root, or set pyrightconfig.json

;;;; --- SystemVerilog / Verilog ---
(setq verilog-auto-newline nil
      verilog-auto-indent-on-newline t
      verilog-indent-level 2
      verilog-indent-level-module 2
      verilog-indent-level-declaration 2
      verilog-indent-level-behavioral 2
      verilog-case-indent 2)

(add-to-list 'auto-mode-alist '("\\.sv\\'" . verilog-mode))
(add-to-list 'auto-mode-alist '("\\.svh\\'" . verilog-mode))

;;;; --- Project.el (built-in project management) ---
(setq project-vc-extra-root-markers '(".project" ".projectile" "Makefile"))

;;; init.el ends here
