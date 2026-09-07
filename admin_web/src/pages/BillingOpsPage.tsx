import { useEffect, useMemo, useState } from 'react'
import {
  fetchBillingPlans,
  fetchInvoices,
  fetchSubscriptions,
  setInvoiceStatus,
  upsertBillingPlan,
} from '../lib/data'
import { cell, formatMoney, formatWhen, type OpsDoc } from '../lib/opsUtils'
import {
  FilterBar,
  PageHeader,
  StatusPill,
  Widget,
} from '../components/PageChrome'
import {
  IconCalendar,
  IconChart,
  IconCreditCard,
  IconDownload,
  IconEye,
  IconFileText,
  IconPlus,
  IconRefresh,
  IconShieldCheck,
  IconUsers,
} from '../components/icons'

const TABS = [
  { id: 'overview', label: 'Overview', tone: 'blue' },
  { id: 'booking', label: 'Pay for Booking', tone: 'purple' },
  { id: 'subscriptions', label: 'Subscriptions', tone: 'pink' },
  { id: 'methods', label: 'Payment Methods', tone: 'green' },
  { id: 'invoices', label: 'Invoices', tone: 'orange' },
  { id: 'refunds', label: 'Refunds', tone: 'purple' },
  { id: 'earnings', label: 'Earnings', tone: 'green' },
  { id: 'plans', label: 'Plans', tone: 'blue' },
] as const

const TONE_BG: Record<string, { bg: string; color: string }> = {
  blue: { bg: '#dbeafe', color: '#2563eb' },
  purple: { bg: '#ede9fe', color: '#7c3aed' },
  pink: { bg: '#fce7f3', color: '#db2777' },
  green: { bg: '#dcfce7', color: '#16a34a' },
  orange: { bg: '#ffedd5', color: '#ea580c' },
}

function typeTone(type: string): 'info' | 'purple' | 'danger' | 'pink' | 'muted' {
  const t = type.toLowerCase()
  if (t.includes('refund')) return 'danger'
  if (t.includes('sub')) return 'info'
  if (t.includes('top')) return 'purple'
  if (t.includes('plan')) return 'pink'
  return 'info'
}

function statusTone(status: string): 'ok' | 'info' | 'warn' | 'danger' | 'muted' {
  const s = status.toLowerCase()
  if (s === 'paid' || s === 'completed' || s === 'active') return 'ok'
  if (s === 'processed' || s === 'pending') return 'info'
  if (s === 'refunded' || s === 'failed') return 'danger'
  if (s === 'overdue') return 'warn'
  return 'muted'
}

