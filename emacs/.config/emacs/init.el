;;; init.el --- Main configuration -*- lexical-binding: t -*-

;; Bootstrap Elpaca
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package integration
(setq use-package-enable-imenu-support t)
(elpaca elpaca-use-package
  (elpaca-use-package-mode))
(setq use-package-always-ensure t)
(use-package use-package-core
  :ensure nil
  :custom (use-package-always-defer t))

(use-package gcmh
  :init (gcmh-mode t))

(use-package cus-edit
  :ensure nil
  :custom (custom-file null-device))

;; transparent titlebar synced to current theme (GUI only)
(when (display-graphic-p)
  (use-package ns-auto-titlebar
    :hook (elpaca-after-init . ns-auto-titlebar-mode)))

(defun keyboard-quit-dwim ()
  "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.
- When a minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the regular `keyboard-quit'."
  (interactive)
  (cond
   ((region-active-p)
    (keyboard-quit))
   ((derived-mode-p 'completion-list-mode)
    (delete-completion-window))
   ((> (minibuffer-depth) 0)
    (abort-recursive-edit))
   (t
    (keyboard-quit))))

(define-key (current-global-map) [remap keyboard-quit] 'keyboard-quit-dwim)

;; Keep emacs directory clean
(use-package no-littering
  :demand t
  :init
  (setq no-littering-etc-directory
      (expand-file-name "~/.local/share/emacs/"))
  (setq no-littering-var-directory
      (expand-file-name "~/.local/state/emacs/"))
  :config (no-littering-theme-backups))

;; Exclude all files in no-littering directories from recentf
(use-package recentf
  :ensure nil
  :config
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-var-directory))
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-etc-directory))
  :hook (elpaca-after-init . recentf-mode))

(use-package savehist
  :ensure nil
  :hook (elpaca-after-init . savehist-mode))

;; Disable initial splash screen
(use-package startup
  :ensure nil
  :preface (defun display-startup-echo-area-message ()
             (message nil))
  :custom
  (inhibit-startup-screen t)
  (initial-scratch-message nil)
  (initial-major-mode 'fundamental-mode))

;; Configure stuff that's present in native code
(use-package emacs
  :ensure nil
  :config
  (fset 'yes-or-no-p 'y-or-n-p)
  :custom
  (ring-bell-function 'ignore)
  (completion-cycle-threshold 1)
  (tab-always-indent 'complete)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (vc-follow-symlinks t)
  (vc-make-backup-files nil))

(use-package epg-config
  :ensure nil
  :custom (epg-pinentry-mode 'loopback))

(use-package jka-cmpr-hook
  :ensure nil
  :hook (elpaca-after-init . auto-compression-mode))

;; set fringe-mode to minimal
(use-package fringe
  :ensure nil
  :config
  (set-fringe-mode '(1 . 1)))

(use-package display-line-numbers
  :ensure nil
  :custom (display-line-numbers-width-start t)
  :hook (elpaca-after-init . global-display-line-numbers-mode))

;; Enable syntax highlighting globally
(use-package font-lock
  :ensure nil
  :config (global-font-lock-mode 1))

;; Allow loading themes without confirmation
(use-package custom
  :ensure nil
  :custom (custom-safe-themes t))

;; install prot's amazing ef-themes packages
(use-package ef-themes
  :demand t
  :config
  ;; set light and dark themes
  (setq light-theme 'ef-frost)
  (setq dark-theme 'ef-owl)

  ;; apply theme based on the system appearance
  (defun apply-theme (appearance)
    (mapc #'disable-theme custom-enabled-themes)
    (pcase appearance
      ('light (load-theme light-theme t))
      ('dark (load-theme dark-theme t))))

  ;; GUI: auto-switch based on macOS system appearance
  (when (display-graphic-p)
    (add-hook 'ns-system-appearance-change-functions #'apply-theme))

  ;; Terminal: detect system appearance on startup
  (unless (display-graphic-p)
    (let* ((output (shell-command-to-string "defaults read -g AppleInterfaceStyle 2>/dev/null"))
           (is-dark (string-match-p "Dark" output)))
      (if is-dark
          (load-theme dark-theme t)
        (load-theme light-theme t)))))

(use-package ligature
  :ensure (ligature
           :host github
           :repo "mickeynp/ligature.el")
  :init (global-ligature-mode)
  :config
  (global-ligature-mode)
  (ligature-set-ligatures
   'prog-mode '("-|" "-~" "---" "-<<" "-<" "--" "->" "->>" "-->" "///" "/=" "/=="
                "/>" "//" "/*" "*>" "***" "*/" "<-" "<<-" "<=>" "<=" "<|" "<||"
                "<|||" "<|>" "<:" "<>" "<-<" "<<<" "<==" "<<=" "<=<" "<==>" "<-|"
                "<<" "<~>" "<=|" "<~~" "<~" "<$>" "<$" "<+>" "<+" "</>" "</" "<*"
                "<*>" "<->" "<!--" ":>" ":<" ":::" "::" ":?" ":?>" ":=" "::=" "=>>"
                "==>" "=/=" "=!=" "=>" "===" "=:=" "==" "!==" "!!" "!=" ">]" ">:"
                ">>-" ">>=" ">=>" ">>>" ">-" ">=" "&&&" "&&" "|||>" "||>" "|>" "|]"
                "|}" "|=>" "|->" "|=" "||-" "|-" "||=" "||" ".." ".?" ".=" ".-" "..<"
                "..." "+++" "+>" "++" "[||]" "[<" "[|" "{|" "??" "?." "?=" "?:" "##"
                "###" "####" "#[" "#{" "#=" "#!" "#:" "#_(" "#_" "#?" "#(" ";;" "_|_"
                "__" "~~" "~~>" "~>" "~-" "~@" "$>" "^=" "]#")))

(use-package mood-line
  :hook (elpaca-after-init . mood-line-mode))

(use-package which-key
  :hook (elpaca-after-init . which-key-mode)
  :custom (which-key-show-transient-maps t)
  :config (which-key-setup-side-window-bottom))

(use-package helpful
  :bind
  (:map help-map
        ("f" . helpful-callable)
        ("v" . helpful-variable)
        ("k" . helpful-key)
        ("x" . helpful-command))
  (:map mode-specific-map
        ("C-d" . helpful-at-point)))

;; keep the buffer up-to-date
(use-package autorevert
  :ensure nil
  :hook (elpaca-after-init . global-auto-revert-mode))

;; smooth scrolling
(use-package ultra-scroll
  :ensure (ultra-scroll
           :host github
           :repo "jdtsmith/ultra-scroll")
  :custom
  (scroll-conservatively 101)
  (scroll-margin 0)
  :config (ultra-scroll-mode 1))

(use-package clipetty
  :if (and (not (display-graphic-p))
           (not (eq system-type 'darwin)))
  :hook (after-init . global-clipetty-mode))

(defun am/setup-terminal-clipboard (&optional frame)
  "Configure reliable clipboard integration for terminal FRAME."
  (unless (display-graphic-p frame)
    ;; Enable mouse support in terminal
    (xterm-mouse-mode 1)
    (global-set-key (kbd "<mouse-4>") 'scroll-down-line)
    (global-set-key (kbd "<mouse-5>") 'scroll-up-line)

    ;; Better terminal colors
    (setq xterm-set-window-title t)

    ;; Clipboard integration
    (setq select-enable-clipboard t
          select-enable-primary t
          save-interprogram-paste-before-kill t)

    ;; On macOS terminals, use system clipboard commands directly.
    ;; This is more reliable than terminal escape-sequence clipboard bridges.
    (when (and (eq system-type 'darwin)
               (executable-find "pbcopy")
               (executable-find "pbpaste"))
      (setq interprogram-cut-function
            (lambda (text &optional _push)
              (let ((process-connection-type nil))
                (let ((proc (start-process "pbcopy" nil "pbcopy")))
                  (process-send-string proc text)
                  (process-send-eof proc))))
            interprogram-paste-function
            (lambda ()
              (string-trim-right (shell-command-to-string "pbpaste")))))))

(defun am/pbcopy-on-kill-new (text &rest _)
  "Mirror killed TEXT to macOS clipboard in terminal Emacs."
  (when (and (not (display-graphic-p))
             (eq system-type 'darwin)
             (stringp text)
             (executable-find "pbcopy"))
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" nil "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc)))))

(defun am/pbpaste-string ()
  "Return current macOS clipboard text, or nil if unavailable."
  (when (and (not (display-graphic-p))
             (eq system-type 'darwin)
             (executable-find "pbpaste"))
    (string-trim-right (shell-command-to-string "pbpaste"))))

(defun am/sync-kill-ring-from-pbpaste (&rest _)
  "Sync kill-ring with macOS clipboard before paste commands."
  (let ((clip (am/pbpaste-string)))
    (when (and (stringp clip)
               (not (string-empty-p clip)))
      (kill-new clip))))

;; Apply once at startup and again for any new terminal frames (daemon/client).
(add-hook 'after-init-hook #'am/setup-terminal-clipboard)
(add-hook 'after-make-frame-functions #'am/setup-terminal-clipboard)
(advice-add 'kill-new :after #'am/pbcopy-on-kill-new)
(advice-add 'yank :before #'am/sync-kill-ring-from-pbpaste)
(advice-add 'yank-pop :before #'am/sync-kill-ring-from-pbpaste)

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package consult
  :init
  (advice-add #'completing-read-multiple :override #'consult-completing-read-multiple)
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :bind
  ([remap isearch-forward] . consult-line)
  ([remap yank-pop] . consult-yank-pop)
  (:map mode-specific-map
        ("h" . consult-history))
  (:map ctl-x-map
        ("b" . consult-buffer)
        ("4 b" . consult-buffer-other-window)
        ("5 b" . consult-buffer-other-frame)
        ("p b" . consult-project-buffer))
  (:map goto-map
        ("i" . consult-imenu)
        ("b" . consult-buffer)
        ("g" . consult-goto-line)
        ("o" . consult-outline)
        ("m" . consult-mark))
  (:map search-map
        ("s" . consult-ripgrep)))

(use-package consult-dir
  :after consult
  :bind
  (:map ctl-x-map
        ("C-d" . consult-dir))
  (:map vertico-map
        ("C-x C-d" . consult-dir)
        ("C-x C-j" . consult-dir-jump-file)))

(use-package consult-project-extra
  :after consult
  :bind
  ([remap project-find-file] . consult-project-extra-find)
  (:map project-prefix-map
        ("4 f" . consult-project-extra-find-other-window)))

(use-package vertico
  :ensure (:files (:defaults "extensions/*")
                  :includes (vertico-indexed
                             vertico-multiform))
  :custom
  (vertico-resize t)
  (vertico-count 10)
  (vertico-multiform-categories '((t indexed)))
  (vertico-multiform-commands '((consult-flymake)
                                (consult-line)
                                (consult-ripgrep)
                                (consult-lsp-diagnostics)
                                (consult-yank-pop indexed)
                                (project-find-regexp)
                                (xref-find-definitions)
                                (xref-find-references)))
  :hook (elpaca-after-init . vertico-mode)
  :config
  (vertico-multiform-mode))

;; Company mode for auto-completion (better terminal support)
(use-package company
  :custom
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 2)
  (company-selection-wrap-around t)
  (company-show-quick-access t)
  (company-tooltip-align-annotations t)
  :init (global-company-mode)
  :bind (:map company-active-map
              ("C-n" . company-select-next)
              ("C-p" . company-select-previous)
              ("<tab>" . company-complete-selection)))

(use-package marginalia
  :hook (elpaca-after-init . marginalia-mode)
  :custom
  (marginalia-max-relative-age 0)
  (marginalia-align 'right)
  (marginalia-annotators
   '(marginalia-annotators-heavy marginalia-annotators-light nil)))

;; Company backends for additional completions
(use-package company
  :ensure nil
  :config
  ;; Enable company in all programming modes
  (add-hook 'prog-mode-hook #'company-mode)
  ;; Add file completion backend
  (add-to-list 'company-backends 'company-files))

(use-package yasnippet
  :hook (prog-mode . yas-minor-mode)
  :config
  (yas-reload-all))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package eldoc-box
  :bind ("C-c l h" . eldoc-box-help-at-point)
  :custom
  (eldoc-box-max-pixel-width 800)
  (eldoc-box-max-pixel-height 600))

;; Quick error navigation with consult
(with-eval-after-load 'consult
  (global-set-key (kbd "C-c ! l") #'consult-flymake))

;; Quick error navigation keybindings
(with-eval-after-load 'flymake
  (define-key flymake-mode-map (kbd "C-c ! n") #'flymake-goto-next-error)
  (define-key flymake-mode-map (kbd "C-c ! p") #'flymake-goto-prev-error))

(use-package expand-region
   :bind
   ("C-=" . er/expand-region)
   ("C-_" . er/contract-region))

(use-package vundo
  :custom
  (vundo-compact-display nil)
  (vundo-glyph-alist vundo-unicode-symbols))

 ;; save cursor postion
 (use-package saveplace
   :ensure nil
   :hook (elpaca-after-init . save-place-mode))

 (use-package whitespace
   :ensure nil
   :hook (before-save . whitespace-cleanup))

 ;; Replace active region with what I type
 (use-package delsel
   :ensure nil
   :hook (elpaca-after-init . delete-selection-mode))

 (use-package whole-line-or-region
   :config (whole-line-or-region-global-mode t))

 (use-package diff-hl
   :hook
   (prog-mode . diff-hl-margin-mode)
   (magit-post-refresh . diff-hl-magit-post-refresh))

 (use-package indent
   :ensure nil
   :custom (standard-indent 2))

 (use-package mwim
   :bind (([remap move-beginning-of-line] . mwim-beginning)
          ([remap move-end-of-line] . mwim-end)))

 (use-package goto-last-change
   :bind ("C-z" . goto-last-change))

 (use-package elec-pair
   :ensure nil
   :hook (elpaca-after-init . electric-pair-mode))

 (use-package move-text
   :demand t
   :init (move-text-default-bindings))

 (use-package paren
   :ensure nil
   :hook (prog-mode . show-paren-mode))

 (use-package subword
   :ensure nil
   :hook (prog-mode . subword-mode))

 (use-package hl-line
   :ensure nil
   :hook (prog-mode . hl-line-mode))

 (use-package smart-comment
   :bind (:map esc-map (";" . smart-comment)))

 (use-package hide-comnt
   :ensure (hide-comnt
            :host github
            :repo "emacsmirror/hide-comnt"))

 (use-package newcomment
   :ensure nil
   :custom
   (fill-column 80)
   (comment-auto-fill-only-comments 1)
   (auto-fill-function 'do-auto-fill))

 (use-package dumb-jump
   :init (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)
   :custom
   (dumb-jump-selector 'completing-read)
   (dumb-jump-force-searcher 'rg)
   (dumb-jump-prefer-searcher 'rg))

 ;; avy for jumping to place
 (use-package avy
   :bind
   ("C-j" . avy-goto-char-timer)
   (:map goto-map
         ("M-g" . avy-goto-line)))

 (use-package avy-zap
   :bind ([remap zap-to-char] . avy-zap-to-char))

;; auto-resize windows while switching using the golden-ratio
(use-package golden-ratio
  :custom
  (golden-ratio-exclude-modes '("vundo-mode"
                              "which-key-mode"))
  (golden-ratio-exclude-buffer-names '("*Warnings*"))
  :hook (elpaca-after-init . golden-ratio-mode))

(use-package ace-window
  :after golden-ratio
  :config (add-to-list 'golden-ratio-extra-commands 'ace-window)
  :bind (:map esc-map ("o" . ace-window)))

 (use-package hungry-delete
   :hook
   (text-mode . hungry-delete-mode)
   (prog-mode . hungry-delete-mode))

 ;; Multiple cursors (terminal-compatible)
 (use-package multiple-cursors
   :bind
   (:map esc-map ("RET" . mc/edit-lines)))
 ;; Note: s-<mouse-1> removed - doesn't work in terminal
 ;; Use M-RET (Option+Return) instead

 (use-package copy-as-format
   :bind
   (:map mode-specific-map
         :prefix-map copy-as-format-prefix-map
         :prefix "w"
         ("g" . copy-as-format-github)
         ("s" . copy-as-format-slack)
         ("m" . copy-as-format-markdown)
         ("h" . copy-as-format-html)
         ("j" . copy-as-format-jira)
         ("o" . copy-as-format-org-mode)))

;; consult-eglot for LSP symbol search
(use-package consult-eglot
  :after (consult eglot)
  :bind (:map eglot-mode-map
              ("C-c l s" . consult-eglot-symbols)))

;; Breadcrumb showing current function/class
(use-package breadcrumb
  :hook (prog-mode . breadcrumb-mode))

;; dired enhancements
(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
              ("TAB" . dired-subtree-toggle)
              ("<backtab>" . dired-subtree-cycle)))

;; File tree sidebar
(use-package dired-sidebar
  :commands (dired-sidebar-toggle-sidebar)
  :bind ("C-c d" . dired-sidebar-toggle-sidebar)
  :custom
  (dired-sidebar-width 35)
  (dired-sidebar-theme 'none))

;; Tab bar for multiple projects
(use-package tab-bar
  :ensure nil
  :custom
  (tab-bar-show 1)
  (tab-bar-close-button-show nil)
  (tab-bar-new-button-show nil)
  (tab-bar-tab-hints t)
  :bind (("C-c w n" . tab-bar-new-tab)
         ("C-c w c" . tab-bar-close-tab)
         ("C-c w r" . tab-bar-rename-tab)))

(use-package auth-source
   :ensure nil
   :custom (auth-sources '("~/.authinfo")))

 (use-package transient)

 (use-package magit
   :custom
   (magit-diff-refine-hunk t)
   (magit-git-executable "/opt/homebrew/bin/git")
   :bind (:map mode-specific-map
               :prefix-map magit-prefix-map
               :prefix "m"
               ("s" . magit-status)
               ("b" . magit-blame)
               ("l" . magit-log)))

 (use-package forge
   :after magit)

;; git-timemachine for file history
(use-package git-timemachine
  :bind ("C-c g t" . git-timemachine))

;; blamer for inline git blame (GitLens-like)
(use-package blamer
  :custom
  (blamer-idle-time 0.5)
  (blamer-min-offset 70)
  (blamer-prettify-time-p t)
  (blamer-author-formatter "  %s ")
  (blamer-datetime-formatter "[%s]")
  (blamer-commit-formatter " • %s")
  :bind (("C-c g b" . blamer-mode)
         ("C-c g B" . blamer-show-commit-info)))

 ;; get github link at point
 (use-package git-link)

(use-package org
  :ensure nil
  :custom
  (org-hide-emphasis-markers t))

(use-package org-modern
  :hook (elpaca-after-init . global-org-modern-mode))

(use-package org-modern-indent
  :ensure (org-modern-indent
           :host github
           :repo "jdtsmith/org-modern-indent")
  :config
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

;; polyglot setup
(use-package zig-mode)
(use-package nix-mode)
(use-package fountain-mode)
(use-package typescript-mode)

(use-package treesit
  :ensure nil
  :init
  (setq treesit-language-source-alist
        '((css . ("https://github.com/tree-sitter/tree-sitter-css"))
          (dockerfile . ("https://github.com/camdencheek/tree-sitter-dockerfile"))
          (go . ("https://github.com/tree-sitter/tree-sitter-go"))
          (html . ("https://github.com/tree-sitter/tree-sitter-html"))
          (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
          (json . ("https://github.com/tree-sitter/tree-sitter-json"))
          (nix . ("https://github.com/nix-community/tree-sitter-nix"))
          (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
          (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
          (ruby . ("https://github.com/tree-sitter/tree-sitter-ruby"))
          (python . ("https://github.com/tree-sitter/tree-sitter-python"))
          (yaml . ("https://github.com/ikatyang/tree-sitter-yaml"))
          (zig . ("https://github.com/tree-sitter-grammars/tree-sitter-zig"))))
  :config
  (defconst am/treesit-required-languages
    '(css dockerfile go html javascript json nix python ruby tsx typescript yaml zig))

  (defun am/treesit-ready-p (language)
    "Return non-nil when LANGUAGE grammar is available."
    (and (fboundp 'treesit-available-p)
         (treesit-available-p)
         (treesit-language-available-p language)))

  (defun am/treesit-toolchain-ready-p ()
    "Return non-nil when local tools can build grammars."
    (and (executable-find "git")
         (or (executable-find "cc")
             (executable-find "clang")
             (executable-find "gcc"))))

  (defun am/treesit-missing-languages ()
    "Return configured grammars not yet available."
    (seq-filter
     (lambda (language) (not (am/treesit-ready-p language)))
     am/treesit-required-languages))

  (defun am/configure-treesit-modes ()
    "Prefer tree-sitter modes for languages with installed grammars."
    (setq auto-mode-alist
          (seq-remove
           (lambda (entry)
             (member (cdr entry)
                     '(typescript-ts-mode tsx-ts-mode js-ts-mode json-ts-mode yaml-ts-mode)))
           auto-mode-alist))

    (when (am/treesit-ready-p 'typescript)
      (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode)))
    (when (am/treesit-ready-p 'tsx)
      (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode)))
    (when (am/treesit-ready-p 'javascript)
      (add-to-list 'auto-mode-alist '("\\.js\\'" . js-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.jsx\\'" . js-ts-mode)))
    (when (am/treesit-ready-p 'json)
      (add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode)))
    (when (am/treesit-ready-p 'yaml)
      (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode)))

    (setq major-mode-remap-alist nil)
    (when (am/treesit-ready-p 'yaml)
      (add-to-list 'major-mode-remap-alist '(yaml-mode . yaml-ts-mode)))
    (when (am/treesit-ready-p 'css)
      (add-to-list 'major-mode-remap-alist '(css-mode . css-ts-mode)))
    (when (am/treesit-ready-p 'typescript)
      (add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode)))
    (when (am/treesit-ready-p 'dockerfile)
      (add-to-list 'major-mode-remap-alist '(dockerfile-mode . dockerfile-ts-mode)))
    (when (am/treesit-ready-p 'javascript)
      (add-to-list 'major-mode-remap-alist '(javascript-mode . js-ts-mode)))
    (when (am/treesit-ready-p 'json)
      (add-to-list 'major-mode-remap-alist '(json-mode . json-ts-mode)))
    (when (am/treesit-ready-p 'ruby)
      (add-to-list 'major-mode-remap-alist '(ruby-mode . ruby-ts-mode)))
    (when (am/treesit-ready-p 'python)
      (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))
    (when (am/treesit-ready-p 'html)
      (add-to-list 'major-mode-remap-alist '(html-mode . html-ts-mode))))

  (defun am/treesit-install-missing-grammars ()
    "Install missing configured tree-sitter grammars."
    (interactive)
    (let ((missing (am/treesit-missing-languages)))
      (when missing
        (unless (am/treesit-toolchain-ready-p)
          (user-error "Missing git/compiler toolchain for tree-sitter grammar builds"))
        (message "Installing tree-sitter grammars: %s"
                 (mapconcat #'symbol-name missing ", "))
        (dolist (language missing)
          (treesit-install-language-grammar language))
        (am/configure-treesit-modes)
        (message "Tree-sitter grammars installed"))))

  (setq treesit-font-lock-level 4)
  (am/configure-treesit-modes)
  (add-hook 'elpaca-after-init #'am/treesit-install-missing-grammars))

(use-package eglot
  :ensure nil
  :init
  (fset #'jsonrpc--log-event #'ignore)
  :hook
  (typescript-mode . eglot-ensure)
  (typescript-ts-mode . eglot-ensure)
  (tsx-ts-mode . eglot-ensure)
  (go-ts-mode . eglot-ensure)
  (js-ts-mode . eglot-ensure)
  (nix-mode . eglot-ensure)
  (ruby-ts-mode . eglot-ensure)
  (json-ts-mode . eglot-ensure)
  (yaml-ts-mode . eglot-ensure)
  (dockerfile-ts-mode . eglot-ensure)
  (css-ts-mode . eglot-ensure)
  (html-ts-mode . eglot-ensure)
  (zig-mode . eglot-ensure)
  :config
  (remove-hook 'eldoc-display-functions 'eldoc-display-in-echo-area)
  ;; Use servers discovered in PATH for portability across machines.
  (when-let ((zls (executable-find "zls")))
    (add-to-list 'eglot-server-programs `(zig-mode . (,zls))))
  (when-let ((nil-ls (executable-find "nil")))
    (add-to-list 'eglot-server-programs `(nix-mode . (,nil-ls)))))

;; Enhanced eglot configuration
(with-eval-after-load 'eglot
  ;; Keybindings
  (define-key eglot-mode-map (kbd "C-c l a") #'eglot-code-actions)
  (define-key eglot-mode-map (kbd "C-c l r") #'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c l o") #'eglot-code-action-organize-imports)
  (define-key eglot-mode-map (kbd "C-c l f") #'eglot-format)
  (define-key eglot-mode-map (kbd "C-c l d") #'eldoc-box-help-at-point)

  ;; Performance for large projects
  (setq eglot-events-buffer-size 0)  ; Disable logging for performance
  (setq eglot-connect-timeout 120)
  (setq eglot-sync-connect nil))

;; Note: Built-in eglot respects .gitignore automatically,
;; so no need to manually configure ignored directories

;; formatting
(use-package apheleia
  :ensure (apheleia
           :host github
           :repo "raxod502/apheleia")
  :custom
  ;; Defer indentation decisions to project formatter config (e.g. .prettierrc).
  (apheleia-formatters-respect-indent-level nil)
  :hook (elpaca-after-init . apheleia-global-mode))

;; Project root detection
(setq project-vc-extra-root-markers '(".git" "package.json" "tsconfig.json"))

;; Generic project/search keybindings
(global-set-key (kbd "C-c p") #'project-switch-project)
(global-set-key (kbd "C-c s") #'consult-ripgrep)
(global-set-key (kbd "C-c a") #'xref-find-definitions)
(global-set-key (kbd "C-c u") #'project-find-regexp)
(global-set-key (kbd "C-c j") #'project-dired)
(global-set-key (kbd "C-c t") #'project-find-file)
(global-set-key (kbd "C-c r") #'consult-project-buffer)

(use-package autoinsert
  :ensure nil
  :hook (find-file . auto-insert))

;;;; misc functions
(defun find-user-config-file ()
  "Edit the config file, in another window."
  (interactive)
  (find-file-other-window (expand-file-name "config.org" user-emacs-directory)))

(define-key goto-map "I" 'find-user-config-file)

(defun kill-other-buffers ()
  "Kill all buffers but the current one.
Doesn't mess with special buffers."
  (interactive)
  (when (y-or-n-p "Are you sure you want to kill all buffers but the current one? ")
    (seq-each
     #'kill-buffer
     (delete (current-buffer) (seq-filter #'buffer-file-name (buffer-list))))))

(define-key ctl-x-map "K" 'kill-other-buffers)

(defun am/show-emacs-cheatsheet ()
  "Show the Emacs command cheat sheet in a pinned side window."
  (interactive)
  (let* ((file "/Users/ananthmadhavan/Code/emacs-commands-cheatsheet.md")
         (buffer (find-file-noselect file))
         (window (display-buffer-in-side-window
                  buffer
                  '((side . right)
                    (slot . 0)
                    (window-width . 0.33)))))
    (with-current-buffer buffer
      (read-only-mode 1)
      (visual-line-mode 1)
      (when (fboundp 'markdown-view-mode)
        (markdown-view-mode 1)))
    (set-window-dedicated-p window t)
    (select-window window)))

(global-set-key (kbd "C-c e") #'am/show-emacs-cheatsheet)

;; bring all the LLMs to emacs
(use-package gptel
  :custom (gptel-default-mode 'org-mode)
  :config
  (setq gptel-api-key (string-trim
                       (shell-command-to-string
                        "op read 'op://Personal/OpenAI/notes'")))
  (gptel-make-anthropic "Claude"
    :stream t
    :key (string-trim
          (shell-command-to-string
           "op read 'op://Personal/Anthropic/credential'")))
  (gptel-make-openai "DeepSeek"
    :host "api.deepseek.com"
    :endpoint "/chat/completions"
    :stream t
    :key (string-trim
          (shell-command-to-string
           "op read 'op://Personal/DeepSeek/credential'"))
    :models '(deepseek-chat deepseek-coder))
  :bind
  (:map mode-specific-map
        ("RET" . gptel-send)))

;;; init.el ends here
