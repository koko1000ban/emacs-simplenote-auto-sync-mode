;;;  -*- coding: utf-8; mode: emacs-lisp; -*-
;;; simplenote-auto-sync-mode.el -- buffer sync automatically to simplenote

;; Copyright (C) 2012  tabi
;; Author: tabi <koko1000ban@gmail.com>
;; Keywords: simplenote, autosync

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; simplenote-auto-sync-mode is sync buffer to simplenote automatically
;;    when keyevent reach limit or launch command `sn-sync-buffer'

;;; Requirement:
;; * simplenote.el https://github.com/cefstat/simplenote.el
;; and simplenote account!

;;; Installation:

;; drop requirements and this file into a directory in your `load-path',
;; and put these lines into your .emacs file.

;; (require 'simplenote)
;; (setq simplenote-email "oh!")
;; (setq simplenote-password "oh!oh!")
;; (simplenote-setup)
;; (require 'simplenote-auto-sync-mode)
;; (global-simplenote-auto-sync-mode 1)

;;; Commands:
;;
;; Below are command list:
;; 
;; [C-c C-c] `sn-sync-buffer'
;;     sync current buffer to simplenote.
;;     if first time, create new note from buffer.
;;     else push current content to related note.
;; 
;; [C-c C-r] `sn-recovery-latest-buffer'
;;     pull latest related content from simplenote and replace it.
;;
;;

;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `sn-sync-keys-file'
;;    sync keyconfig file path 
;;
;;  `sn-sync-targets'
;;    target buffer names what start automatically this mode
;;
;;  `sn-limit-fire'
;;    limit count to start sync automatically


;;; ChangeLog:
;; * 0.0.1:
;;   Initial version.

;;; Code:

(require 'simplenote)
(require 'pp)

(defcustom sn-sync-keys-file
  (expand-file-name (concat (if (boundp 'user-emacs-directory)
                                user-emacs-directory
                              "~/.emacs.d/")
                            "/sn-sync-keys.dat"))
  "auto sync keys file name."
  :type 'string
  :group 'simplenote-auto-sync-mode)

(defcustom sn-sync-targets 
  '("*scratch*")
  "auto sync target"
  :group 'simplenote-auto-sync-mode)

(defcustom sn-limit-fire 60
  "limit count to start sync automatically"
  :group 'simplenote-auto-sync-mode)

(defvar sn-sync-keys nil)

(defvar sn-keyevent-counter 0)

(defun sn-current-mtime-gmt ()
  (let (mtime tz-offset)
    (setq mtime (current-time))
    (setq tz-offset (nth 0 (current-time-zone)))
    (time-add mtime (butlast (seconds-to-time (- tz-offset))))))

(defun sn-create-note-from-buffer ()
  (message "create new note from this buffer...")
  (let (createdate key)
    (setq currentdate (sn-current-mtime-gmt))
    (setq key (simplenote-create-note (encode-coding-string (buffer-string) 'utf-8 t)
                                      (simplenote-token)
                                      (simplenote-email)
                                      currentdate))
    (if key
        (progn
          (message "Created note %s" key))
      (message "Failed to create new note"))
    key))

(defun sn-push-buffer (key)
  ;; (interactive (list (sn-sync-keys-get-from-current-buffer)))
  (message "push buffer to simplenote...")
  (let (modifydate success)
    (setq modifydate (sn-current-mtime-gmt))
    (setq success (simplenote-update-note key
                                          (encode-coding-string (buffer-string) 'utf-8 t)
                                          (simplenote-token)
                                          (simplenote-email)
                                          modifydate))
    (if success
        (message "Pushed note %s" key)
      (message "Failed to push note %s" key))
    key))

(defun sn-recovery-latest-buffer (key)
  (interactive (list (sn-sync-keys-get (sn-get-fpath))))
  (if key 
      (multiple-value-bind (data note-key note-createdate note-modifydate note-deleted)
          (simplenote-get-note key
                               (simplenote-token)
                               (simplenote-email))
        (if data
            (progn
              (erase-buffer)
              (insert data)
              (message "Pulled note %s" key)
              ;; (pp data)
              )
          (message "Failed to pull note %s" key)))
    (message "Failed to get key from path %s" (sn-get-fpath))
    ))

(defun sn-sync-buffer ()
  (interactive)
  (if (not (boundp 'simplenote-email))
      (message "simplenote not ready to sync. see https://github.com/cefstat/simplenote.el")
    (let* ((buf (sn-get-fpath))
           (key (sn-sync-keys-get buf)))
      (if key
          (sn-push-buffer key)
        (sn-sync-keys-add buf (sn-create-note-from-buffer))))))

(defun sn-keybord-watcher (&optional arg)
  (setq sn-keyevent-counter (+ 1 sn-keyevent-counter))
  ;; (message "%d" sn-keyevent-counter)
  (when (> sn-keyevent-counter sn-fire-)
    (message "fireeeeeeee")
   (sn-sync-buffer)
    (setq sn-keyevent-counter 0)))

(defun sn-sync-keys-load ()
  (interactive)
  (let ((db (if (file-exists-p sn-sync-keys-file)
                (ignore-errors
                  (with-temp-buffer
                    (insert-file-contents sn-sync-keys-file)
                    (goto-char (point-min))
                    (sn-sync-keys-deserialize (read (current-buffer))))))))
    (setq sn-sync-keys (or db (sn-sync-keys-make)))))

(defun sn-sync-keys-save (&optional db)
  (interactive)
  (ignore-errors
    (with-temp-buffer
      (pp (sn-sync-keys-serialize (or db sn-sync-keys)) (current-buffer))
      (write-region (point-min) (point-max) sn-sync-keys-file))))

(defun sn-sync-keys-make ()
  (make-hash-table :test 'equal))

(defun sn-sync-keys-deserialize (sexp)
  (condition-case nil
      (let ((tab (sn-sync-keys-make)))
        (mapc (lambda (cons)
                (puthash (car cons) (cdr cons) tab))
              sexp)
        tab)
    (error (message "Invalid sync-keys db.") nil)))

(defun sn-sync-keys-serialize (db)
  (let (alist)
    (maphash (lambda (k v)
               (push (cons k v) alist)) db)
    alist))

(defun sn-sync-keys-add (fpath key)
  (puthash fpath key sn-sync-keys))

(defun sn-sync-keys-get (fpath)
  (gethash fpath sn-sync-keys))

(defun sn-sync-keys-init ()
  (sn-sync-keys-load)
  (add-hook 'kill-emacs-hook 'sn-sync-keys-save))

(defun sn-get-fpath ()
  (or (buffer-file-name) (buffer-name)))

;; Keymap
(defvar sn-mode-map 
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'sn-sync-buffer)
    (define-key map (kbd "C-c C-r") 'sn-recovery-latest-buffer)
    map)
  "Keymap for sn mode")

(define-minor-mode simplenote-auto-sync-mode 
  "sync simplenote when keydown"
  :lighter " SNAS"
  :keymap sn-mode-map
  (if simplenote-auto-sync-mode
      (progn 
        (add-hook 'pre-command-hook 'sn-keybord-watcher nil t)
        (sn-sync-keys-init))
    (remove-hook 'pre-command-hook 'sn-keybord-watcher t)))

(defun sn-mode-turn-on ()
  (when (member (buffer-name) sn-sync-targets)
     (simplenote-auto-sync-mode 1)))

(define-global-minor-mode global-simplenote-auto-sync-mode
  simplenote-auto-sync-mode sn-mode-turn-on
  :group 'simplenote-auto-sync-mode)

(provide 'simplenote-auto-sync-mode)