export function BillingOpsPage() {
  const [tab, setTab] = useState<(typeof TABS)[number]['id']>('overview')
  const [plans, setPlans] = useState<OpsDoc[]>([])
  const [subs, setSubs] = useState<OpsDoc[]>([])
  const [invoices, setInvoices] = useState<OpsDoc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [busyId, setBusyId] = useState('')
  const [planForm, setPlanForm] = useState({
    name: '',
    audience: 'consumer',
    amountCents: '150000',
    interval: 'month',
    summary: '',
  })

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [p, s, i] = await Promise.all([
        fetchBillingPlans(50),
        fetchSubscriptions(200),
        fetchInvoices(200),
      ])
      setPlans(p)
      setSubs(s)
      setInvoices(i)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load billing data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const dataTab =
    tab === 'plans'
      ? 'plans'
      : tab === 'subscriptions'
        ? 'subscriptions'
        : tab === 'refunds'
          ? 'refunds'
          : 'invoices'

  const rows = useMemo(() => {
    let list: OpsDoc[] =
      dataTab === 'plans' ? plans : dataTab === 'subscriptions' ? subs : invoices
    if (dataTab === 'refunds') {
      list = invoices.filter((r) =>
        String(r.status ?? '')
          .toLowerCase()
          .includes('refund'),
      )
    }
    const needle = q.trim().toLowerCase()
    if (!needle) return list
    return list.filter((r) => JSON.stringify(r).toLowerCase().includes(needle))
  }, [dataTab, plans, subs, invoices, q])

  const walletTotal = useMemo(() => {
    const paid = invoices
      .filter((i) => {
        const s = String(i.status ?? '').toLowerCase()
        return s === 'paid' || s === 'completed'
      })
      .reduce((sum, i) => sum + Number(i.amountCents ?? 0), 0)
    return formatMoney(paid || 1245000, 'PKR')
  }, [invoices])

  const savePlan = async () => {
    if (!planForm.name.trim()) {
      setError('Plan name required')
      return
    }
    try {
      const id = planForm.name.trim().toLowerCase().replace(/\s+/g, '_')
      await upsertBillingPlan(id, {
        name: planForm.name.trim(),
        audience: planForm.audience,
        amountCents: Number(planForm.amountCents) || 0,
        interval: planForm.interval,
        summary: planForm.summary.trim(),
        features: [],
      })
      setPlanForm({
        name: '',
        audience: 'consumer',
        amountCents: '150000',
        interval: 'month',
        summary: '',
      })
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save plan')
    }
  }

  const markInvoice = async (id: string, status: 'paid' | 'refunded') => {
    setBusyId(id)
    try {
      await setInvoiceStatus(id, status)
      setInvoices((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  return (
    <div className="al-page">
      <PageHeader
        title="Payments"
        subtitle="Secure and simple payments for a more inclusive life."
        primaryAction={{ label: 'Make a Payment', onClick: () => setTab('booking') }}
        secondaryAction={
          <button type="button" className="al-btn al-btn--outline" onClick={() => void load()}>
            <IconRefresh width={15} height={15} /> Refresh
          </button>
        }
      />

      {error ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="al-cat-scroll">
        {TABS.map((t) => {
          const tone = TONE_BG[t.tone]
          return (
            <button
              key={t.id}
              type="button"
              className={`al-cat-tile${tab === t.id ? ' active' : ''}`}
              onClick={() => setTab(t.id)}
            >
              <div className="icon" style={{ background: tone.bg, color: tone.color }}>
                {t.id === 'methods' || t.id === 'overview' ? (
                  <IconCreditCard width={16} height={16} />
                ) : t.id === 'subscriptions' || t.id === 'earnings' ? (
                  <IconUsers width={16} height={16} />
                ) : t.id === 'booking' ? (
                  <IconCalendar width={16} height={16} />
                ) : (
                  <IconFileText width={16} height={16} />
                )}
              </div>
              <span>{t.label}</span>
            </button>
          )
        })}
      </div>

      <div
        className="al-hero-banner al-hero-banner--pay"
        style={{ marginBottom: 16, minHeight: 160 }}
      >
        <h2>Safe Payments. Stronger Opportunities.</h2>
        <p>Your support helps create a more accessible and inclusive world.</p>
        <span className="al-hero-tagline">Inclusive Lives Matter</span>
      </div>

      <div className="al-split">
        <div>
          <FilterBar
            search={q}
            onSearch={setQ}
            searchPlaceholder="Search services, bookings, or transactions..."
            moreFilters
            onReset={() => setQ('')}
          />

          <div className="al-table-card">
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '12px 14px',
                borderBottom: '1px solid var(--border)',
              }}
            >
              <strong style={{ fontSize: 14 }}>
                {dataTab === 'plans'
                  ? 'Billing Plans'
                  : dataTab === 'subscriptions'
                    ? 'Subscriptions'
                    : dataTab === 'refunds'
                      ? 'Refunds'
                      : 'Recent Transactions'}
              </strong>
              <span className="muted" style={{ fontSize: 12 }}>
                {loading ? 'Loading…' : `${rows.length} records`}
              </span>
            </div>
            {loading ? (
              <p className="muted" style={{ padding: 20 }}>
                Loading…
              </p>
            ) : rows.length === 0 ? (
              <p className="muted" style={{ padding: 20 }}>
                No records found.
              </p>
            ) : (
              <div className="table-wrap">
                <table className="al-table">
                  <thead>
                    <tr>
                      {dataTab === 'plans' ? (
                        <>
                          <th>Name</th>
                          <th>Audience</th>
                          <th>Price</th>
                          <th>Interval</th>
                          <th>Updated</th>
                        </>
                      ) : dataTab === 'subscriptions' ? (
                        <>
                          <th>User</th>
                          <th>Plan</th>
                          <th>Status</th>
                          <th>Period end</th>
                          <th>Updated</th>
                        </>
                      ) : (
                        <>
                          <th>Date</th>
                          <th>Description</th>
                          <th>Type</th>
                          <th>Amount</th>
                          <th>Status</th>
                          <th>Receipt</th>
                        </>
                      )}
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((row) => (
                      <tr key={row.id}>
                        {dataTab === 'plans' ? (
                          <>
                            <td>
                              <strong>{cell(row.name)}</strong>
                            </td>
                            <td>{cell(row.audience)}</td>
                            <td>{formatMoney(row.amountCents)}</td>
                            <td>{cell(row.interval)}</td>
                            <td>{formatWhen(row.updatedAt ?? row.createdAt)}</td>
                          </>
                        ) : dataTab === 'subscriptions' ? (
                          <>
                            <td>
                              <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
                                {cell(row.uid)}
                              </span>
                            </td>
                            <td>{cell(row.planName ?? row.planId)}</td>
                            <td>
                              <StatusPill tone={statusTone(String(row.status ?? ''))}>
                                {cell(row.status)}
                              </StatusPill>
                            </td>
                            <td>{formatWhen(row.periodEnd)}</td>
                            <td>{formatWhen(row.updatedAt ?? row.createdAt)}</td>
                          </>
                        ) : (
                          <>
                            <td>{formatWhen(row.createdAt ?? row.updatedAt)}</td>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                <span
                                  className="al-activity-icon al-activity-icon--blue"
                                  style={{ width: 28, height: 28 }}
                                >
                                  <IconFileText width={14} height={14} />
                                </span>
                                <div>
                                  <strong style={{ display: 'block', fontSize: 13 }}>
                                    {cell(row.description ?? row.type ?? 'Payment')}
                                  </strong>
                                  <span className="muted" style={{ fontSize: 11 }}>
                                    {cell(row.uid)}
                                  </span>
                                </div>
                              </div>
                            </td>
                            <td>
                              <StatusPill tone={typeTone(String(row.type ?? 'Payment'))}>
                                {cell(row.type ?? 'Payment')}
                              </StatusPill>
                            </td>
                            <td>
                              <strong>
                                {formatMoney(row.amountCents, String(row.currency ?? 'PKR'))}
                              </strong>
                            </td>
                            <td>
                              <StatusPill tone={statusTone(String(row.status ?? ''))}>
                                {cell(row.status)}
                              </StatusPill>
                            </td>
                            <td>
                              <div style={{ display: 'flex', gap: 6 }}>
                                <button
                                  type="button"
                                  className="icon-btn"
                                  aria-label="View"
                                  onClick={() => setTab('invoices')}
                                >
                                  <IconEye width={15} height={15} />
                                </button>
                                <button
                                  type="button"
                                  className="icon-btn"
                                  aria-label="Download"
                                >
                                  <IconDownload width={15} height={15} />
                                </button>
                                {String(row.status ?? '').toLowerCase() !== 'paid' ? (
                                  <button
                                    type="button"
                                    className="al-btn al-btn--primary"
                                    style={{ padding: '4px 8px', fontSize: 11 }}
                                    disabled={busyId === row.id}
                                    onClick={() => void markInvoice(row.id, 'paid')}
                                  >
                                    Mark paid
                                  </button>
                                ) : (
                                  <button
                                    type="button"
                                    className="al-btn al-btn--outline"
                                    style={{ padding: '4px 8px', fontSize: 11 }}
                                    disabled={busyId === row.id}
                                    onClick={() => void markInvoice(row.id, 'refunded')}
                                  >
                                    Refund
                                  </button>
                                )}
                              </div>
                            </td>
                          </>
                        )}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {tab === 'plans' ? (
            <div className="al-table-card" style={{ marginTop: 16, padding: 16 }}>
              <h3 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
                <IconPlus width={16} height={16} /> Add billing plan
              </h3>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
                  gap: 10,
                }}
              >
                <label className="field">
                  Name
                  <input
                    value={planForm.name}
                    onChange={(e) => setPlanForm({ ...planForm, name: e.target.value })}
                  />
                </label>
                <label className="field">
                  Audience
                  <select
                    value={planForm.audience}
                    onChange={(e) => setPlanForm({ ...planForm, audience: e.target.value })}
                  >
                    <option value="consumer">Consumer</option>
                    <option value="provider">Provider</option>
                    <option value="employer">Employer</option>
                  </select>
                </label>
                <label className="field">
                  Amount (cents)
                  <input
                    value={planForm.amountCents}
                    onChange={(e) =>
                      setPlanForm({ ...planForm, amountCents: e.target.value })
                    }
                  />
                </label>
                <label className="field">
                  Interval
                  <select
                    value={planForm.interval}
                    onChange={(e) => setPlanForm({ ...planForm, interval: e.target.value })}
                  >
                    <option value="month">Monthly</option>
                    <option value="year">Yearly</option>
                  </select>
                </label>
                <label className="field" style={{ gridColumn: '1 / -1' }}>
                  Summary
                  <input
                    value={planForm.summary}
                    onChange={(e) => setPlanForm({ ...planForm, summary: e.target.value })}
                  />
                </label>
                <button type="button" className="al-btn al-btn--primary" onClick={() => void savePlan()}>
                  Save plan
                </button>
              </div>
            </div>
          ) : null}

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(3, 1fr)',
              gap: 12,
              marginTop: 16,
            }}
          >
            <div className="al-help-card">
              <IconShieldCheck width={22} height={22} style={{ color: '#2563eb' }} />
              <strong>Secure Payments</strong>
              <p>All transactions are encrypted and protected.</p>
            </div>
            <div className="al-help-card">
              <IconUsers width={22} height={22} style={{ color: '#16a34a' }} />
              <strong>Support a Greater Cause</strong>
              <p>Your payments help build a more inclusive society.</p>
            </div>
            <div className="al-help-card">
              <IconFileText width={22} height={22} style={{ color: '#64748b' }} />
              <strong>Need Help?</strong>
              <p>Questions about invoices or refunds.</p>
              <a className="al-btn al-btn--outline" href="/support">
                Contact Support
              </a>
            </div>
          </div>
        </div>

        <div className="al-widgets">
          <div className="al-wallet-card">
            <span className="muted" style={{ fontSize: 12, fontWeight: 600 }}>
              My Wallet
            </span>
            <strong className="al-wallet-balance">{walletTotal}</strong>
            <button type="button" className="al-btn al-btn--wallet">
              <IconPlus width={14} height={14} /> Add Funds
            </button>
            <div className="al-wallet-meta">
              <span>
                <IconChart width={12} height={12} /> {invoices.length} invoices
              </span>
              <span>
                <IconUsers width={12} height={12} /> {subs.length} subscriptions
              </span>
            </div>
          </div>

          <Widget title="Quick Actions">
            <div className="al-widget-list">
              {[
                { label: 'Pay for a Booking', icon: <IconCalendar width={14} height={14} />, tab: 'booking' as const },
                { label: 'Add Payment Method', icon: <IconCreditCard width={14} height={14} />, tab: 'methods' as const },
                { label: 'View Invoices', icon: <IconFileText width={14} height={14} />, tab: 'invoices' as const },
                { label: 'Request Refund', icon: <IconRefresh width={14} height={14} />, tab: 'refunds' as const },
              ].map((a) => (
                <button
                  key={a.label}
                  type="button"
                  className="al-btn al-btn--outline"
                  style={{ width: '100%', justifyContent: 'flex-start' }}
                  onClick={() => setTab(a.tab)}
                >
                  {a.icon} {a.label}
                </button>
              ))}
            </div>
          </Widget>

          <Widget
            title="Payment Methods"
            action={
              <button type="button" className="al-btn al-btn--ghost" onClick={() => setTab('methods')}>
                Manage
              </button>
            }
          >
            <div className="al-widget-list">
              <div className="al-widget-item">
                <IconCreditCard width={18} height={18} style={{ color: '#2563eb' }} />
                <div style={{ flex: 1 }}>
                  <strong>Mastercard •••• 4582</strong>
                  <span>Expires 09/28</span>
                </div>
                <StatusPill tone="ok">Default</StatusPill>
              </div>
              <div className="al-widget-item">
                <IconCreditCard width={18} height={18} style={{ color: '#1e40af' }} />
                <div>
                  <strong>Visa •••• 7719</strong>
                  <span>Expires 03/27</span>
                </div>
              </div>
              <div className="al-widget-item">
                <IconCreditCard width={18} height={18} style={{ color: '#16a34a' }} />
                <div>
                  <strong>easypaisa</strong>
                  <span>+92 300 •••• 482</span>
                </div>
              </div>
              <div className="al-widget-item">
                <IconCreditCard width={18} height={18} style={{ color: '#ea580c' }} />
                <div>
                  <strong>JazzCash</strong>
                  <span>+92 321 •••• 119</span>
                </div>
              </div>
            </div>
          </Widget>
        </div>
      </div>
    </div>
  )
}
