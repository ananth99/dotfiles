;;; early-init.el --- Early initialization -*- lexical-binding: t -*-

;; Increase GC threshold for faster startup
(setq gc-cons-threshold most-positive-fixnum)

;; Prefer newest version of files
(setq load-prefer-newer t)

;; Disable package.el (we use Elpaca)
(setq package-enable-at-startup nil)
(setq-default package-quickstart nil)

;; Disable unwanted UI elements
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)

;; Unset file-name-handler-alist for faster startup
(setq file-name-handler-alist nil)

;; Keyboard modifiers (terminal-aware)
;; In GUI: use ⌘ as meta, ⌥ as super
(when (display-graphic-p)
  (defvar mac-option-key-is-meta nil)
  (defvar mac-command-key-is-meta t)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'super))

;; In terminal: Option/Alt is automatically Meta
;; Ghostty config (macos-option-as-alt = true) handles this
;; No Emacs configuration needed

;; Disable bidirectional text rendering for performance
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)

;; Remove CLI opts that aren't relevant to current OS
(unless (eq system-type 'darwin)
  (setq command-line-ns-option-alist nil))
(unless (eq system-type 'gnu/linux)
  (setq command-line-x-option-alist nil))

;; Native compilation cache
;; Emacs 30 can expose the function before native-comp state is initialized.
(when (and (fboundp 'startup-redirect-eln-cache)
           (boundp 'native-comp-eln-load-path))
  (startup-redirect-eln-cache
   (expand-file-name "~/.cache/emacs/")))

;; Inhibit implied resize for faster startup
(setq frame-inhibit-implied-resize t)

;; Set JetBrains Mono font (works in both GUI and terminal)
(set-face-attribute 'default nil
                    :family "JetBrains Mono"
                    :height 130
                    :weight 'regular)

;;; early-init.el ends here
