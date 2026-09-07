import { useEffect, useRef, useState } from 'react'
import {
  FilterBar,
  PageHeader,
  StatusPill,
  Widget,
} from '../components/PageChrome'
import {
  IconMore,
  IconUpload,
} from '../components/icons'
import { useAuth } from '../lib/auth'
import {
  DEFAULT_HOME_HERO_SLIDES,
  HOME_HERO_ACTIONS,
  saveHomeHeroSlides,
  uploadHomeHeroImage,
  type HomeHeroSlide,
} from '../lib/data'

function cloneDefaults(): HomeHeroSlide[] {
  return DEFAULT_HOME_HERO_SLIDES.map((s) => ({ ...s }))
}

function slideLabel(slide: HomeHeroSlide): string {
  return (
    HOME_HERO_ACTIONS.find((a) => a.value === slide.action)?.label ??
    slide.ctaLabel ??
    slide.id
  )
}

const VIDEO_CATS = [
  { id: 'all', label: 'All Videos', tone: '#2563eb', bg: '#dbeafe' },
  { id: 'exercises', label: 'Exercises', tone: '#16a34a', bg: '#dcfce7' },
  { id: 'at', label: 'Assistive Technology', tone: '#2563eb', bg: '#dbeafe' },
  { id: 'daily', label: 'Daily Living', tone: '#ea580c', bg: '#ffedd5' },
  { id: 'health', label: 'Health & Wellness', tone: '#dc2626', bg: '#fee2e2' },
  { id: 'education', label: 'Education', tone: '#7c3aed', bg: '#ede9fe' },
  { id: 'employment', label: 'Employment', tone: '#1e3a8a', bg: '#e0e7ff' },
  { id: 'stories', label: 'Inspiring Stories', tone: '#ca8a04', bg: '#fef9c3' },
  { id: 'travel', label: 'Travel', tone: '#0284c7', bg: '#e0f2fe' },
]

