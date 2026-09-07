import { Link } from 'react-router-dom'

export function PlaceholderPage({
  title,
  blurb,
}: {
  title: string
  blurb?: string
}) {
  return (
    <div className="dash">
      <div className="page-head">
        <div>
          <h1 className="page-title">{title}</h1>
          <p className="page-sub">{blurb ?? 'Coming soon — wired to the same Firebase backend.'}</p>
        </div>
      </div>
      <div className="card" style={{ padding: 28 }}>
        <p className="empty" style={{ padding: 0, margin: 0 }}>
          This section matches the mockup navigation. Use{' '}
          <Link className="link-all" to="/">
            Dashboard
          </Link>{' '}
          for live Ability Map overview.
        </p>
      </div>
    </div>
  )
}
