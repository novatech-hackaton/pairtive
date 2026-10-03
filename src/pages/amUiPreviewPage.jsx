import { useState } from 'react';
import { Flag, Sparkles } from 'lucide-react';
import { AM_SUBJECTS } from '../../shared/amSubjects.js';
import { AmButton, AmIconButton } from '../components/amButton.jsx';
import { AmCard } from '../components/amCard.jsx';
import { AmSubjectChip } from '../components/amSubjectChip.jsx';
import { AmAvatar, AmAvatarStack } from '../components/amAvatar.jsx';
import { AmStarInput, AmRatingBadge } from '../components/amStars.jsx';
import { AmField, AmSwitch } from '../components/amField.jsx';
import { AmModal } from '../components/amModal.jsx';
import { AmEmptyState } from '../components/amEmptyState.jsx';
import { AmCountdownRing } from '../components/amCountdownRing.jsx';
import { AmLogo } from '../components/amLogo.jsx';

// Dev-only gallery of the UI kit (route /ui). Not shipped in production routes.
export default function AmUiPreviewPage() {
  const [stars, setStars] = useState(4);
  const [sw, setSw] = useState(true);
  const [open, setOpen] = useState(false);
  return (
    <div className="mx-auto max-w-4xl space-y-8 p-6">
      <AmLogo />
      <section className="flex flex-wrap gap-3">
        <AmButton>Primary</AmButton>
        <AmButton variant="secondary">Secondary</AmButton>
        <AmButton variant="ghost">Ghost</AmButton>
        <AmButton variant="danger">Danger</AmButton>
        <AmButton variant="success" icon={Sparkles}>Success</AmButton>
        <AmButton loading>Loading</AmButton>
        <AmIconButton icon={Flag} label="Report" />
      </section>
      <section className="flex flex-wrap gap-2">
        {AM_SUBJECTS.map((s) => <AmSubjectChip key={s} subject={s} />)}
      </section>
      <section className="flex items-center gap-4">
        <AmAvatar name="Ana Cruz" size="lg" ring online />
        <AmAvatarStack people={[{ id: 1, name: 'Ana' }, { id: 2, name: 'Ben' }, { id: 3, name: 'Cy' }, { id: 4, name: 'Dee' }]} />
        <AmRatingBadge avg={4.6} count={12} />
        <AmRatingBadge count={0} />
        <AmCountdownRing secondsLeft={8} total={15} />
      </section>
      <AmCard className="max-w-md space-y-4">
        <AmField label="Email" placeholder="you@example.com" />
        <AmStarInput value={stars} onChange={setStars} />
        <AmSwitch checked={sw} onChange={setSw} label="Same school only" description="Match within your school." />
        <AmButton onClick={() => setOpen(true)}>Open modal</AmButton>
      </AmCard>
      <AmEmptyState icon={Sparkles} title="Nothing here yet" description="A friendly empty state." action={<AmButton>Do something</AmButton>} />
      <AmModal open={open} onClose={() => setOpen(false)} title="Example modal" description="Focus-trapped and escapable." footer={<AmButton onClick={() => setOpen(false)}>Close</AmButton>}>
        <p className="text-sm text-slate-300">Modal body content.</p>
      </AmModal>
    </div>
  );
}
