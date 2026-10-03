import { Routes, Route, Navigate } from 'react-router-dom';
import DsDiagnostic from './pages/dsDiagnostic.jsx';
import DsSkillGPS from './pages/dsSkillGPS.jsx';

/**
 * Router — the app exposes only the two modules, with no login:
 * - `/diagnostic` -> Diagnostic_Page
 * - `/skillgps`   -> SkillGPS_Page
 * - `/` and any unmatched path redirect to `/diagnostic`.
 *
 * Authentication was removed by request. Reference and student data are read
 * and written with the Supabase Anon_Key under anonymous-access RLS policies
 * (see supabase/dsschema.sql). This is a local/demo setup, not production auth.
 */
export default function DsApp() {
  return (
    <Routes>
      <Route path="/diagnostic" element={<DsDiagnostic />} />
      <Route path="/skillgps" element={<DsSkillGPS />} />
      <Route path="/" element={<Navigate to="/diagnostic" replace />} />
      <Route path="*" element={<Navigate to="/diagnostic" replace />} />
    </Routes>
  );
}
