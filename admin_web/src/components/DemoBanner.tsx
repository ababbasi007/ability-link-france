type DemoBannerProps = {
  /** When true, banner is shown. */
  active: boolean
  /** Optional short reason, e.g. "Firestore empty" or "fetch failed". */
  reason?: string
}

/** Visible warning whenever a page is showing fabricated demo rows/KPIs. */
export function DemoBanner({ active, reason }: DemoBannerProps) {
  if (!active) return null
  return (
    <div className="demo-banner" role="status">
      <strong>Demo data</strong>
      <span>
        {reason
          ? `${reason} — numbers and rows below are sample data, not live Firestore.`
          : 'Numbers and rows below are sample data, not live Firestore.'}
      </span>
    </div>
  )
}
