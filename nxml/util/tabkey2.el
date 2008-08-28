;;; tabkey2.el --- Use second tab key pressed for what you want
;;
;; Author: Lennart Borgman (lennart O borgman A gmail O com)
;; Created: 2008-03-15T14:40:28+0100 Sat
(defconst tabkey2:version "1.22")
;; Last-Updated: 2008-05-05T20:58:59+0200 Mon
;; URL: http://www.emacswiki.org/cgi-bin/wiki/tabkey2.el
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `appmenu', `cl', `ourcomments-util', `popcmp'.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; The tab key is in Emacs often used for indentation.  However if you
;; press the tab key a second time and Emacs tries to do indentation
;; again, then usually nothing exciting will happen.  Then why not use
;; second tab key in a row for something else?
;;
;; Commonly used completion functions in Emacs is often bound to
;; something corresponding to Alt-Tab.  Unfortunately this is unusable
;; if you have a window manager that have an apetite for it (like that
;; on MS Windows for example, and several on GNU/Linux).
;;
;; Then using the second tab key press for completion might be a good
;; choice and perhaps also easy to remember.
;;
;; This little library tries to make it easy to do use the second tab
;; press for completion.  Or you can see this library as a swizz army
;; knife for the tab key ;-)
;;
;; See `tabkey2-mode' for more information.
;;
;;
;; This is a generalization of an idea Sebastien Rocca Serra once
;; presented on Emacs Wiki and called "Smart Tab".  (It seems like
;; many others have also been using Tab for completion in one way or
;; another for years.)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;; Version 1.04:
;; - Add overlay to display state after first tab.
;;
;; Version 1.05:
;; - Fix remove overlay problem.
;;
;; Version 1.06:
;; - Add completion function choice.
;; - Add support for popcmp popup completion.
;;
;; Version 1.07:
;; - Add informational message after first tab.
;;
;; Version 1.08:
;; - Give better informational message after first tab.
;;
;; Version 1.09:
;; - Put flyspell first.
;;
;; Version 1.09:
;; - Give the overlay higher priority.
;;
;; Version 1.10:
;; - Correct tabkey2-completion-functions.
;; - Add double-tab for modes where tab can not be typed again.
;; - Use better condition for when completion can be done, so that it
;;   can be done later while still on the same line.
;; - Add a better message handling for the "Tab completion state".
;; - Add C-g break out of the "Tab completion state".
;; - Add faces for highlight.
;; - Make it work in custom mode buffers.
;; - Fix documentation for `tabkey2-first'
;;
;; Version 1.11:
;; - Don't call chosen completion function directly.  Instead make it
;;   default for current buffer.
;;
;; Version 1.12:
;; - Simplify code.
;; - Add help to C-f1 during "Tab completion state".
;; - Fix documentation basics.
;; - Add customization of state message and line marking.
;; - Fix handling of double-Tab modes.
;; - Make user interaction better.
;; - Handle read-only in custom buffers better.
;; - Add more flexible check for if completion function is active.
;; - Support predictive mode.
;; - Reorder and simplify.
;;
;; Version 1.13:
;; - Add org-mode to the double-tab gang.
;; - Make it possible to use double-tab in normal buffers.
;; - Add cycling through completion functions to S-tab.
;;
;; Version 1.14:
;; - Fix bug in handling of read-only.
;; - Show completion binding in help message.
;; - Add binding to make current choice buffer local when cycling.
;;
;; Version 1.15:
;; - Fix problem at buffer end.
;; - Add S-tab to enter completion state without indentation.
;; - Add backtab bindings too for this.
;; - Remove double-tab, S-tab is better.
;; - Add list of modes that uses more tabs.
;; - Add list of modes that uses tab only for completion.
;; - Move first overlay when indentation changes.
;; - Make mark at line beginning 1 char long.
;;
;; Version 1.16:
;; - Don't call tab function when alternate key is pressed.
;;
;; Version 1.17:
;; - Let alternate key cycle completion functions instead of complete.
;; - Bind backtab.
;; - Fix bug when only one completion funciton was available.
;; - Fix bug when alt key and major without fix indent.
;;
;; Version 1.18:
;; - Add popup style messages.
;; - Add delay to first message.
;; - Use different face for indicator on line and message.
;; - Use different face for echo area and popup messages.
;; - Add anything to completion functions.
;; - Put help funciton on f1.
;; - Always bind alternate key to cycle.
;; - Change defcustoms to simplify (excuse me).
;; - Work around end of buffer problems.
;; - Work around start of buffer problems.
;; - Assure popup messages are visible.
;; - Reorder code in more logical order.
;;
;; Version 1.19:
;; - Make overlay keymap end advance.
;; - Remove overlay keymap parent.
;;
;; Version 1.20:
;; - Fix bug on emtpy line.
;; - Fix some text problems.
;; - Make f1 c/k work in tab completion state.
;;
;; Version 1.20:
;; - Fixed bug in overlay removal.
;;
;; Version 1.21:
;; - Fixed bug in minibuffer setup.
;;
;; Version 1.22:
;; - Honour widget-forward, button-forward.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Known bugs
;;
;; - Problems with comint shell.
;; - Does not check visibility.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(eval-when-compile (require 'cl))
(require 'popcmp nil t)
(require 'appmenu nil t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Custom

(defgroup tabkey2 nil
  "Customization of second tab key press."
  :group 'nxhtml
  :group 'convenience)

(defface tabkey2-highlight-line
  '((t :inherit highlight))
  "Face for marker on current line."
  :group 'tabkey2)

(defface tabkey2-highlight-message
  '((t :inherit tabkey2-highlight-line))
  "Face for messages in echo area."
  :group 'tabkey2)

(defface tabkey2-highlight-popup
  '((default :box t :inherit tabkey2-highlight-message)
    (((class color) (background light)) :foreground "black")
    (((class color) (background dark)) :foreground "yellow"))
  "Face for popup messages."
  :group 'tabkey2)

(defcustom tabkey2-show-mark-on-active-line t
  "Show mark on active line if non-nil.
This mark is shown during 'Tab completion state'."
  :type 'boolean
  :group 'tabkey2)

(defcustom tabkey2-show-message-on-enter 2.0
  "If non-nil show message when entering 'Tab completion state'.
If value is a number then delay message that number of seconds."
  :type '(choice (const :tag "Don't show" nil)
                 (const :tag "Show at once" t)
                 (float :tag "Show, but delayed (seconds)"))
  :group 'tabkey2)


;; (setq tabkey2-message-style 'popup)
;; (setq tabkey2-message-style 'echo-area)
(defcustom tabkey2-message-style 'popup
  "How to show messages."
  :type '(choice (const :tag "Popup" 'popup)
                 (const :tag "Echo area" 'echo-area))
  :group 'tabkey2)

(defcustom tabkey2-in-minibuffer nil
  "If non-nil use command `tabkey2-mode' also in minibuffer."
  :type 'boolean
  :group 'tabkey2)

