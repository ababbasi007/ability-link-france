import { useState, type FormEvent } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useAuth } from '../lib/auth'
import { firebaseReady } from '../lib/firebase'
import {
  IconChart,
  IconChevronLeft,
  IconEye,
  IconLayers,
  IconLock,
  IconMail,
  IconSettings,
  IconShieldCheck,
  IconUsers,
} from '../components/icons'

export function LoginPage() {
  const { login, user, allowed, loading, ready } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [showPw, setShowPw] = useState(false)
  const [remember, setRemember] = useState(true)

  if (!loading && user && allowed) return <Navigate to="/" replace />

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      await login(email.trim(), password)
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="al-login">
      <aside className="al-login-brand">
        <div className="al-login-brand-top">
          <div className="brand-mark" aria-hidden>
            AL
          </div>
          <div>
            <strong>Ability Link</strong>
            <span>Access · Support · Opportunity</span>
          </div>
        </div>
        <h1>Building a more inclusive world.</h1>
        <p>Manage users, services, bookings and more from a powerful admin dashboard.</p>
        <ul className="al-login-features">
          <li>
            <span className="icon">
              <IconUsers width={16} height={16} />
            </span>
            <div>
              <strong>Manage Users</strong>
              <span>Oversee users, providers and caregivers</span>
            </div>
          </li>
          <li>
            <span className="icon">
              <IconLayers width={16} height={16} />
            </span>
            <div>
              <strong>Track Services</strong>
              <span>Monitor bookings, programs and assessments</span>
            </div>
          </li>
          <li>
            <span className="icon">
              <IconChart width={16} height={16} />
            </span>
            <div>
              <strong>View Analytics</strong>
              <span>Insights for better decisions</span>
            </div>
          </li>
          <li>
            <span className="icon">
              <IconSettings width={16} height={16} />
            </span>
            <div>
              <strong>Control Platform</strong>
              <span>Manage content, settings and security</span>
            </div>
          </li>
        </ul>
        <p className="al-login-script">Inclusive People. Stronger Communities.</p>
      </aside>

      <section className="al-login-form-wrap">
        <a className="al-login-back" href="https://abilitylink.com" target="_blank" rel="noreferrer">
          <IconChevronLeft width={14} height={14} /> Back to Website
        </a>

        <form className="al-login-card" onSubmit={onSubmit}>
          <div className="al-login-card-brand">
            <div className="brand-mark" aria-hidden>
              AL
            </div>
            <span>Admin Panel</span>
          </div>
          <h2>Sign in to Admin Panel</h2>
          <p className="muted">Access your dashboard to manage the platform.</p>

          {!ready || !firebaseReady ? (
            <div className="error">
              Firebase web config missing. Copy <code>.env.example</code> to{' '}
              <code>.env.local</code> and add your Web app keys.
            </div>
          ) : null}
          {user && !allowed ? (
            <div className="error">
              Signed in, but this UID is not an admin/moderator. Add it to
              platformConfig/settings.
            </div>
          ) : null}
          {error ? <div className="error">{error}</div> : null}

          <label className="field">
            Email Address
            <div className="al-login-input">
              <IconMail width={15} height={15} />
              <input
                type="email"
                autoComplete="username"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@abilitylink.com"
                required
              />
            </div>
          </label>

          <label className="field">
            <span style={{ display: 'flex', justifyContent: 'space-between' }}>
              Password
              <button type="button" className="al-btn al-btn--ghost" style={{ padding: 0, fontSize: 12 }}>
                Forgot Password?
              </button>
            </span>
            <div className="al-login-input">
              <IconLock width={15} height={15} />
              <input
                type={showPw ? 'text' : 'password'}
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                required
              />
              <button
                type="button"
                className="icon-btn"
                aria-label={showPw ? 'Hide password' : 'Show password'}
                onClick={() => setShowPw((v) => !v)}
              >
                <IconEye width={15} height={15} />
              </button>
            </div>
          </label>

          <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, marginBottom: 12 }}>
            <input
              type="checkbox"
              checked={remember}
              onChange={(e) => setRemember(e.target.checked)}
              style={{ accentColor: '#2563eb' }}
            />
            Remember me
          </label>

          <button
            className="al-btn al-btn--primary"
            type="submit"
            disabled={busy || !firebaseReady}
            style={{ width: '100%', padding: '12px 16px' }}
          >
            {busy ? 'Signing in…' : 'Sign In'} →
          </button>

          <div className="al-login-or">
            <span>or</span>
          </div>

          <button type="button" className="al-btn al-btn--outline" style={{ width: '100%' }} disabled>
            Sign in with Google
          </button>

          <div className="al-login-secure">
            <IconShieldCheck width={16} height={16} />
            <div>
              <strong>Authorized personnel only</strong>
              <span>This system is restricted to authorized administrators.</span>
            </div>
          </div>
        </form>

        <footer className="al-login-foot">
          © 2026 Ability Link. All rights reserved. ·{' '}
          <Link to="/legal-rights">Privacy Policy</Link> ·{' '}
          <Link to="/legal-rights">Terms of Service</Link> ·{' '}
          <Link to="/support">Support</Link>
        </footer>
      </section>
    </div>
  )
}
