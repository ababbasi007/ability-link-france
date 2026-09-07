import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { useAuth } from '../lib/auth'
import { useI18n } from '../i18n'
import {
  changeAdminPassword,
  DEFAULT_ADMIN_SETTINGS,
  saveAdminSettings,
  updateAdminDisplayName,
  type AdminSettings,
} from '../lib/data'
import {
  IconAccessibility,
  IconBell,
  IconCloud,
  IconCode,
  IconCreditCard,
  IconGlobe,
  IconInfo,
  IconLock,
  IconMail,
  IconPencil,
  IconSettings,
  IconShieldCheck,
  IconSliders,
  IconTrash,
  IconUser,
  IconWarning,
  IconX,
} from '../components/icons'
import { PageHeader, StatusPill, Widget } from '../components/PageChrome'

type ModalKind =
  | 'general'
  | 'profile'
  | 'notifications'
  | 'security'
  | 'email'
  | 'payments'
  | 'platform'
  | 'backup'
  | 'advanced'
  | null

function Toggle({
  on,
  onChange,
  label,
  disabled,
}: {
  on: boolean
  onChange: () => void
  label: string
  disabled?: boolean
}) {
  return (
    <button
      type="button"
      className={`st-toggle ${on ? 'on' : ''}`}
      role="switch"
      aria-checked={on}
      aria-label={label}
      disabled={disabled}
      onClick={onChange}
    >
      <span className="st-toggle-knob" />
    </button>
  )
}

function Field({
  label,
  children,
}: {
  label: string
  children: ReactNode
}) {
  return (
    <label className="st-field">
      <span>{label}</span>
      {children}
    </label>
  )
}

function cloneSettings(s: AdminSettings): AdminSettings {
  return structuredClone(s)
}

