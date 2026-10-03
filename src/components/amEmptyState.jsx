import { motion } from 'motion/react';

export function AmEmptyState({ icon: Icon, title, description, action, className = '' }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      className={`flex flex-col items-center justify-center px-6 py-14 text-center ${className}`}
    >
      {Icon ? (
        <span className="relative mb-5 grid size-20 place-items-center">
          <span className="absolute inset-0 rounded-full bg-brand opacity-25 blur-xl" aria-hidden />
          <span className="glass relative grid size-20 animate-float place-items-center rounded-full">
            <Icon className="size-9 text-brand-cyan" aria-hidden />
          </span>
        </span>
      ) : null}
      <h3 className="text-lg font-semibold text-white">{title}</h3>
      {description ? <p className="mt-1.5 max-w-sm text-sm text-slate-400">{description}</p> : null}
      {action ? <div className="mt-6">{action}</div> : null}
    </motion.div>
  );
}
