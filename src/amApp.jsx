import { Suspense, lazy } from 'react';
import { Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';
import { RotateCw, TriangleAlert } from 'lucide-react';
import { useAmAuth } from './lib/amAuth.jsx';
import { useAmMastery } from './lib/amMastery.jsx';
import { amSupabaseConfigured } from './lib/amSupabase.js';
import { useAmUnread } from './lib/amRealtime.js';
import { AmLayout } from './components/amLayout.jsx';
import { AmFullScreenLoader } from './components/amLogo.jsx';
import { AmEmptyState } from './components/amEmptyState.jsx';
import { AmButton } from './components/amButton.jsx';
import { AmInviteListener } from './components/amInviteListener.jsx';
import { AmSetupNotice } from './pages/amSetupNotice.jsx';

const AmLoginPage = lazy(() => import('./pages/amLoginPage.jsx'));
const AmSignupPage = lazy(() => import('./pages/amSignupPage.jsx'));
const AmOnboardingPage = lazy(() => import('./pages/amOnboardingPage.jsx'));
const AmHomePage = lazy(() => import('./pages/amHomePage.jsx'));
const AmMatchPage = lazy(() => import('./pages/amMatchPage.jsx'));
const AmSessionPage = lazy(() => import('./pages/amSessionPage.jsx'));
const AmRatePage = lazy(() => import('./pages/amRatePage.jsx'));
const AmMessagesPage = lazy(() => import('./pages/amMessagesPage.jsx'));
const AmThreadPage = lazy(() => import('./pages/amThreadPage.jsx'));
const AmProfilePage = lazy(() => import('./pages/amProfilePage.jsx'));
const AmSuspendedPage = lazy(() => import('./pages/amSuspendedPage.jsx'));
const AmUiPreviewPage = lazy(() => import('./pages/amUiPreviewPage.jsx'));
const AmDiagnosticPage = lazy(() => import('./pages/amDiagnosticPage.jsx'));
const AmSkillGpsPage = lazy(() => import('./pages/amSkillGpsPage.jsx'));

/** Gate: signed in -> profile complete -> not suspended. */
function AmGuard({ allowIncomplete = false, allowSuspended = false }) {
  const { user, loading, profile, profileComplete, isSuspended } = useAmAuth();
  const location = useLocation();
  if (loading) return <AmFullScreenLoader />;
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  if (!allowSuspended && isSuspended) return <Navigate to="/suspended" replace />;
  if (!allowIncomplete && !profileComplete) return <Navigate to="/onboarding" replace />;
  return <Outlet />;
}

/**
 * Gate for /match: the user needs at least one Mastery_Record (completed diagnostic).
 * Fails closed: a load error shows a retry card instead of entering /match.
 */
export function AmDiagnosticGuard({ children }) {
  const { count, loading, error, refresh } = useAmMastery();
  if (loading) return <AmFullScreenLoader />;
  if (error) {
    return (
      <AmEmptyState
        icon={TriangleAlert}
        title="Couldn't load your diagnostic results"
        description="We need your results before matching. Check your connection and try again."
        action={
          <AmButton icon={RotateCw} onClick={() => refresh()}>
            Try again
          </AmButton>
        }
      />
    );
  }
  if (!count) return <Navigate to="/diagnostic" replace state={{ from: '/match', reason: 'diagnostic-required' }} />;
  return children ?? <Outlet />;
}

function AmPublicOnly() {
  const { user, loading } = useAmAuth();
  if (loading) return <AmFullScreenLoader />;
  if (user) return <Navigate to="/home" replace />;
  return <Outlet />;
}

function AmShell() {
  const { user, profile, signOut } = useAmAuth();
  const { unread } = useAmUnread(user?.id);
  return (
    <AmLayout profile={profile} unread={unread} onSignOut={signOut}>
      <Outlet />
    </AmLayout>
  );
}

function AmGlobalListeners() {
  const { user } = useAmAuth();
  return (
    <>
      <AmInviteListener userId={user?.id} />
      <Outlet />
    </>
  );
}

export default function AmApp() {
  if (!amSupabaseConfigured) return <AmSetupNotice />;
  return (
    <Suspense fallback={<AmFullScreenLoader />}>
      <Routes>
        <Route element={<AmPublicOnly />}>
          <Route path="/login" element={<AmLoginPage />} />
          <Route path="/signup" element={<AmSignupPage />} />
        </Route>

        <Route element={<AmGuard allowIncomplete />}>
          <Route path="/onboarding" element={<AmOnboardingPage />} />
        </Route>
        <Route element={<AmGuard allowSuspended allowIncomplete />}>
          <Route path="/suspended" element={<AmSuspendedPage />} />
        </Route>

        <Route element={<AmGuard />}>
          <Route element={<AmGlobalListeners />}>
            <Route path="/session/:sessionId" element={<AmSessionPage />} />
            <Route element={<AmShell />}>
              <Route path="/home" element={<AmHomePage />} />
              <Route path="/diagnostic" element={<AmDiagnosticPage />} />
              <Route path="/skillgps" element={<AmSkillGpsPage />} />
              <Route element={<AmDiagnosticGuard />}>
                <Route path="/match" element={<AmMatchPage />} />
              </Route>
              <Route path="/rate/:sessionId" element={<AmRatePage />} />
              <Route path="/messages" element={<AmMessagesPage />} />
              <Route path="/messages/:conversationId" element={<AmThreadPage />} />
              <Route path="/profile" element={<AmProfilePage />} />
            </Route>
          </Route>
        </Route>

        {import.meta.env.DEV ? <Route path="/ui" element={<AmUiPreviewPage />} /> : null}
        <Route path="*" element={<Navigate to="/home" replace />} />
      </Routes>
    </Suspense>
  );
}
