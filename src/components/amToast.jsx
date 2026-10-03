import { Toaster, toast } from 'sonner';

export const amToast = toast;

export function AmToaster() {
  return (
    <Toaster
      theme="dark"
      position="top-center"
      closeButton
      toastOptions={{
        classNames: {
          toast: 'glass-strong! rounded-2xl! border-white/10! text-slate-100! shadow-glow!',
          description: 'text-slate-400!',
          actionButton: 'bg-brand! text-white! rounded-lg!',
          cancelButton: 'bg-white/10! text-white! rounded-lg!',
        },
      }}
    />
  );
}
