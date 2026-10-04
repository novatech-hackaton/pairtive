import { useEffect, useId, useRef } from 'react';
import { createPortal } from 'react-dom';
import { AnimatePresence, motion } from 'motion/react';
import { X } from 'lucide-react';

const AM_FOCUSABLE =
  'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';

/** Focus trap + Escape + focus restore for dialogs. */
export function useAmDialog(open, onClose, { dismissible = true } = {}) {
  const ref = useRef(null);
  // Keep the latest onClose without re-running the focus effect: callers often
  // pass inline handlers, and re-running would steal focus from inputs on every render.
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;
  useEffect(() => {
    if (!open) return undefined;
    const previous = document.activeElement;
    const node = ref.current;
    const raf = requestAnimationFrame(() => {
      const target = node?.querySelector('[data-autofocus]') || node?.querySelector(AM_FOCUSABLE) || node;
      target?.focus?.();
    });
    function onKey(e) {
      if (e.key === 'Escape' && dismissible) {
        e.stopPropagation();
        onCloseRef.current?.();
      }
      if (e.key === 'Tab' && node) {
        const items = [...node.querySelectorAll(AM_FOCUSABLE)].filter((el) => el.offsetParent !== null || el === document.activeElement);
        if (!items.length) {
          e.preventDefault();
          return;
        }
        const first = items[0];
        const last = items[items.length - 1];
        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    }
    document.addEventListener('keydown', onKey, true);
    return () => {
      cancelAnimationFrame(raf);
      document.removeEventListener('keydown', onKey, true);
      previous?.focus?.();
    };
  }, [open, dismissible]);
  return ref;
}

export function AmModal({ open, onClose, title, description, children, footer, dismissible = true, size = 'md', icon: Icon }) {
  const ref = useAmDialog(open, onClose, { dismissible });
  const titleId = useId();
  const descId = useId();
  const widths = { sm: 'max-w-sm', md: 'max-w-md', lg: 'max-w-lg', xl: 'max-w-2xl' };

  return createPortal(
    <AnimatePresence>
      {open ? (
        <motion.div className="fixed inset-0 z-50 flex items-end justify-center p-3 sm:items-center sm:p-6" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
          <div className="absolute inset-0 bg-ink-950/70 backdrop-blur-sm" onClick={dismissible ? onClose : undefined} aria-hidden />
          <motion.div
            ref={ref}
            role="dialog"
            aria-modal="true"
            aria-labelledby={titleId}
            aria-describedby={description ? descId : undefined}
            tabIndex={-1}
            className={`glass-strong relative w-full ${widths[size]} max-h-[90dvh] overflow-y-auto rounded-3xl p-6 shadow-glow`}
            initial={{ y: 24, scale: 0.97, opacity: 0 }}
            animate={{ y: 0, scale: 1, opacity: 1 }}
            exit={{ y: 16, scale: 0.98, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 380, damping: 30 }}
          >
            {dismissible ? (
              <button
                type="button"
                onClick={onClose}
                aria-label="Close"
                className="absolute top-4 right-4 grid size-9 place-items-center rounded-full text-slate-400 hover:bg-white/10 hover:text-white"
              >
                <X className="size-5" aria-hidden />
              </button>
            ) : null}
            <div className="mb-4 flex items-start gap-3 pr-8">
              {Icon ? (
                <span className="grid size-11 shrink-0 place-items-center rounded-2xl bg-brand shadow-glow">
                  <Icon className="size-5 text-white" aria-hidden />
                </span>
              ) : null}
              <div>
                <h2 id={titleId} className="text-xl font-semibold text-white">
                  {title}
                </h2>
                {description ? (
                  <p id={descId} className="mt-1 text-sm text-slate-400">
                    {description}
                  </p>
                ) : null}
              </div>
            </div>
            {children}
            {footer ? <div className="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">{footer}</div> : null}
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>,
    document.body,
  );
}