export function HomeHeroImagesPage() {
  const { config, refreshConfig, admin } = useAuth()
  const [slides, setSlides] = useState<HomeHeroSlide[]>(cloneDefaults)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [ok, setOk] = useState('')
  const [cat, setCat] = useState('all')
  const [q, setQ] = useState('')
  const fileRefs = useRef<Record<string, HTMLInputElement | null>>({})

  useEffect(() => {
    if (config?.homeHeroSlides?.length) {
      setSlides(config.homeHeroSlides.map((s) => ({ ...s })))
    } else {
      setSlides(cloneDefaults())
    }
  }, [config?.homeHeroSlides])

  const updateSlide = (id: string, patch: Partial<HomeHeroSlide>) => {
    setSlides((prev) => prev.map((s) => (s.id === id ? { ...s, ...patch } : s)))
    setOk('')
    setError('')
  }

  const onPickFile = async (slideId: string, file: File | undefined) => {
    if (!file) return
    if (!admin) {
      setError('Only admins can upload hero images.')
      return
    }
    setBusyId(slideId)
    setError('')
    setOk('')
    try {
      const url = await uploadHomeHeroImage(file, slideId)
      updateSlide(slideId, { imageUrl: url })
      const slide =
        slides.find((s) => s.id === slideId) ??
        DEFAULT_HOME_HERO_SLIDES.find((s) => s.id === slideId)
      setOk(
        `Uploaded image for “${slide ? slideLabel(slide) : slideId}”. Click Save to publish.`,
      )
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Upload failed')
    } finally {
      setBusyId(null)
    }
  }

  const onSave = async () => {
    if (!admin) {
      setError('Only admins can save hero slides.')
      return
    }
    setSaving(true)
    setError('')
    setOk('')
    try {
      await saveHomeHeroSlides(slides)
      await refreshConfig()
      setOk('Home hero slides published to the app.')
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const ordered = [...slides]
    .sort((a, b) => a.sortOrder - b.sortOrder)
    .filter((s) => {
      if (!q.trim()) return true
      return slideLabel(s).toLowerCase().includes(q.trim().toLowerCase())
    })

  const featured = ordered.find((s) => s.active) ?? ordered[0]

  return (
    <div className="al-page">
      <PageHeader
        title="Videos"
        subtitle="Watch, learn and be inspired. Helpful videos for a more inclusive and independent life."
        primaryAction={{
          label: 'Upload Video',
          onClick: () => fileRefs.current[ordered[0]?.id ?? '']?.click(),
        }}
        secondaryAction={
          <button
            type="button"
            className="al-btn al-btn--outline"
            disabled={saving || !admin}
            onClick={() => void onSave()}
          >
            {saving ? 'Saving…' : 'Save & publish'}
          </button>
        }
      />

      {!admin ? (
        <div className="al-settings-note">Admin role required to upload or publish videos/hero slides.</div>
      ) : null}
      {error ? <div className="error" style={{ marginBottom: 12 }}>{error}</div> : null}
      {ok ? <div className="al-settings-ok" style={{ marginBottom: 12 }}>{ok}</div> : null}

      <div className="al-cat-scroll">
        {VIDEO_CATS.map((c) => (
          <button
            key={c.id}
            type="button"
            className={`al-cat-tile${cat === c.id ? ' active' : ''}`}
            onClick={() => setCat(c.id)}
          >
            <div className="icon" style={{ background: c.bg, color: c.tone }}>
              <IconUpload width={16} height={16} />
            </div>
            <span>{c.label}</span>
          </button>
        ))}
      </div>

      {featured ? (
        <div className="al-table-card" style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', marginBottom: 16, overflow: 'hidden' }}>
          <div style={{ position: 'relative', minHeight: 220, background: '#0f172a' }}>
            {featured.imageUrl ? (
              <img src={featured.imageUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', opacity: 0.9 }} />
            ) : null}
            <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center' }}>
              <span style={{ width: 56, height: 56, borderRadius: '50%', background: 'rgba(255,255,255,0.9)', display: 'grid', placeItems: 'center', color: '#2563eb', fontSize: 18 }}>▶</span>
            </div>
          </div>
          <div style={{ padding: 20 }}>
            <StatusPill tone="info">FEATURED VIDEO</StatusPill>
            <h2 style={{ margin: '10px 0 6px', fontSize: 20 }}>{slideLabel(featured)}</h2>
            <p className="muted" style={{ fontSize: 13 }}>
              Different Abilities, Brighter Tomorrows. Real stories. Real people. A more inclusive world.
            </p>
            <p className="muted" style={{ fontSize: 12 }}>Ability Link · Hero slide · {featured.active ? 'Active' : 'Inactive'}</p>
            <button type="button" className="al-btn al-btn--primary" style={{ marginTop: 12 }}>
              Watch Now →
            </button>
          </div>
        </div>
      ) : null}

      <div className="al-split">
        <div>
          <FilterBar
            search={q}
            onSearch={setQ}
            searchPlaceholder="Search videos..."
            moreFilters={false}
            onReset={() => setQ('')}
          >
            <select defaultValue="all">
              <option value="all">All Categories</option>
            </select>
            <select defaultValue="any">
              <option value="any">Any Duration</option>
            </select>
            <select defaultValue="recent">
              <option value="recent">Most Recent</option>
            </select>
          </FilterBar>

          <strong style={{ display: 'block', marginBottom: 10 }}>Browse Videos / Hero Slides</strong>
          <div className="al-content-grid">
            {ordered.map((slide, index) => (
              <article key={slide.id} className="al-content-card">
                <div style={{ position: 'relative' }}>
                  {slide.imageUrl ? (
                    <img src={slide.imageUrl} alt={slide.ctaLabel} />
                  ) : (
                    <div style={{ height: 120, background: '#e2e8f0', display: 'grid', placeItems: 'center', color: '#64748b', fontSize: 12 }}>
                      No image
                    </div>
                  )}
                  <span style={{ position: 'absolute', left: 8, bottom: 8, background: 'rgba(0,0,0,0.75)', color: '#fff', fontSize: 10, padding: '2px 6px', borderRadius: 4 }}>
                    {String(index + 1).padStart(2, '0')}:00
                  </span>
                  <button type="button" className="icon-btn" style={{ position: 'absolute', top: 4, right: 4, background: '#fff' }} aria-label="More">
                    <IconMore width={14} height={14} />
                  </button>
                </div>
                <div className="body">
                  <strong>{slideLabel(slide)}</strong>
                  <div style={{ display: 'flex', gap: 6, marginBottom: 8 }}>
                    <StatusPill tone={slide.active ? 'ok' : 'muted'}>
                      {slide.active ? 'Active' : 'Inactive'}
                    </StatusPill>
                  </div>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12 }}>
                    <input
                      type="checkbox"
                      checked={slide.active}
                      disabled={!admin}
                      onChange={(e) => updateSlide(slide.id, { active: e.target.checked })}
                    />
                    Show on home
                  </label>
                  <div style={{ marginTop: 8, display: 'flex', gap: 6 }}>
                    <button
                      type="button"
                      className="al-btn al-btn--outline"
                      style={{ fontSize: 11, padding: '6px 8px' }}
                      disabled={!admin || busyId === slide.id}
                      onClick={() => fileRefs.current[slide.id]?.click()}
                    >
                      <IconUpload width={12} height={12} /> Upload
                    </button>
                    <input
                      ref={(el) => {
                        fileRefs.current[slide.id] = el
                      }}
                      type="file"
                      accept="image/*"
                      hidden
                      onChange={(e) => void onPickFile(slide.id, e.target.files?.[0])}
                    />
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>

        <div className="al-widgets">
          <Widget title="Continue Watching">
            <div className="al-widget-list">
              {ordered.slice(0, 3).map((s, i) => (
                <div key={s.id} className="al-widget-item">
                  <div style={{ width: 48, height: 32, borderRadius: 6, overflow: 'hidden', background: '#e2e8f0', flexShrink: 0 }}>
                    {s.imageUrl ? <img src={s.imageUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : null}
                  </div>
                  <div style={{ flex: 1 }}>
                    <strong>{slideLabel(s)}</strong>
                    <div style={{ height: 4, background: '#e2e8f0', borderRadius: 999, marginTop: 4 }}>
                      <div style={{ width: `${65 - i * 15}%`, height: '100%', background: '#2563eb', borderRadius: 999 }} />
                    </div>
                    <span>{65 - i * 15}% watched</span>
                  </div>
                </div>
              ))}
            </div>
          </Widget>
          <Widget title="Popular Playlists">
            <div className="al-widget-list">
              {['Exercise Programs · 24 videos', 'Daily Living Tips · 12 videos', 'Inspiring Stories · 18 videos'].map((p) => (
                <div key={p} className="al-widget-item">
                  <IconUpload width={14} height={14} style={{ color: '#2563eb' }} />
                  <strong>{p}</strong>
                </div>
              ))}
            </div>
          </Widget>
          <div className="al-help-card">
            <IconUpload width={20} height={20} style={{ color: '#2563eb' }} />
            <strong>Have a Video to Share?</strong>
            <p>Upload hero media used across the Ability Link app.</p>
            <button type="button" className="al-btn al-btn--primary" disabled={!admin} onClick={() => void onSave()}>
              Upload Video
            </button>
          </div>
          <p style={{ fontStyle: 'italic', color: '#2563eb', fontWeight: 600, fontSize: 13, textAlign: 'center' }}>
            “Knowledge shared is independence multiplied.”
          </p>
        </div>
      </div>
    </div>
  )
}
