import type { ReactNode } from 'react'
import {
  IconDownload,
  IconFilter,
  IconPlus,
  IconRefresh,
  IconSearch,
  IconTrendDown,
  IconTrendUp,
} from './icons'

export type KpiItem = {
  label: string
  value: string | number
  trend?: string
  trendDown?: boolean
  tone?: 'blue' | 'green' | 'orange' | 'red' | 'purple' | 'pink' | 'yellow'
  icon?: ReactNode
}

const TONE_CLASS: Record<NonNullable<KpiItem['tone']>, string> = {
  blue: 'al-kpi--blue',
  green: 'al-kpi--green',
  orange: 'al-kpi--orange',
  red: 'al-kpi--red',
  purple: 'al-kpi--purple',
  pink: 'al-kpi--pink',
  yellow: 'al-kpi--yellow',
}

export function PageHeader({
  title,
  subtitle,
  onExport,
  primaryAction,
  secondaryAction,
}: {
  title: string
  subtitle?: string
  onExport?: () => void
  primaryAction?: { label: string; onClick?: () => void; href?: string }
  secondaryAction?: ReactNode
}) {
  return (
    <div className="al-page-head">
      <div>
        <h1 className="al-page-title">{title}</h1>
        {subtitle ? <p className="al-page-sub">{subtitle}</p> : null}
      </div>
      <div className="al-page-actions">
        {secondaryAction}
        {onExport ? (
          <button type="button" className="al-btn al-btn--outline" onClick={onExport}>
            <IconDownload width={15} height={15} /> Export
          </button>
        ) : null}
        {primaryAction ? (
          primaryAction.href ? (
            <a className="al-btn al-btn--primary" href={primaryAction.href}>
              <IconPlus width={15} height={15} /> {primaryAction.label}
            </a>
          ) : (
            <button
              type="button"
              className="al-btn al-btn--primary"
              onClick={primaryAction.onClick}
            >
              <IconPlus width={15} height={15} /> {primaryAction.label}
            </button>
          )
        ) : null}
      </div>
    </div>
  )
}

export function KpiRow({
  items,
  cols = 5,
}: {
  items: KpiItem[]
  cols?: 4 | 5 | 6
}) {
  return (
    <div className={`al-kpi-row${cols === 4 ? ' cols-4' : ''}`} style={cols === 6 ? { gridTemplateColumns: 'repeat(6, minmax(0,1fr))' } : undefined}>
      {items.map((item) => (
        <div key={item.label} className={`al-kpi ${TONE_CLASS[item.tone ?? 'blue']}`}>
          <div className="al-kpi-icon" aria-hidden>
            {item.icon}
          </div>
          <div className="al-kpi-body">
            <span className="al-kpi-label">{item.label}</span>
            <strong className="al-kpi-value">{item.value}</strong>
            {item.trend ? (
              <span className={`al-kpi-trend${item.trendDown ? ' down' : ''}`}>
                {item.trendDown ? (
                  <IconTrendDown width={12} height={12} />
                ) : (
                  <IconTrendUp width={12} height={12} />
                )}{' '}
                {item.trend}
              </span>
            ) : null}
          </div>
        </div>
      ))}
    </div>
  )
}

export function FilterBar({
  search,
  onSearch,
  searchPlaceholder = 'Search…',
  children,
  onReset,
  moreFilters = true,
}: {
  search: string
  onSearch: (v: string) => void
  searchPlaceholder?: string
  children?: ReactNode
  onReset?: () => void
  moreFilters?: boolean
}) {
  return (
    <div className="al-filter-bar">
      <div className="al-filter-search">
        <IconSearch width={15} height={15} />
        <input
          value={search}
          onChange={(e) => onSearch(e.target.value)}
          placeholder={searchPlaceholder}
        />
      </div>
      <div className="al-filter-fields">{children}</div>
      {moreFilters ? (
        <button type="button" className="al-btn al-btn--outline">
          <IconFilter width={14} height={14} /> More Filters
        </button>
      ) : null}
      {onReset ? (
        <button type="button" className="al-btn al-btn--ghost" onClick={onReset}>
          <IconRefresh width={14} height={14} /> Reset
        </button>
      ) : null}
    </div>
  )
}

export function TabBar({
  tabs,
  active,
  onChange,
}: {
  tabs: { id: string; label: string }[]
  active: string
  onChange: (id: string) => void
}) {
  return (
    <div className="al-tabs" role="tablist">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          type="button"
          role="tab"
          aria-selected={active === tab.id}
          className={`al-tab${active === tab.id ? ' active' : ''}`}
          onClick={() => onChange(tab.id)}
        >
          {tab.label}
        </button>
      ))}
    </div>
  )
}

export function DetailPanel({
  open,
  onClose,
  header,
  title,
  children,
  footer,
}: {
  open: boolean
  onClose: () => void
  header?: ReactNode
  /** @deprecated Prefer `header` for rich layouts */
  title?: string
  children: ReactNode
  footer?: ReactNode
}) {
  if (!open) return null
  return (
    <aside className="al-detail" aria-label="Details">
      <div className="al-detail-head">
        <div style={{ flex: 1, minWidth: 0 }}>
          {header ?? (title ? <strong style={{ fontSize: 15 }}>{title}</strong> : null)}
        </div>
        <button type="button" className="icon-btn" onClick={onClose} aria-label="Close">
          ×
        </button>
      </div>
      <div className="al-detail-body">{children}</div>
      {footer ? <div className="al-detail-foot">{footer}</div> : null}
    </aside>
  )
}

export function StatusPill({
  tone,
  children,
}: {
  tone: 'ok' | 'warn' | 'danger' | 'info' | 'muted' | 'purple' | 'pink' | 'yellow' | 'navy' | 'orange'
  children: ReactNode
}) {
  return <span className={`al-pill al-pill--${tone}`}>{children}</span>
}

export function Widget({ title, action, children }: { title: string; action?: ReactNode; children: ReactNode }) {
  return (
    <div className="al-widget">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <h3 style={{ margin: 0 }}>{title}</h3>
        {action}
      </div>
      {children}
    </div>
  )
}
