simplenote-auto-sync-mode
======================

Overview
------------
 this mode is sync `*scratch*` buffer and others to simplenote automatically  
 when keyevent reach limit or launch command `sn-sync-buffer'
 
Requirement
------------
[simplenote.el](https://github.com/cefstat/simplenote.el)
and simplenote account

Installation
------------
 drop requirements and `simplenote-auto-sync-mode.el` into a directory in your `load-path`. If you have `install-elisp` or `auto-install`, you also be able to install
`simplenote-auto-sync-mode.el` like:

	;; install-elisp
    (install-elisp "https://raw.github.com/koko1000ban/emacs-simplenote-auto-sync-mode/master/simplenote-auto-sync-mode.el")

    ;; auto-install
    (auto-install-from-url "https://raw.github.com/koko1000ban/emacs-simplenote-auto-sync-mode/master/simplenote-auto-sync-mode.el")

And then put these lines into your .emacs file.

    ;; (require 'simplenote)
	;; (setq simplenote-email "oh!")
	;; (setq simplenote-password "oh!oh!")
	;; (simplenote-setup)
	;; (require 'simplenote-auto-sync-mode)
	;; (global-simplenote-auto-sync-mode 1)

Basic Usage
-----------
 * Sync Automatically if key event count reach limit(default 60 count)
 * press C-cC-c, sync manually
 * press C-cC-r, pull latest content from simple note and replace 


日本語
-----------
simplenoteを使ったバッファ毎の自動同期をするelispです  
60打するかC-cC-c押すと同期はじめます  
scratchを自動保存してsimplenote側で履歴管理するとか用  
(scratchはデフォでこのモード適用されます)