function formatBackupDate(value: string) {
  if (!value) return 'Never'
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return value
  return d.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function formatLastLogin(user: { metadata?: { lastSignInTime?: string } } | null) {
  const raw = user?.metadata?.lastSignInTime
  if (!raw) return '—'
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return d.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function SettingsPage() {
  const { config, admin, user, refreshConfig, refreshUser } = useAuth()
  const { locale, setLocale } = useI18n()
  const [settings, setSettings] = useState<AdminSettings>(DEFAULT_ADMIN_SETTINGS)
  const [draft, setDraft] = useState<AdminSettings>(DEFAULT_ADMIN_SETTINGS)
  const [modal, setModal] = useState<ModalKind>(null)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [ok, setOk] = useState('')
  const [maintenanceMessage, setMaintenanceMessage] = useState('')
  const [profileName, setProfileName] = useState('')
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [advancedTab, setAdvancedTab] = useState<
    'api' | 'webhooks' | 'integrations' | 'developer'
  >('api')
  const [activeTab, setActiveTab] = useState('account')
  const [a11y, setA11y] = useState({
    largerText: false,
    highContrast: false,
    reduceMotion: false,
    screenReader: true,
    simplified: false,
  })
  const [showPasswordForm, setShowPasswordForm] = useState(false)

  useEffect(() => {
    const next = config?.adminSettings
      ? cloneSettings(config.adminSettings)
      : cloneSettings(DEFAULT_ADMIN_SETTINGS)
    if (config?.maintenanceMessage?.trim()) {
      next.platform.maintenanceMode = true
    }
    setSettings(next)
    setMaintenanceMessage(config?.maintenanceMessage ?? '')
  }, [config])

  useEffect(() => {
    setProfileName(
      user?.displayName?.trim() ||
        (user?.email ? user.email.split('@')[0] : 'Admin User'),
    )
  }, [user])

  const displayName =
    user?.displayName?.trim() ||
    (user?.email ? user.email.split('@')[0] : 'Admin User')
  const roleLabel = admin ? 'Super Admin' : 'Moderator'
  const email = user?.email ?? '—'
  const storagePct = Math.min(
    100,
    Math.round(
      (settings.backup.storageUsedGb / Math.max(1, settings.backup.storageQuotaGb)) * 1000,
    ) / 10,
  )

  const openModal = (
    kind: Exclude<ModalKind, null>,
    opts?: { advancedTab?: 'api' | 'webhooks' | 'integrations' | 'developer' },
  ) => {
    setError('')
    setOk('')
    setDraft(cloneSettings(settings))
    setMaintenanceMessage(
      config?.maintenanceMessage ||
        (settings.platform.maintenanceMode
          ? 'Platform is under maintenance. Please try again later.'
          : ''),
    )
    setCurrentPassword('')
    setNewPassword('')
    setConfirmPassword('')
    setProfileName(displayName)
    if (kind === 'advanced') setAdvancedTab(opts?.advancedTab ?? 'api')
    setModal(kind)
  }

  const persistSettings = async (next: AdminSettings, message?: string) => {
    if (!admin) throw new Error('Only admins can change platform settings')
    setSaving(true)
    setError('')
    try {
      const msg =
        message !== undefined
          ? message
          : next.platform.maintenanceMode
            ? maintenanceMessage.trim() ||
              'Platform is under maintenance. Please try again later.'
            : ''
      await saveAdminSettings(next, { maintenanceMessage: msg })
      await refreshConfig()
      setSettings(cloneSettings(next))
      setOk('Settings saved.')
      setModal(null)
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setSaving(false)
    }
  }

  const saveProfile = async () => {
    setSaving(true)
    setError('')
    try {
      await updateAdminDisplayName(profileName)
      if (newPassword || currentPassword || confirmPassword) {
        if (newPassword !== confirmPassword) {
          throw new Error('New passwords do not match')
        }
        await changeAdminPassword({
          currentPassword,
          newPassword,
        })
      }
      await refreshUser()
      setOk(
        newPassword ? 'Profile and password updated.' : 'Profile updated.',
      )
      setModal(null)
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setSaving(false)
    }
  }

  const modalTitle = useMemo(() => {
    switch (modal) {
      case 'general':
        return 'Edit General Settings'
      case 'profile':
        return 'Edit Profile'
      case 'notifications':
        return 'Manage Notification Preferences'
      case 'security':
        return 'Manage Security'
      case 'email':
        return 'Configure Email'
      case 'payments':
        return 'Manage Payments'
      case 'platform':
        return 'Manage Platform Preferences'
      case 'backup':
        return 'Manage Backups'
      case 'advanced':
        return 'Advanced Settings'
      default:
        return ''
    }
  }, [modal])

  const SETTINGS_TABS = [
    { id: 'account', label: 'Account', icon: <IconUser width={14} height={14} /> },
    { id: 'profile', label: 'Profile', icon: <IconUser width={14} height={14} /> },
    { id: 'notifications', label: 'Notifications', icon: <IconBell width={14} height={14} /> },
    { id: 'security', label: 'Privacy & Security', icon: <IconLock width={14} height={14} /> },
    { id: 'preferences', label: 'App Preferences', icon: <IconSliders width={14} height={14} /> },
    { id: 'language', label: 'Language', icon: <IconGlobe width={14} height={14} /> },
    { id: 'accessibility', label: 'Accessibility', icon: <IconAccessibility width={14} height={14} /> },
    { id: 'connected', label: 'Connected Accounts', icon: <IconCloud width={14} height={14} /> },
  ]

  const avatar =
    user?.photoURL ||
    `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(user?.uid ?? 'admin')}`

  const onTab = (id: string) => {
    setActiveTab(id)
    if (id === 'notifications') openModal('notifications')
    else if (id === 'security') openModal('security')
    else if (id === 'preferences' || id === 'language') openModal('general')
    else if (id === 'connected') openModal('advanced')
  }

  const saveInlineProfile = async () => {
    setSaving(true)
    setError('')
    try {
      await updateAdminDisplayName(profileName)
      if (showPasswordForm && (newPassword || currentPassword || confirmPassword)) {
        if (newPassword !== confirmPassword) throw new Error('New passwords do not match')
        await changeAdminPassword({ currentPassword, newPassword })
      }
      await refreshUser()
      setOk(newPassword ? 'Profile and password updated.' : 'Profile updated.')
      setShowPasswordForm(false)
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setSaving(false)
    }
  }

  const enable2fa = async () => {
    if (!admin) {
      setError('Only admins can change security settings')
      return
    }
    const next = cloneSettings(settings)
    next.security.twoFactorEnabled = !next.security.twoFactorEnabled
    await persistSettings(next)
  }

  return (
    <div className="al-page">
      <PageHeader
        title="Settings"
        subtitle="Manage your account, preferences and app settings to personalize your Ability Link experience."
      />

      <div className="al-settings-tabs" role="tablist">
        {SETTINGS_TABS.map((tab) => (
          <button
            key={tab.id}
            type="button"
            role="tab"
            aria-selected={activeTab === tab.id}
            className={`al-settings-tab${activeTab === tab.id ? ' active' : ''}`}
            onClick={() => onTab(tab.id)}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {error && !modal ? <div className="error" style={{ marginBottom: 12 }}>{error}</div> : null}
      {ok && !modal ? (
        <div className="al-settings-ok" style={{ marginBottom: 12 }}>{ok}</div>
      ) : null}
      {!admin ? (
        <div className="al-settings-note">
          You can edit your profile. Platform settings require an admin account.
        </div>
      ) : null}

      <div className="al-settings-split">
        <div className="al-settings-main">
          <section className="al-settings-card">
            <header className="al-settings-card-head">
              <span className="al-settings-card-icon"><IconUser width={18} height={18} /></span>
              <h2>Account Settings</h2>
            </header>
            <div className="al-settings-fields">
              <label className="al-settings-field">
                <span>Full Name</span>
                <input
                  value={profileName}
                  onChange={(e) => setProfileName(e.target.value)}
                  placeholder="Your name"
                />
              </label>
              <label className="al-settings-field">
                <span>Email Address</span>
                <div className="al-settings-input-row">
                  <input value={email} readOnly />
                  <StatusPill tone="ok">Verified</StatusPill>
                </div>
              </label>
              <label className="al-settings-field">
                <span>Phone Number</span>
                <div className="al-settings-input-row">
                  <div className="al-settings-phone">
                    <span className="al-settings-flag" aria-hidden>PK</span>
                    <input defaultValue="+92 300 1234567" />
                  </div>
                  <StatusPill tone="ok">Verified</StatusPill>
                </div>
              </label>
              <label className="al-settings-field">
                <span>Account Type</span>
                <input value={admin ? 'Administrator' : roleLabel} readOnly />
                <em className="al-settings-hint">You have full access to manage the platform.</em>
              </label>
              <div className="al-settings-field">
                <span>Password</span>
                {!showPasswordForm ? (
                  <div className="al-settings-input-row">
                    <input type="password" value="••••••••••" readOnly />
                    <button
                      type="button"
                      className="al-btn al-btn--outline"
                      onClick={() => setShowPasswordForm(true)}
                    >
                      Change Password
                    </button>
                  </div>
                ) : (
                  <div className="al-settings-pw-form">
                    <input
                      type="password"
                      placeholder="Current password"
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                      autoComplete="current-password"
                    />
                    <input
                      type="password"
                      placeholder="New password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      autoComplete="new-password"
                    />
                    <input
                      type="password"
                      placeholder="Confirm new password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      autoComplete="new-password"
                    />
                    <div style={{ display: 'flex', gap: 8 }}>
                      <button
                        type="button"
                        className="al-btn al-btn--primary"
                        disabled={saving}
                        onClick={() => void saveInlineProfile()}
                      >
                        {saving ? 'Saving…' : 'Save Password'}
                      </button>
                      <button
                        type="button"
                        className="al-btn al-btn--ghost"
                        onClick={() => {
                          setShowPasswordForm(false)
                          setCurrentPassword('')
                          setNewPassword('')
                          setConfirmPassword('')
                        }}
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
            <div className="al-settings-info">
              <IconInfo width={16} height={16} />
              <p>
                Keep your account secure. Use a strong password and enable two-factor
                authentication for added security.
              </p>
            </div>
            <div className="al-settings-card-actions">
              <button
                type="button"
                className="al-btn al-btn--primary"
                disabled={saving}
                onClick={() => void saveInlineProfile()}
              >
                {saving ? 'Saving…' : 'Save Changes'}
              </button>
              <button type="button" className="al-btn al-btn--outline" onClick={() => openModal('profile')}>
                <IconPencil width={14} height={14} /> Edit in modal
              </button>
            </div>
          </section>

          <section className="al-settings-card">
            <header className="al-settings-card-head">
              <span className="al-settings-card-icon"><IconShieldCheck width={18} height={18} /></span>
              <h2>Two-Factor Authentication</h2>
            </header>
            <div className="al-settings-2fa">
              <div>
                <span className="muted">Status</span>{' '}
                <StatusPill tone={settings.security.twoFactorEnabled ? 'ok' : 'danger'}>
                  {settings.security.twoFactorEnabled ? 'Enabled' : 'Not Enabled'}
                </StatusPill>
              </div>
              <button
                type="button"
                className="al-btn al-btn--primary"
                disabled={!admin || saving}
                onClick={() => void enable2fa()}
              >
                {settings.security.twoFactorEnabled ? 'Disable 2FA' : 'Enable 2FA'}
              </button>
            </div>
          </section>

          <section className="al-settings-card al-settings-card--danger">
            <header className="al-settings-card-head">
              <span className="al-settings-card-icon al-settings-card-icon--danger">
                <IconTrash width={18} height={18} />
              </span>
              <h2>Delete Account</h2>
            </header>
            <div className="al-settings-danger-banner">
              <IconWarning width={16} height={16} />
              <p>This action cannot be undone. Please be sure before you proceed.</p>
            </div>
            <button type="button" className="al-btn al-btn--danger" onClick={() => openModal('security')}>
              Delete Account
            </button>
          </section>

          {admin ? (
            <section className="al-settings-card">
              <header className="al-settings-card-head">
                <span className="al-settings-card-icon"><IconSettings width={18} height={18} /></span>
                <h2>Platform Controls</h2>
              </header>
              <p className="muted" style={{ marginTop: 0, fontSize: 13 }}>
                Open admin panels for email, payments, backups and advanced APIs.
              </p>
              <div className="al-settings-quick-grid">
                {(
                  [
                    ['general', 'General', <IconGlobe key="g" width={14} height={14} />],
                    ['email', 'Email', <IconMail key="m" width={14} height={14} />],
                    ['payments', 'Payments', <IconCreditCard key="c" width={14} height={14} />],
                    ['platform', 'Platform', <IconSliders key="s" width={14} height={14} />],
                    ['backup', 'Backup', <IconCloud key="b" width={14} height={14} />],
                    ['advanced', 'Advanced', <IconCode key="a" width={14} height={14} />],
                  ] as const
                ).map(([kind, label, icon]) => (
                  <button
                    key={kind}
                    type="button"
                    className="al-btn al-btn--outline"
                    onClick={() => openModal(kind)}
                  >
                    {icon} {label}
                  </button>
                ))}
              </div>
              <div className="al-detail-kv" style={{ marginTop: 14 }}>
                <div><span>Platform</span><strong>{settings.general.platformName}</strong></div>
                <div><span>Last login</span><strong>{formatLastLogin(user)}</strong></div>
                <div><span>Storage</span><strong>{storagePct}% used</strong></div>
              </div>
            </section>
          ) : null}
        </div>

        <aside className="al-settings-rail">
          <Widget title="Profile Photo">
            <div className="al-settings-photo">
              <img src={avatar} alt="" />
              <div className="al-settings-photo-actions">
                <button type="button" className="al-btn al-btn--outline" onClick={() => openModal('profile')}>
                  Change Photo
                </button>
                <button type="button" className="al-btn al-btn--danger">Remove</button>
              </div>
              <p className="muted" style={{ fontSize: 11.5, margin: '8px 0 0' }}>
                JPG or PNG up to 5MB.
              </p>
            </div>
          </Widget>

          <Widget title="App Preferences">
            <div className="al-settings-prefs">
              <label>
                <span>Theme</span>
                <select defaultValue="light">
                  <option value="light">Light</option>
                  <option value="dark">Dark</option>
                </select>
              </label>
              <label>
                <span>Default Location</span>
                <select defaultValue="abbottabad">
                  <option value="abbottabad">Abbottabad, Pakistan</option>
                  <option value="islamabad">Islamabad, Pakistan</option>
                  <option value="lahore">Lahore, Pakistan</option>
                </select>
              </label>
              <label>
                <span>Time Zone</span>
                <select
                  value={settings.general.timeZone}
                  disabled={!admin}
                  onChange={(e) => {
                    const next = cloneSettings(settings)
                    next.general.timeZone = e.target.value
                    setSettings(next)
                    void persistSettings(next)
                  }}
                >
                  <option value="Asia/Karachi">(GMT+05:00) Islamabad</option>
                  <option value="Europe/Paris">(GMT+01:00) Paris</option>
                  <option value="UTC">UTC</option>
                </select>
              </label>
              <label>
                <span>Date Format</span>
                <select
                  value={settings.general.dateFormat}
                  disabled={!admin}
                  onChange={(e) => {
                    const next = cloneSettings(settings)
                    next.general.dateFormat = e.target.value
                    setSettings(next)
                    void persistSettings(next)
                  }}
                >
                  <option value="DD MMM YYYY">DD MMM YYYY</option>
                  <option value="MM/DD/YYYY">MM/DD/YYYY</option>
                  <option value="YYYY-MM-DD">YYYY-MM-DD</option>
                </select>
              </label>
              <label>
                <span>Language</span>
                <select
                  value={locale}
                  onChange={(e) => setLocale(e.target.value === 'fr' ? 'fr' : 'en')}
                >
                  <option value="en">English</option>
                  <option value="fr">Français</option>
                </select>
              </label>
            </div>
          </Widget>

          <Widget title="Accessibility Preferences">
            <div className="al-settings-a11y">
              {(
                [
                  ['largerText', 'Larger Text'],
                  ['highContrast', 'High Contrast Mode'],
                  ['reduceMotion', 'Reduce Motion'],
                  ['screenReader', 'Screen Reader Support'],
                  ['simplified', 'Simplified Interface'],
                ] as const
              ).map(([key, label]) => (
                <div key={key} className="al-settings-a11y-row">
                  <span>{label}</span>
                  <Toggle
                    label={label}
                    on={a11y[key]}
                    onChange={() => setA11y((s) => ({ ...s, [key]: !s[key] }))}
                  />
                </div>
              ))}
            </div>
          </Widget>

          <div className="al-help-card" style={{ background: '#eff6ff' }}>
            <span className="al-kpi-icon" style={{ background: '#2563eb', color: '#fff' }}>?</span>
            <strong>Need help with settings?</strong>
            <p>Get assistance with your account or preferences.</p>
            <a className="al-btn al-btn--outline" href="/support">Contact Support →</a>
          </div>
        </aside>
      </div>


      {modal ? (
        <div
          className="st-modal-backdrop"
          role="presentation"
          onClick={() => !saving && setModal(null)}
        >
          <div
            className="st-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="st-modal-title"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="st-modal-head">
              <h2 id="st-modal-title">{modalTitle}</h2>
              <button
                type="button"
                className="st-icon-btn"
                disabled={saving}
                onClick={() => setModal(null)}
                aria-label="Close"
              >
                <IconX width={16} height={16} />
              </button>
            </div>
            {error ? <div className="error">{error}</div> : null}

            {modal === 'general' ? (
              <div className="st-form-grid">
                <Field label="Platform Name">
                  <input
                    value={draft.general.platformName}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        general: { ...d.general, platformName: e.target.value },
                      }))
                    }
                  />
                </Field>
                <Field label="Platform Email">
                  <input
                    value={draft.general.platformEmail}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        general: { ...d.general, platformEmail: e.target.value },
                      }))
                    }
                  />
                </Field>
                <Field label="Time Zone">
                  <select
                    value={draft.general.timeZone}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        general: { ...d.general, timeZone: e.target.value },
                      }))
                    }
                  >
                    {[
                      '(UTC+05:00) Asia/Karachi',
                      '(UTC+00:00) UTC',
                      '(UTC-05:00) America/New_York',
                      '(UTC+01:00) Europe/Paris',
                      '(UTC+05:30) Asia/Kolkata',
                    ].map((z) => (
                      <option key={z} value={z}>
                        {z}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label="Date Format">
                  <select
                    value={draft.general.dateFormat}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        general: { ...d.general, dateFormat: e.target.value },
                      }))
                    }
                  >
                    {['MMM d, yyyy', 'dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'].map((f) => (
                      <option key={f} value={f}>
                        {f}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label="Language">
                  <select
                    value={draft.general.language}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        general: { ...d.general, language: e.target.value },
                      }))
                    }
                  >
                    {['English (US)', 'English (UK)', 'French', 'Urdu', 'Arabic'].map((l) => (
                      <option key={l} value={l}>
                        {l}
                      </option>
                    ))}
                  </select>
                </Field>
              </div>
            ) : null}

            {modal === 'profile' ? (
              <div className="st-form-grid">
                <Field label="Display name">
                  <input
                    value={profileName}
                    onChange={(e) => setProfileName(e.target.value)}
                  />
                </Field>
                <Field label="Email">
                  <input value={email} disabled />
                </Field>
                <Field label="Role">
                  <input value={roleLabel} disabled />
                </Field>
                <p className="st-modal-lead st-field-full">
                  To change password, enter your current password and a new one.
                </p>
                <Field label="Current password">
                  <input
                    type="password"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    autoComplete="current-password"
                  />
                </Field>
                <Field label="New password">
                  <input
                    type="password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    autoComplete="new-password"
                  />
                </Field>
                <Field label="Confirm new password">
                  <input
                    type="password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    autoComplete="new-password"
                  />
                </Field>
              </div>
            ) : null}

            {modal === 'notifications' ? (
              <div className="st-form-grid">
                {(
                  [
                    ['email', 'Email Notifications'],
                    ['push', 'Push Notifications'],
                    ['inApp', 'In-App Notifications'],
                    ['reports', 'Report Notifications'],
                    ['reviews', 'Review Notifications'],
                  ] as const
                ).map(([key, label]) => (
                  <div key={key} className="st-check-row">
                    <span>{label}</span>
                    <Toggle
                      label={label}
                      on={draft.notifications[key]}
                      onChange={() =>
                        setDraft((d) => ({
                          ...d,
                          notifications: {
                            ...d.notifications,
                            [key]: !d.notifications[key],
                          },
                        }))
                      }
                    />
                  </div>
                ))}
              </div>
            ) : null}

            {modal === 'security' ? (
              <div className="st-form-grid">
                <div className="st-check-row">
                  <span>Two-Factor Authentication</span>
                  <Toggle
                    label="Two-Factor Authentication"
                    on={draft.security.twoFactorEnabled}
                    onChange={() =>
                      setDraft((d) => ({
                        ...d,
                        security: {
                          ...d.security,
                          twoFactorEnabled: !d.security.twoFactorEnabled,
                        },
                      }))
                    }
                  />
                </div>
                <div className="st-check-row">
                  <span>Login Alerts</span>
                  <Toggle
                    label="Login Alerts"
                    on={draft.security.loginAlerts}
                    onChange={() =>
                      setDraft((d) => ({
                        ...d,
                        security: {
                          ...d.security,
                          loginAlerts: !d.security.loginAlerts,
                        },
                      }))
                    }
                  />
                </div>
                <Field label="Session timeout (minutes)">
                  <input
                    type="number"
                    min={5}
                    max={480}
                    value={draft.security.sessionTimeoutMinutes}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        security: {
                          ...d.security,
                          sessionTimeoutMinutes: Number(e.target.value) || 30,
                        },
                      }))
                    }
                  />
                </Field>
                <Field label="Password expiry (days)">
                  <input
                    type="number"
                    min={0}
                    max={365}
                    value={draft.security.passwordExpiryDays}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        security: {
                          ...d.security,
                          passwordExpiryDays: Number(e.target.value) || 90,
                        },
                      }))
                    }
                  />
                </Field>
              </div>
            ) : null}

            {modal === 'email' ? (
              <div className="st-form-grid">
                <Field label="SMTP Server">
                  <input
                    value={draft.email.smtpServer}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        email: { ...d.email, smtpServer: e.target.value },
                      }))
                    }
                  />
                </Field>
                <Field label="SMTP Port">
                  <input
                    value={draft.email.smtpPort}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        email: { ...d.email, smtpPort: e.target.value },
                      }))
                    }
                  />
                </Field>
                <Field label="From Email">
                  <input
                    value={draft.email.fromEmail}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        email: { ...d.email, fromEmail: e.target.value },
                      }))
                    }
                  />
                </Field>
                <Field label="From Name">
                  <input
                    value={draft.email.fromName}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        email: { ...d.email, fromName: e.target.value },
                      }))
                    }
                  />
                </Field>
                <Field label="Email templates count">
                  <input
                    type="number"
                    min={0}
                    value={draft.email.templateCount}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        email: {
                          ...d.email,
                          templateCount: Number(e.target.value) || 0,
                        },
                      }))
                    }
                  />
                </Field>
              </div>
            ) : null}

            {modal === 'payments' ? (
              <div className="st-form-grid">
                <Field label="Active payment gateways">
                  <input
                    type="number"
                    min={0}
                    value={draft.payments.gatewaysActive}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        payments: {
                          ...d.payments,
                          gatewaysActive: Number(e.target.value) || 0,
                        },
                      }))
                    }
                  />
                </Field>
                <Field label="Currency">
                  <input
                    value={draft.payments.currency}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        payments: { ...d.payments, currency: e.target.value },
                      }))
                    }
                  />
                </Field>
                <Field label="Subscription plans">
                  <input
                    type="number"
                    min={0}
                    value={draft.payments.subscriptionPlans}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        payments: {
                          ...d.payments,
                          subscriptionPlans: Number(e.target.value) || 0,
                        },
                      }))
                    }
                  />
                </Field>
                <Field label="Transaction fee">
                  <input
                    value={draft.payments.transactionFee}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        payments: {
                          ...d.payments,
                          transactionFee: e.target.value,
                        },
                      }))
                    }
                  />
                </Field>
              </div>
            ) : null}

            {modal === 'platform' ? (
              <div className="st-form-grid">
                <div className="st-check-row">
                  <span>Maintenance Mode</span>
                  <Toggle
                    label="Maintenance Mode"
                    on={draft.platform.maintenanceMode}
                    onChange={() =>
                      setDraft((d) => ({
                        ...d,
                        platform: {
                          ...d.platform,
                          maintenanceMode: !d.platform.maintenanceMode,
                        },
                      }))
                    }
                  />
                </div>
                {draft.platform.maintenanceMode ? (
                  <Field label="Maintenance message">
                    <textarea
                      rows={3}
                      value={maintenanceMessage}
                      onChange={(e) => setMaintenanceMessage(e.target.value)}
                    />
                  </Field>
                ) : null}
                <div className="st-check-row">
                  <span>User Registration</span>
                  <Toggle
                    label="User Registration"
                    on={draft.platform.registrationOpen}
                    onChange={() =>
                      setDraft((d) => ({
                        ...d,
                        platform: {
                          ...d.platform,
                          registrationOpen: !d.platform.registrationOpen,
                        },
                      }))
                    }
                  />
                </div>
                <Field label="Review moderation">
                  <select
                    value={draft.platform.reviewModeration}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        platform: {
                          ...d.platform,
                          reviewModeration: e.target.value,
                        },
                      }))
                    }
                  >
                    {['Auto + Manual', 'Manual only', 'Auto only'].map((v) => (
                      <option key={v} value={v}>
                        {v}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label="Default map view">
                  <select
                    value={draft.platform.defaultMapView}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        platform: {
                          ...d.platform,
                          defaultMapView: e.target.value,
                        },
                      }))
                    }
                  >
                    {['Standard', 'Satellite', 'Terrain'].map((v) => (
                      <option key={v} value={v}>
                        {v}
                      </option>
                    ))}
                  </select>
                </Field>
              </div>
            ) : null}

            {modal === 'backup' ? (
              <div className="st-form-grid">
                <Field label="Backup frequency">
                  <select
                    value={draft.backup.frequency}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        backup: { ...d.backup, frequency: e.target.value },
                      }))
                    }
                  >
                    {['Hourly', 'Daily', 'Weekly', 'Monthly'].map((v) => (
                      <option key={v} value={v}>
                        {v}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label="Data retention">
                  <select
                    value={draft.backup.retention}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        backup: { ...d.backup, retention: e.target.value },
                      }))
                    }
                  >
                    {['30 Days', '90 Days', '1 Year', '2 Years', 'Forever'].map((v) => (
                      <option key={v} value={v}>
                        {v}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label="Storage used (GB)">
                  <input
                    type="number"
                    min={0}
                    step={0.1}
                    value={draft.backup.storageUsedGb}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        backup: {
                          ...d.backup,
                          storageUsedGb: Number(e.target.value) || 0,
                        },
                      }))
                    }
                  />
                </Field>
                <Field label="Storage quota (GB)">
                  <input
                    type="number"
                    min={1}
                    value={draft.backup.storageQuotaGb}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        backup: {
                          ...d.backup,
                          storageQuotaGb: Number(e.target.value) || 100,
                        },
                      }))
                    }
                  />
                </Field>
                <div className="st-field-full">
                  <button
                    type="button"
                    className="st-card-btn"
                    disabled={saving}
                    onClick={() =>
                      setDraft((d) => ({
                        ...d,
                        backup: {
                          ...d.backup,
                          lastBackupAt: new Date().toISOString(),
                        },
                      }))
                    }
                  >
                    <IconCloud width={14} height={14} />
                    Mark backup completed now
                  </button>
                  <p className="st-modal-lead">
                    Last backup: {formatBackupDate(draft.backup.lastBackupAt)}
                  </p>
                </div>
              </div>
            ) : null}

            {modal === 'advanced' ? (
              <div className="st-form-grid">
                <div className="st-adv-tabs st-field-full">
                  {(
                    [
                      ['api', 'API'],
                      ['webhooks', 'Webhooks'],
                      ['integrations', 'Integrations'],
                      ['developer', 'Developer'],
                    ] as const
                  ).map(([tab, label]) => (
                    <button
                      key={tab}
                      type="button"
                      className={advancedTab === tab ? 'on' : ''}
                      onClick={() => setAdvancedTab(tab)}
                    >
                      {label}
                    </button>
                  ))}
                </div>
                {advancedTab === 'api' ? (
                  <Field label="API base URL">
                    <input
                      value={draft.advanced.apiBaseUrl}
                      onChange={(e) =>
                        setDraft((d) => ({
                          ...d,
                          advanced: { ...d.advanced, apiBaseUrl: e.target.value },
                        }))
                      }
                    />
                  </Field>
                ) : null}
                {advancedTab === 'webhooks' ? (
                  <>
                    <div className="st-check-row">
                      <span>Webhooks enabled</span>
                      <Toggle
                        label="Webhooks enabled"
                        on={draft.advanced.webhooksEnabled}
                        onChange={() =>
                          setDraft((d) => ({
                            ...d,
                            advanced: {
                              ...d.advanced,
                              webhooksEnabled: !d.advanced.webhooksEnabled,
                            },
                          }))
                        }
                      />
                    </div>
                    <Field label="Webhook URL">
                      <input
                        value={draft.advanced.webhooksUrl}
                        onChange={(e) =>
                          setDraft((d) => ({
                            ...d,
                            advanced: {
                              ...d.advanced,
                              webhooksUrl: e.target.value,
                            },
                          }))
                        }
                        placeholder="https://…"
                      />
                    </Field>
                  </>
                ) : null}
                {advancedTab === 'integrations' ? (
                  <Field label="Integrations notes">
                    <textarea
                      rows={4}
                      value={draft.advanced.integrationsNotes}
                      onChange={(e) =>
                        setDraft((d) => ({
                          ...d,
                          advanced: {
                            ...d.advanced,
                            integrationsNotes: e.target.value,
                          },
                        }))
                      }
                      placeholder="Stripe, FCM, Maps keys notes…"
                    />
                  </Field>
                ) : null}
                {advancedTab === 'developer' ? (
                  <div className="st-check-row">
                    <span>Developer mode</span>
                    <Toggle
                      label="Developer mode"
                      on={draft.advanced.developerMode}
                      onChange={() =>
                        setDraft((d) => ({
                          ...d,
                          advanced: {
                            ...d.advanced,
                            developerMode: !d.advanced.developerMode,
                          },
                        }))
                      }
                    />
                  </div>
                ) : null}
              </div>
            ) : null}

            <div className="st-modal-actions">
              <button
                type="button"
                className="st-btn ghost"
                disabled={saving}
                onClick={() => setModal(null)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="st-btn primary"
                disabled={saving}
                onClick={() => {
                  if (modal === 'profile') void saveProfile()
                  else void persistSettings(draft, maintenanceMessage)
                }}
              >
                {saving ? 'Saving…' : 'Save changes'}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}