(defcustom tabkey2-in-appmenu t
  "Show a completion menu in command `appmenu-mode' if t."
  :type 'boolean
  :set (lambda (sym val)
         (set-default sym val)
         (when (featurep 'appmenu)
           (if val
               (appmenu-add 'tabkey2 nil t "Completion" 'tabkey2-appmenu)
             (appmenu-remove 'tabkey2))))
  :group 'tabkey2)

(defcustom tabkey2-completion-functions
  '(
    ("Spell check word" flyspell-correct-word-before-point)
    ("Predictive word" complete-word-at-point predictive-mode)
    ("XML completion" nxml-complete)
    ("Complete Emacs symbol" lisp-complete-symbol)
    ("Widget complete" widget-complete)
    ("Comint Dynamic Complete" comint-dynamic-complete)
    ("PHP completion" php-complete-function)
    ("Tags completion" complete-symbol)
    ("Dynamic word expansion" dabbrev-expand)
    ("Ispell complete word" ispell-complete-word)
    ("Anything" anything (commandp 'anything))
    )
  "List of completion functions.
The first 'active' entry in this list is normally used during the
'Tab completion state' by `tabkey2-complete'.  An entry in the
list is considered active if:

-  The symbol is bound to a function

and

- it has a key binding at point,

  or

  the elisp expression evaluates to non-nil.
  If it is a single symbol then its variable value is used,
  otherwise the elisp form is evaled.

When choosing with `tabkey2-cycle-through-completion-functions'
only the currently active entry in this list are shown."
  :type '(repeat (list string (choice (command :tag "Currently know command")
                                      (symbol  :tag "Command not known yet"))
                       (sexp :tag "Elisp, if evaluate to non-nil then active")))
  :group 'tabkey2)

(defcustom tabkey2-alternate-key [f8]
  "Alternate key, bound to cycle and show completion functions.
This key is always bound to `tabkey2-cycle-through-completion-functions'."
  :set (lambda (sym val)
         (when (boundp 'tabkey2-mode-emul-map)
           (define-key tabkey2-mode-emul-map
             tabkey2-alternate-key nil)
           (define-key tabkey2-completion-state-emul-map
             tabkey2-alternate-key nil)
           (define-key tabkey2-mode-emul-map val 'tabkey2-cycle-through-completion-functions)
           (define-key tabkey2-completion-state-emul-map val 'tabkey2-cycle-through-completion-functions)
           (when tabkey2-completion-state-mode
             (tabkey2-completion-state-mode -1)
             (tabkey2-completion-state-mode 1)))
         (set-default sym val))
  :type 'key-sequence
  :group 'tabkey2)

(defcustom tabkey2-modes-that-uses-more-tabs
  '(python-mode
    haskell-mode
    makefile-mode
    org-mode
    Custom-mode
    ;; other
    cmd-mode
    )
  "In those modes use must use S-Tab to start completion state.
In those modes pressing Tab several types may make sense so you
can not go into�'Tab completion state' just because one Tab has
been pressed.  Instead you use S-Tab to go into that state.
After that Tab does completion.

You can do use S-Tab in other modes too if you want too."
  :type '(repeat command)
  :group 'tabkey2)

(defcustom tabkey2-modes-that-just-completes
  ;; Fix-me: Sometimes S-tab does not work here, why?
  '(shell-mode)
  "Tab is only used for completion in these modes.
Therefore `tabkey2-first' just calls the function on Tab."
  :type '(repeat command)
  :group 'tabkey2)

;;(setq tabkey2-use-popup-menus nil)
(defcustom tabkey2-use-popup-menus (when (featurep 'popcmp) t)
  "Use pop menus if available."
  :type 'boolean
  :group 'tabkey2)

(defvar tabkey2-preferred nil
  "Preferred function for second tab key press.")
(make-variable-buffer-local 'tabkey2-preferred)
(put 'tabkey2-preferred 'permanent-local t)

(defvar tabkey2-fallback nil
  "Fallback function for second tab key press.")
(make-variable-buffer-local 'tabkey2-fallback)
(put 'tabkey2-fallback 'permanent-local t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; State

(defvar tabkey2-overlay nil
  "Show when tab key 2 action is to be done.")
(defvar tabkey2-keymap-overlay nil
  "Hold the keymap for tab key 2.")
(defvar tabkey2-beg-mark nil)
(defvar tabkey2-end-mark nil)

;; (setq tabkey2-keymap-overlay nil)
(defconst tabkey2-completion-state-emul-map
  (let ((map (make-sparse-keymap)))
    ;;(define-key map [(control shift tab)] 'tabkey2-choose-completion-function)
    ;;(define-key map [(control backtab)]   'tabkey2-choose-completion-function)
    (define-key map [(control ?c) tab]    'tabkey2-make-current-sticky)

    (define-key map tabkey2-alternate-key 'tabkey2-cycle-through-completion-functions)
    (define-key map [backtab]             'tabkey2-cycle-through-completion-functions)
    (define-key map [(shift tab)]         'tabkey2-cycle-through-completion-functions)

    (define-key map [(control f1)]        'tabkey2-completion-function-help)
    (define-key map [(meta f1)]           'tabkey2-show-completion-functions)
    (define-key map [f1]                  'tabkey2-completion-state-help)

    (define-key map [(control ?g)]        'tabkey2-completion-state-off)
    (define-key map [tab]                 'tabkey2-complete)
    map)
  "This keymap is for `tabkey2-keymap-overlay'.")

(defun tabkey2-completion-state-p ()
  "Return t if Tab completion state should continue.
Otherwise return nil."
  (and (or (eobp)
           (eq (key-binding [tab]) 'tabkey2-complete))
       (= (line-beginning-position)
          (overlay-start tabkey2-keymap-overlay))))

(defvar tabkey2-current-tab-info nil
  "Saved information message for Tab completion state.")
(defvar tabkey2-current-tab-function nil
  "Tab completion state current completion function.")

(defun tabkey2-read-only-p ()
  "Return non-nil if buffer seems to be read-only at point."
  (or buffer-read-only
      (get-char-property (min (1+ (point)) (point-max)) 'read-only)
      (let ((remap (command-remapping 'self-insert-command (point))))
        (memq remap '(Custom-no-edit)))))

;;;; Minor mode active after first tab

(defun tabkey2-move-overlays ()
  "Move overlays that mark the state and carries the state keymap."
  (let* ((beg (let ((inhibit-field-text-motion t))
                (line-beginning-position)))
         (ind (current-indentation))
         (end (+ beg 1)) ;(if (> ind 0) ind 1)))
         (inhibit-read-only t))
    (unless tabkey2-overlay
      (setq tabkey2-overlay (make-overlay beg end)))
    ;; Fix-me: gets some strange errors, try avoid moving:
    (unless (and (eq (current-buffer) (overlay-buffer tabkey2-overlay))
                 (= beg (overlay-start tabkey2-overlay))
                 (= end (overlay-end   tabkey2-overlay)))
      (move-overlay tabkey2-overlay beg end (current-buffer)))
    ;; Give it a high priority, it is very temporary
    (overlay-put tabkey2-overlay 'priority 1000)
    (if tabkey2-show-mark-on-active-line
        (progn
          (overlay-put tabkey2-overlay 'face 'tabkey2-highlight-line)
          (overlay-put tabkey2-overlay 'help-echo
                       "This highlight shows that Tab completion state is on"))
      (overlay-put tabkey2-overlay 'face nil)
      (overlay-put tabkey2-overlay 'help-echo nil)))
  ;; The keymap overlay
  (let ((beg (line-beginning-position))
        (end (line-end-position)))
    ;;(when (= end (point-max)) (setq end (1+ end)))

    (setq tabkey2-beg-mark (copy-marker beg nil))
    (setq tabkey2-end-mark (copy-marker end t)))
  (assert (or (eobp)
              (= tabkey2-beg-mark tabkey2-end-mark)
              (= tabkey2-beg-mark
                 (save-excursion
                   (goto-char (1- tabkey2-end-mark))
                   (line-beginning-position)))))
  (unless tabkey2-keymap-overlay
    ;; Make the rear of the overlay advance so that the keymap works
    ;; at the end of a line and the end of the buffer.
    (setq tabkey2-keymap-overlay (make-overlay 0 0 nil nil t)))
  (overlay-put tabkey2-keymap-overlay 'priority 1000)
  ;;(overlay-put tabkey2-keymap-overlay 'face 'secondary-selection)
  (overlay-put tabkey2-keymap-overlay 'keymap
               tabkey2-completion-state-emul-map)
  (move-overlay tabkey2-keymap-overlay tabkey2-beg-mark tabkey2-end-mark (current-buffer)))

(defun tabkey2-is-active (fun chk)
  "Return t FUN is active.
Return t if CHK is a symbol with non-nil value or a form that
evals to non-nil.

Otherwise return t if FUN has a key binding at point."
  (or (if (symbolp chk)
          (when (boundp chk) (symbol-value chk))
        (eval chk))
      (let* ((emulation-mode-map-alists
              ;; Remove keymaps from tabkey2 in this copy:
              (delq 'tabkey2--emul-keymap-alist
                    (copy-sequence emulation-mode-map-alists)))
             (keys (tabkey2-symbol-keys fun))
             kb-bound)
        (dolist (key keys)
          (unless (memq (car (append key nil))
                        '(menu-bar))
            (setq kb-bound t)))
        kb-bound)))

(defun tabkey2-is-active-p (fun)
  "Return FUN is active.
Look it up in `tabkey2-completion-functions' to find out what to
check and return the value from `tabkey2-is-active'."
  (let ((chk (catch 'chk
               (dolist (rec tabkey2-completion-functions)
                 (when (eq fun (nth 1 rec))
                   (throw 'chk (nth 2 rec)))))))
    (tabkey2-is-active fun chk)))

(defun tabkey2-first-active-from-completion-functions ()
  "Return first active completion function.
Look in `tabkey2-completion-functions' for the first function
that has an active key binding."
  (catch 'active-fun
    (dolist (rec tabkey2-completion-functions)
      (let ((fun (nth 1 rec))
            (chk (nth 2 rec)))
        (when (tabkey2-is-active fun chk)
          (throw 'active-fun fun))))))

(defun tabkey2-get-default-completion-fun ()
  "Return the default completion function.
See `tabkey2-first' for the list considered."
  (or (when (and tabkey2-chosen-completion-function
                 (tabkey2-is-active-p
                  tabkey2-chosen-completion-function))
        tabkey2-chosen-completion-function)
      tabkey2-preferred
      (tabkey2-first-active-from-completion-functions)
      tabkey2-fallback))

(defvar tabkey2-completion-state-mode nil)
(defun tabkey2-completion-state-mode (arg)
  "Tab completion state minor mode.
This pseudo-minor mode holds the 'Tab completion state'.  When this
minor mode is on completion key bindings are available.

With ARG a positive number turn on, otherwise turn off this minor
mode.

See `tabkey2-first' for more information."
  (unless (assoc 'tabkey2-completion-state-mode minor-mode-alist)
    (setq minor-mode-alist (cons '(tabkey2-completion-state-mode " Tab2")
                                 minor-mode-alist)))
  (setq tabkey2-completion-state-mode (when (and (numberp arg)
                                                 (> arg 0))
                                        t))
  (let ((emul-map (cdr (car tabkey2--emul-keymap-alist))))
    (if tabkey2-completion-state-mode
        (progn
          ;; Set default completion function
          (tabkey2-make-message-and-set-fun
           (tabkey2-get-default-completion-fun))
          ;; Message
          (setq tabkey2-message-is-shown nil)
          (when tabkey2-show-message-on-enter
            (tabkey2-show-current-message
             (when (numberp tabkey2-show-message-on-enter)
               tabkey2-show-message-on-enter)))
          ;; Move overlays
          (tabkey2-move-overlays)
          ;; Work around eob keymap problem ...
          ;;(set-keymap-parent emul-map (overlay-get tabkey2-keymap-overlay 'keymap))
          ;; Set up for pre/post-command-hook
          (add-hook 'pre-command-hook 'tabkey2-pre-command)
          (add-hook 'post-command-hook 'tabkey2-post-command))
      ;;(set-keymap-parent emul-map nil)
      (let ((inhibit-read-only t))
        (when tabkey2-keymap-overlay
          (delete-overlay tabkey2-keymap-overlay))
        (when tabkey2-overlay
          (delete-overlay tabkey2-overlay)))
      (remove-hook 'pre-command-hook 'tabkey2-pre-command)
      (remove-hook 'post-command-hook 'tabkey2-post-command)
      (tabkey2-overlay-message nil)
      ;;(message "")
      )))

(defun tabkey2-completion-state-off ()
  "Quit Tab completion state."
  (interactive)
  (tabkey2-completion-state-mode -1)
  (message "Quit"))

(defvar tabkey2-message-is-shown nil)

(defun tabkey2-pre-command ()
  "Run this in `pre-command-hook'.
Check if message is shown.
Remove overlay message.
Cancel delayed message."
  (condition-case err
      (progn
        (setq tabkey2-message-is-shown
              (case tabkey2-message-style
                ('popup
                 (when tabkey2-overlay-message
                   (overlay-buffer tabkey2-overlay-message)))
                ('echo-area
                 (get (current-message) 'tabkey2))))
        (tabkey2-overlay-message nil)
        (tabkey2-cancel-delayed-message)
        )
    (error (message "tabkey2 pre: %s" (error-message-string err)))))

(defun tabkey2-post-command ()
  "Turn off Tab completion state if not feasable any more.
This is run in `post-command-hook' after each command."
  (condition-case err
      (save-match-data
        ;; Delayd messages
        (if (not (tabkey2-completion-state-p))
            (tabkey2-completion-state-mode -1)
          (tabkey2-move-overlays)))
    (error (message "tabkey2 post: %s" (error-message-string err)))))

(defun tabkey2-minibuffer-setup ()
  "Activate/deactivate `tabkey2-mode' in minibuffer."
  (set (make-local-variable 'tabkey2-mode)
       (and tabkey2-mode
            tabkey2-in-minibuffer)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Message functions

(defun tabkey2-invisible-p (pos)
  "Return non-nil if the character after POS is currently invisible."
  (let ((prop
         (get-char-property pos 'invisible)))
    (if (eq buffer-invisibility-spec t)
        prop
      (if (listp prop)
          (catch 'invis
            (dolist (p prop)
              (when (or (memq p buffer-invisibility-spec)
                        (assq p buffer-invisibility-spec))
                (throw 'invis t))))
        (or (memq prop buffer-invisibility-spec)
            (assq prop buffer-invisibility-spec))))))

(defvar tabkey2-overlay-message nil)

;; (defun test-scroll ()
;;   (interactive)
;;   (setq debug-on-error t)
;;   (let* ((buffer-name "test-scroll")
;;         (buffer (get-buffer buffer-name)))
;;     (when buffer (kill-buffer buffer))
;;     (setq buffer (get-buffer-create buffer-name))
;;     (switch-to-buffer buffer)
;;     (message "here 1") (sit-for 1)
;;     (condition-case err
;;         (scroll-up 1)
;;       (error (message "scroll-up error: %s" err)
;;              (sit-for 1)))
;;     (message "here 2") (sit-for 1)
;;     (scroll-up 1)
;;     (message "here 3") (sit-for 1)
;;     ))

(defun tabkey2-overlay-message (txt)
  "Display TXT below or above current line using an overlay."
  (if (not txt)
      (when tabkey2-overlay-message
        (delete-overlay tabkey2-overlay-message))
    (let ((ovl tabkey2-overlay-message)
          (column (current-column))
          (txt-len (length txt))
          (here (point))
          beg end
          (before "")
          (after "")
          ovl-str too-much
          (is-eob (eobp))
          (direction 1))
      (unless ovl (setq ovl (make-overlay 0 0)))

      (when is-eob
        (setq direction -1))
      ;;(forward-line 0)
      (forward-line direction)
      ;;(message "here 1") (sit-for 2)
      (when (and (/= (point-min) (window-start))
                 (>= (point) (window-end)))
        ;; Go back inside window to avoid aggressive scrolling:
        (forward-line -1)
        (scroll-up 1)
        (forward-line 1))
      ;;(message "here 2") (sit-for 2)
      ;; Fix-me: Emacs bug workaround
      (if (when (< 1 (point))
            (tabkey2-invisible-p (1- (point))))
          (progn
            (goto-char here)
            (tabkey2-echo-area-message txt))
        (when (tabkey2-invisible-p (point))
          (while (tabkey2-invisible-p (point))
            (forward-line direction)))
        (setq beg (line-beginning-position))
        (setq end (line-end-position))

        ;; string before
        (move-to-column column)
        (setq before (buffer-substring beg (point)))
        (when (< (current-column) column)
          (setq before
                (concat before
                        (make-string (- column (current-column)) ? ))))
        (setq too-much (- (+ txt-len (length before))
                          (window-width)))
        (when (> too-much 0)
          (setq before (substring before 0 (- too-much))))

        (unless (> too-much 0)
          (move-to-column (+ txt-len (length before)))
          (setq after (buffer-substring (point) end)))

;;;       (when is-eob
;;;         ;; fix-me
;;;         (setq before (concat "\n" before))
;;;         (setq beg (point-max-marker))
;;;         (setq end (point-max-marker))
;;;         (set-marker-insertion-type beg t)
;;;         (set-marker-insertion-type end t)
;;;         )

        ;;(setq before (propertize before 'face 'secondary-selection))
        ;;(setq after (propertize after 'face 'secondary-selection))
        (setq ovl-str (concat before
                              (propertize txt 'face 'tabkey2-highlight-popup)
                              after
                              ;;"\n"
                              ))

        (overlay-put ovl 'after-string ovl-str)
        (overlay-put ovl 'display "")
        (overlay-put ovl 'window (selected-window))
        (move-overlay ovl beg end)

        (setq tabkey2-overlay-message ovl)
        ;;(add-hook 'pre-command-hook 'tabkey2-remove-overlay-message)
        (goto-char here)
        ))))

;; Fix-me: This was not usable IMO. Too much flickering.
;; (defun tabkey2-tooltip (txt)
;;   (let* ((params tooltip-frame-parameters)
;;          (coord (car (point-to-coord (point))))
;;          (left (car coord))
;;          (top  (cadr coord))
;;          tooltip-frame-parameters
;;          )
;;     ;; Fix-me: how do you get char height??
;;     (setq top (+ top 50))
;;     (setq params (tooltip-set-param params 'left left))
;;     (setq params (tooltip-set-param params 'top top))
;;     (setq params (tooltip-set-param params 'top top))
;;     (setq tooltip-frame-parameters params)
;;     (tooltip-hide)
;;     (tooltip-show txt nil)))

(defun tabkey2-echo-area-message (txt)
  "Show TXT in the echo area with a special face.
Shown with the face `tabkey2-highlight-message'."
  (message "%s" (propertize txt
                            'face 'tabkey2-highlight-message
                            'tabkey2 t)))

(defun tabkey2-deliver-message (txt)
  "Show message TXT to user."
  (case tabkey2-message-style
    (popup (tabkey2-overlay-message txt))
    (t (tabkey2-echo-area-message txt))))

(defun tabkey2-timer-deliver-message (txt)
  "Show message TXT to user.
Protect from errors cause this is run during a timer."
  (condition-case err
      (tabkey2-deliver-message txt)
    (error (message "tabkey2-timer-deliver-message: %s"
                    (error-message-string err)))))

(defvar tabkey2-delayed-timer nil)

(defun tabkey2-cancel-delayed-message ()
  "Cancel delayed message."
  (when tabkey2-delayed-timer
    (cancel-timer tabkey2-delayed-timer)
    (setq tabkey2-delayed-timer)))

(defun tabkey2-maybe-delayed-message (txt delay)
  "Show message TXT, delay it if DELAY is non-nil."
  (if delay
      (setq tabkey2-delayed-timer
            (run-with-idle-timer
             delay nil
             'tabkey2-timer-deliver-message txt))
    (tabkey2-deliver-message txt)))

(defun tabkey2-message (delay format-string &rest args)
  "Show, if DELAY delayed, otherwise immediately message.
FORMAT-STRING and ARGS are like for `message'."
  (let ((txt (apply 'format format-string args)))
    (tabkey2-maybe-delayed-message txt delay)))

(defun tabkey2-show-current-message (&optional delay)
  "Show current completion message, delayed if DELAY is non-nil."
  (tabkey2-cancel-delayed-message)
  (tabkey2-message delay "%s" tabkey2-current-tab-info))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Completion function selection etc

(defun tabkey2-symbol-keys (comp-fun)
  "Get a list of all key bindings for COMP-FUN."
  (let* ((remapped (command-remapping comp-fun)))
    (where-is-internal comp-fun
                       nil ;;overriding-local-map
                       nil nil remapped)))

(defun tabkey2-get-active-completion-functions ()
  "Get a list of active completion functions.
Consider only those in `tabkey2-completion-functions'."
  (delq nil
        (mapcar (lambda (rec)
                  (let ((fun (nth 1 rec))
                        (chk (nth 2 rec)))
                    (when (tabkey2-is-active fun chk) rec)))
                tabkey2-completion-functions)))

(defvar tabkey2-chosen-completion-function nil)
(make-variable-buffer-local 'tabkey2-chosen-completion-function)
(put 'tabkey2-chosen-completion-function 'permanent-local t)

(defun tabkey2-make-current-sticky ()
  "Make current Tab completion function sticky.
Set the current Tab completion function at point as default for
the current buffer."
  (interactive)
  (let ((set-it
         (y-or-n-p
          (format
           "Make %s default for Tab completion in current buffer? "
           tabkey2-current-tab-function))))
    (when set-it
      (setq tabkey2-chosen-completion-function
            tabkey2-current-tab-function))
    (unless set-it
      (when (local-variable-p 'tabkey2-chosen-completion-function)
        (when (y-or-n-p "Use default Tab completion selection in buffer? ")
          (setq set-it t))
        (kill-local-variable 'tabkey2-chosen-completion-function)))
    (when (tabkey2-completion-state-p)
      (tabkey2-message "%s%s" tabkey2-current-tab-info
                       (if set-it " - Done" "")))))

(defun tabkey2-cycle-through-completion-functions (prefix)
  "Cycle through cnd display ompletion functions.
If 'Tab completion state' is not on then turn it on.

If PREFIX is given just show what shift tab will do."
  (interactive "P")
  (if (tabkey2-read-only-p)
      (message "Buffer is read only at point")
    (unless tabkey2-completion-state-mode (tabkey2-completion-state-mode 1))
    (save-match-data
      (if prefix
          ;; fix-me
          (message "(TabKey2) Shift tab: show/cycle completion function")
        (let* ((active (mapcar (lambda (rec)
                                 (nth 1 rec))
                               (tabkey2-get-active-completion-functions)))
               (first (car active))
               next)
          ;;(message "is-shown=%s" tabkey2-message-is-shown)
          (when tabkey2-message-is-shown
            ;; Message is shown currently so change
            (when tabkey2-current-tab-function
              (while (and active (not next))
                (when (eq (car active) tabkey2-current-tab-function)
                  (setq next (cadr active)))
                (setq active (cdr active))))
            (unless next (setq next first))
            (tabkey2-make-message-and-set-fun next)))
        (tabkey2-show-current-message)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Handling of Tab and alternate key

(defun tabkey2-first (prefix)
  "Do something else after first Tab.
The Tab key is easy to type on your keyboard.  Then why not use
it for completion, something that is very useful?  Shells usually
use Tab for completion so many are used to it.  This was the idea
of Smart Tabs and this is a generalization of that idea.

However in Emacs the Tab key is usually used for indentation.
The idea here is that if indentation has been done once since you
entered a line, then as long as point is on the same line further
Tab keys might as well do completion.

So you kind of do Tab-Tab for first completion and then just Tab
for further completions on the same line.

This function is bound to the Tab key when minor mode command
`tabkey2-mode' is on.  It works like this:

1. The first time Tab is pressed do whatever Tab would have done
   if minor mode command `tabkey2-mode' was off.

   Then before next command enter a new temporary 'Tab completion
   state' for just the next command.  Show this by a highlight on
   the indentation and a marker \"Tab2\" in the mode line.

   However if either
   - the minibuffer is active and `tabkey2-in-minibuffer' is nil
   - `major-mode' is in `tabkey2-modes-that-uses-more-tabs' then
     do not enter this temporary 'Tab completion state'.

   For major modes where it make sense to press Tab several times
   S-Tab \(or backtab) can often be used to enter 'Tab completion
   state'. Or, use `tabkey2-alternate-key': \\[tabkey2-alternate-key]


2. As long as point is on the same line do completion when Tab is
   pressed again.  Show that this state is active with a
   highlighting at the line beginning, a marker on the mode
   line (Tab2) and a message in the echo area which tells what
   kind of completion will be done.

   When deciding what kind of completion to do look in the table
   below and do whatever it found first that is not nil:

   - `tabkey2-preferred'
   - `tabkey2-completion-functions'
   - `tabkey2-fallback'

3. Of course, there must be some way for you to easily determine
   what kind of completion because there are many in Emacs. If
   you do not turn it off this function show that to you.  And if
   you turn it off you can still display it, see the key bindings
   below.

   If this function is used with a PREFIX argument then it just
   shows what Tab will do.

   If the default kind of completion is not what you want then
   you can choose completion function from any of the candidates
   in `tabkey2-completion-functions'.  During the 'Tab completion
   state' the following extra key bindings are available:

\\{tabkey2-completion-state-emul-map}

Of course, some languages does not have a fixed indent as is
assumed above. You can put major modes for those in
`tabkey2-modes-that-just-completes'.

Some major modes uses tab for something else already. Those are
in `tabkey2-modes-that-uses-more-tabs'.  There is an alternate
key, `tabkey2-alternate-key' if you want to do completion
there. Note that this key does not do completion. It however
enters 'Tab completion state' in which you have access to the
keys above for completion etc. \(This key also lets you cycle
through the completion functions too choose which one to use.)

-----
NOTE: This uses `emulation-mode-map-alists' and it supposes that
nothing else is bound to Tab there."
  (interactive "P")
  (if (and tabkey2-keymap-overlay
           (eq (overlay-buffer tabkey2-keymap-overlay) (current-buffer))
           (>= (point) (overlay-start tabkey2-keymap-overlay))
           (<= (point) (overlay-end   tabkey2-keymap-overlay)))
      ;; We should maybe not be here, but the keymap does not work at
      ;; the end of the buffer so we call the second tab function from
      ;; here:
      (if (memq 'shift (event-modifiers last-input-event))
          (call-interactively 'tabkey2-cycle-through-completion-functions)
        (call-interactively 'tabkey2-complete prefix))
    (let* ((emma-without-tabkey2
            ;; Remove keymaps from tabkey2 in this copy:
            (delq 'tabkey2--emul-keymap-alist
                  (copy-sequence emulation-mode-map-alists)))
           (just-complete (memq major-mode tabkey2-modes-that-just-completes))
           (what (if just-complete
                     'complete
                   (if (or (unless tabkey2-in-minibuffer
                             (active-minibuffer-window))
                           (use-region-p)
                           (memq major-mode tabkey2-modes-that-uses-more-tabs))
                       'indent
                     'indent-complete
                     )))
           (to-do-1 (unless (or
                             ;; Skip action on tab if shift tab,
                             ;; backtab or a mode in the "just
                             ;; complete" list
                             (memq 'shift (event-modifiers last-input-event))
                             (equal [backtab] (this-command-keys-vector))
                             (memq what '(complete)))
                      (let ((emulation-mode-map-alists emma-without-tabkey2))
                        (key-binding [?\t] t))))
           (to-do-2 (unless (or (memq what '(indent))
                                (memq to-do-1 '(widget-forward button-forward)))
                      (tabkey2-get-default-completion-fun))))
      (if prefix
          (if (memq 'shift (event-modifiers last-input-event))
              (message "(TabKey2) Shift tab: turn on 'Tab completion state'")
            (message "(TabKey2) First tab: %s, next: maybe %s"
                     to-do-1 to-do-2))
        (when to-do-1
          (let ((last-command to-do-1)
                mumamo-multi-major-mode)
            (call-interactively to-do-1)))
        (unless (tabkey2-read-only-p)
          (when to-do-2
            (if just-complete
                (call-interactively 'tabkey2-complete)
              (tabkey2-completion-state-mode 1))
            ))))))


(defun tabkey2-complete (prefix)
  "Call current completion function.
If used with a PREFIX argument then just show what Tab will do."
  (interactive "P")
  (if prefix
      (message "(TabKey2) Tab: %s" tabkey2-current-tab-function)
    (call-interactively tabkey2-current-tab-function)))

;; Use emulation mode map for first Tab key
(defconst tabkey2-mode-emul-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tab] 'tabkey2-first)
    (define-key map [backtab] 'tabkey2-cycle-through-completion-functions)
    (define-key map tabkey2-alternate-key 'tabkey2-cycle-through-completion-functions)
    map)
  "This keymap just binds tab all the time.")

(defvar tabkey2--emul-keymap-alist nil)

(define-minor-mode tabkey2-mode
  "More fun with Tab key number two (completion etc).
This minor mode binds Tab in a way that let you do completion
with Tab in all buffers \(where it is possible).  See
`tabkey2-first' for more information."
  :keymap nil
  :global t
  :group 'tabkey2
  (if tabkey2-mode
      (progn
        (add-hook 'minibuffer-setup-hook 'tabkey2-minibuffer-setup)
        ;; Update emul here if keymap have changed
        (setq tabkey2--emul-keymap-alist
              (list (cons 'tabkey2-mode
                          tabkey2-mode-emul-map)))
        (add-to-list 'emulation-mode-map-alists 'tabkey2--emul-keymap-alist))
    (tabkey2-completion-state-mode -1)
    (remove-hook 'minibuffer-setup-hook 'tabkey2-minibuffer-setup)
    (setq emulation-mode-map-alists (delq 'tabkey2--emul-keymap-alist
                                          emulation-mode-map-alists))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Help functions

(defun tabkey2-show-completion-state-help ()
  "Help for 'Tab completion state'.
To get out of this state you can move out of the current line.

During this state the keymap below is active.  This state stops
as soon as you leave the current row.

\\{tabkey2-completion-state-emul-map}
See function `tabkey2-mode' for more information.

If you want to use Emacs normal help function then press F1
again.")

(defun tabkey2-completion-state-help ()
  "Show help for 'Tab completion state'."
  (interactive)
  (tabkey2-show-current-message)
  (let ((invoked-by-f1 (equal (this-command-keys-vector) [f1]))
        normal-help)
    (when invoked-by-f1
      (with-timeout (3.5 (setq normal-help nil))
        (setq normal-help
              (read-char
               (propertize
                (concat "Type a char for Emacs help."
                        " Or, wait for Tab completion help: ")
                'face 'highlight)
               nil))))
    (case normal-help
      ((nil)
       (message "Tab completion state help")
       (describe-function 'tabkey2-show-completion-state-help))
      (?c
       (call-interactively 'describe-key-briefly))
      (?k
       (call-interactively 'describe-key))
      (t
       (tabkey2-completion-state-mode -1)
       (setq unread-command-events (append (this-command-keys) nil))))))

(defun tabkey2-completion-function-help ()
  "Show help for current completion function."
  (interactive)
  (describe-function tabkey2-current-tab-function))




(defun tabkey2-get-key-binding (fun)
  "Get key binding for FUN during 'Tab completion state'."
  (let* ((remapped (command-remapping fun))
         (key (where-is-internal fun
                                 tabkey2-completion-state-emul-map
                                 t
                                 nil
                                 remapped)))
    key))

(defun tabkey2-make-message-and-set-fun (comp-fun)
  "Set current completion function to COMP-FUN.
Build message but don't show it."
  (setq tabkey2-current-tab-function comp-fun)
  (let* ((chs-fun 'tabkey2-cycle-through-completion-functions)
         (key (tabkey2-get-key-binding chs-fun))
         (active-funs (tabkey2-get-active-completion-functions))
         what)
    (dolist (rec tabkey2-completion-functions)
      (let ((fun (nth 1 rec))
            (txt (nth 0 rec)))
        (when (eq fun comp-fun) (setq what txt))))
    (let ((info (concat (format "Tab: %s" what)
                        (if (cdr (tabkey2-get-active-completion-functions))
                            (format ", other %s, help F1"
                                    (key-description key))
                          ""))))
      (setq tabkey2-current-tab-info info))))

(defun tabkey2-get-active-string (bnd fun buf)
  "Get string to show for state.
BND: means active
FUN: function
BUF: buffer"
  (if bnd
      (if (with-current-buffer buf (tabkey2-read-only-p))
          (propertize "active, but read-only" 'face '( :foreground "red"))
        (propertize "active" 'face '( :foreground "green")))
    (if (fboundp fun)
        (propertize "not active" 'face '( :foreground "red"))
      (propertize "not defined" 'face '( :foreground "gray")))))

(defun tabkey2-show-completion-functions ()
  "Show what currently may be used for completion."
  (interactive)
  (let ((orig-buf (current-buffer))
        (orig-mn  mode-name)
        (active-mark (concat " "
                             (propertize " <= "
                                         'face '( :background "yellow"))))
        (act-found nil)
        (chosen-fun tabkey2-chosen-completion-function)
        what
        chosen)
    (when chosen-fun
      (dolist (rec tabkey2-completion-functions)
        (let ((fun (nth 1 rec))
              (txt (nth 0 rec)))
          (when (eq fun chosen-fun) (setq what txt))))
      (setq chosen (list what chosen-fun)))
    (with-output-to-temp-buffer (help-buffer)
      (help-setup-xref (list #'tabkey2-show-completion-functions)
                       (interactive-p))
      (with-current-buffer (help-buffer)
        (insert (concat "The completion functions available for"
                        " 'Tab completion' in buffer\n'"
                (buffer-name orig-buf)
                "' at point with mode " orig-mn " are shown below.\n"
                "The first active function is used.\n\n")
        (if (not chosen)
            (insert "  None is chosen")
          (let* ((txt (nth 0 chosen))
                 (fun (nth 1 chosen))
                 (chk (nth 2 chosen))
                 (bnd (with-current-buffer orig-buf
                        (tabkey2-is-active fun chk)))
                 (act (tabkey2-get-active-string bnd fun orig-buf)))
            (insert (format "  Chosen currently is %s (%s): %s"
                            txt fun act))
            (when bnd (insert active-mark) (setq act-found t))))
        (insert "\n\n")
        (if (not tabkey2-preferred)
            (insert "  None is preferred")
          (let* ((txt (nth 0 tabkey2-preferred))
                 (fun (nth 1 tabkey2-preferred))
                 (chk (nth 2 chosen))
                 (bnd (with-current-buffer orig-buf
                        (tabkey2-is-active fun chk)))
                 (act (tabkey2-get-active-string bnd fun orig-buf)))
            (insert (format "  Preferred is %s (`%s')': %s"
                            txt fun act))
            (when bnd (insert active-mark) (setq act-found t))))
        (insert "\n\n")
        (dolist (comp-fun tabkey2-completion-functions)
          (let* ((txt (nth 0 comp-fun))
                 (fun (nth 1 comp-fun))
                 (chk (nth 2 comp-fun))
                 (bnd (with-current-buffer orig-buf
                        (tabkey2-is-active fun chk)))
                 (act (tabkey2-get-active-string bnd fun orig-buf)))
            (insert
             (format
              "  %s (`%s'): %s"
              txt fun act))
            (when (and (not act-found) bnd)
              (insert active-mark) (setq act-found t))
            (insert "\n")))
        (insert "\n")
        (if (not tabkey2-fallback)
            (insert "  There is no fallback")
          (let* ((txt (nth 0 tabkey2-fallback))
                 (fun (nth 1 tabkey2-fallback))
                 (chk (nth 2 tabkey2-fallback))
                 (bnd (with-current-buffer orig-buf
                        (tabkey2-is-active fun chk)))
                 (act (tabkey2-get-active-string bnd fun orig-buf)))
            (insert (format "  Fallback is %s (`%s'): %s"
                            txt fun act))
            (when (and (not act-found) bnd) (insert active-mark) (setq act-found t))))
        (insert "\n\nSee function `tabkey2-mode' for more information.")
        (print-help-return-message))))))

(defvar tabkey2-completing-read 'completing-read)

(defun tabkey2-set-fun (fun)
  "Use function FUN for Tab in 'Tab completion state'."
  (setq tabkey2-chosen-completion-function fun)
  (unless fun
    (setq fun (tabkey2-first-active-from-completion-functions)))
  (tabkey2-make-message-and-set-fun fun)
  (when (tabkey2-completion-state-p)
    (message "%s" tabkey2-current-tab-info)))

(defun tabkey2-appmenu ()
  "Make a menu for minor mode command `appmenu-mode'."
  (unless (tabkey2-read-only-p)
    (let* ((cf-r (reverse (tabkey2-get-active-completion-functions)))
           (tit "Complete")
           (map (make-sparse-keymap tit)))
      (define-key map [tabkey2-usage]
        (list 'menu-item "Show available completion functions"
              'tabkey2-show-completion-functions))
      (define-key map [tabkey2-divider-1] (list 'menu-item "--"))
      (let ((set-map (make-sparse-keymap "Set completion")))
        (define-key map [tabkey2-choose]
          (list 'menu-item "Set Tab completion for buffer" set-map))
        (dolist (cf-rec cf-r)
          (let ((dsc (nth 0 cf-rec))
                (fun (nth 1 cf-rec)))
            (define-key set-map
              (vector (intern (format "tabkey2-set-%s" fun)))
              (list 'menu-item dsc
                    `(lambda ()
                       (interactive)
                       (tabkey2-set-fun ',fun))
                    :button
                    `(:radio
                      . (eq ',fun tabkey2-chosen-completion-function))))))
        (define-key set-map [tabkey2-set-div] (list 'menu-item "--"))
        (define-key set-map [tabkey2-set-default]
          (list 'menu-item "Default Tab completion"
                (lambda ()
                  (interactive)
                  (tabkey2-set-fun nil))
                :button
                '(:radio . (null tabkey2-chosen-completion-function))))
        (define-key set-map [tabkey2-set-header-div] (list 'menu-item "--"))
        (define-key set-map [tabkey2-set-header]
          (list 'menu-item "Set Tab completion for buffer"))
        )
      (define-key map [tabkey2-divider] (list 'menu-item "--"))
      (dolist (cf-rec cf-r)
        (let ((dsc (nth 0 cf-rec))
              (fun (nth 1 cf-rec)))
          (define-key map
            (vector (intern (format "tabkey2-call-%s" fun)))
            (list 'menu-item dsc fun
                  :button
                  `(:toggle
                    . (eq ',fun tabkey2-chosen-completion-function))
                  ))))
      map)))

;; (defun tabkey2-completion-menu-popup ()
;;   "Pop up a menu with completion alternatives."
;;   (interactive)
;;   (let ((menu (tabkey2-appmenu)))
;;     (popup-menu-at-point menu)))

;; (defun tabkey2-choose-completion-function ()
;;   "Set current completion function.
;; Let user choose completion function from those in
;; `tabkey2-completion-functions' that have some key binding at
;; point.

;; Let the chosen completion function be the default for subsequent
;; completions in the current buffer."
;;   ;; Fix-me: adjust to mumamo.
;;   (interactive)
;;   (save-match-data
;;     (if (and (featurep 'popcmp)
;;              tabkey2-use-popup-menus)
;;         (tabkey2-completion-menu-popup)
;;       (when (eq 'completing-read tabkey2-completing-read) (isearch-unread 'tab))
;;       (let* ((cf-r (reverse (tabkey2-get-active-completion-functions)))
;;              (cf (cons '("- Use default Tab completion" nil) cf-r))
;;              (hist (mapcar (lambda (rec)
;;                              (car rec))
;;                            cf))
;;              (tit (funcall tabkey2-completing-read "Set current completion function: " cf
;;                            nil ;; predicate
;;                            t   ;; require-match
;;                            nil ;; initial-input
;;                            'hist ;; hist
;;                            ))
;;              (fun-rec (assoc-string tit cf))
;;              (fun (cadr fun-rec)))
;;         (setq tabkey2-chosen-completion-function fun)
;;         (unless fun
;;           (setq fun (tabkey2-first-active-from-completion-functions)))
;;         (tabkey2-make-message-and-set-fun fun)
;;         (when (tabkey2-completion-state-p)
;;           (tabkey2-show-current-message))))))

(defun tabkey2-add-to-appmenu ()
  "Add a menu to function `appmenu-mode'."
  (appmenu-add 'tabkey2 nil t "Completion" 'tabkey2-appmenu))


(provide 'tabkey2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; tabkey2.el ends here