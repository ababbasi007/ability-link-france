import { useEffect, useMemo, useRef, useState, type FormEvent, type ReactNode } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../lib/auth'
import { createPlace } from '../lib/data'
import { LocationMapPicker } from '../components/LocationMapPicker'
import {
  reverseGeocode,
  searchGoogleLocations,
  type GeocodeHit,
} from '../lib/googleMaps'
import {
  IconAudio,
  IconBraille,
  IconBuilding,
  IconCheckCircle,
  IconClock,
  IconDoor,
  IconEar,
  IconElevator,
  IconEyeOpen,
  IconGlobe,
  IconMail,
  IconMapPin,
  IconParking,
  IconPath,
  IconPaw,
  IconPlus,
  IconRamp,
  IconRestroom,
  IconSave,
  IconSearch,
  IconTactile,
  IconUpload,
  IconWheelchair,
} from '../components/icons'

const CATEGORIES = [
  { value: 'hospital', label: 'Hospital' },
  { value: 'restaurant', label: 'Restaurant' },
  { value: 'cafe', label: 'Cafe' },
  { value: 'mall', label: 'Shopping / Mall' },
  { value: 'park', label: 'Park' },
  { value: 'transit', label: 'Transit' },
  { value: 'library', label: 'Library' },
  { value: 'pharmacy', label: 'Pharmacy' },
  { value: 'hotel', label: 'Hotel' },
  { value: 'other', label: 'Other' },
]

const HOURS = [
  'Mon–Fri 9:00 AM – 5:00 PM',
  'Mon–Sat 10:00 AM – 8:00 PM',
  'Daily 8:00 AM – 10:00 PM',
  '24 hours',
  'By appointment',
  'Custom / see description',
]

const FEATURES: { key: string; label: string; icon: ReactNode }[] = [
  { key: 'wheelchair', label: 'Wheelchair Access', icon: <IconWheelchair /> },
  { key: 'ramp', label: 'Ramps', icon: <IconRamp /> },
  { key: 'elevator', label: 'Elevator', icon: <IconElevator /> },
  { key: 'toilet', label: 'Accessible Restroom', icon: <IconRestroom /> },
  { key: 'parking', label: 'Accessible Parking', icon: <IconParking /> },
  { key: 'stepFree', label: 'Step-Free Entrance', icon: <IconDoor /> },
  { key: 'braille', label: 'Braille', icon: <IconBraille /> },
  { key: 'audioAnnouncements', label: 'Audio Assistance', icon: <IconAudio /> },
  { key: 'hearing', label: 'Hearing Assistance', icon: <IconEar /> },
  { key: 'lowVisionFriendly', label: 'Low Vision Friendly', icon: <IconEyeOpen /> },
  { key: 'wideCorridors', label: 'Wide Doorways', icon: <IconDoor /> },
  { key: 'accessibleTransit', label: 'Accessible Pathways', icon: <IconPath /> },
  { key: 'serviceAnimal', label: 'Service Animal Friendly', icon: <IconPaw /> },
  { key: 'visual', label: 'Tactile Paving', icon: <IconTactile /> },
]

type PhotoPreview = { id: string; name: string; url: string }

const DEFAULT_LAT = 31.5204
const DEFAULT_LNG = 74.3587

export function AddPlacePage() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const fileRef = useRef<HTMLInputElement>(null)

  const [name, setName] = useState('')
  const [category, setCategory] = useState('')
  const [shortDescription, setShortDescription] = useState('')
  const [phoneCode, setPhoneCode] = useState('+92')
  const [phone, setPhone] = useState('')
  const [website, setWebsite] = useState('')
  const [email, setEmail] = useState('')
  const [hours, setHours] = useState(HOURS[0])
  const [features, setFeatures] = useState<Set<string>>(new Set())
  const [customFeature, setCustomFeature] = useState('')
  const [showCustom, setShowCustom] = useState(false)
  const [description, setDescription] = useState('')
  const [tagInput, setTagInput] = useState('')
  const [tags, setTags] = useState<string[]>([])
  const [active, setActive] = useState(true)
  const [locationQuery, setLocationQuery] = useState('')
  const [suggestions, setSuggestions] = useState<GeocodeHit[]>([])
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [lat, setLat] = useState(DEFAULT_LAT)
  const [lng, setLng] = useState(DEFAULT_LNG)
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('Lahore')
  const [country, setCountry] = useState('Pakistan')
  const [photos, setPhotos] = useState<PhotoPreview[]>([])
  const [verificationStatus, setVerificationStatus] = useState<
    'pending' | 'verified' | 'community'
  >('pending')
  const [reviewerNotes, setReviewerNotes] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [geoBusy, setGeoBusy] = useState(false)
  const [geoHint, setGeoHint] = useState('')
  const suggestTimer = useRef<number | null>(null)
  const skipNextSuggest = useRef(false)

  const applyLocation = (hit: GeocodeHit) => {
    skipNextSuggest.current = true
    setLocationQuery(hit.label)
    setLat(Number(hit.lat.toFixed(6)))
    setLng(Number(hit.lng.toFixed(6)))
    setAddress(hit.address)
    if (hit.city) setCity(hit.city)
    if (hit.country) setCountry(hit.country)
    setSuggestions([])
    setShowSuggestions(false)
    setGeoHint('')
    setError('')
  }

  const allFeatures = useMemo(() => {
    const base = [...FEATURES]
    for (const f of features) {
      if (!base.some((b) => b.key === f)) {
        base.push({
          key: f,
          label: f,
          icon: <IconPlus width={16} height={16} />,
        })
      }
    }
    return base
  }, [features])

  const toggleFeature = (key: string) => {
    setFeatures((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }

  const addCustomFeature = () => {
    const key = customFeature.trim().toLowerCase().replace(/\s+/g, '_')
    if (!key) return
    setFeatures((prev) => new Set(prev).add(key))
    setCustomFeature('')
    setShowCustom(false)
  }

  const addTag = () => {
    const t = tagInput.trim()
    if (!t || tags.length >= 10 || tags.includes(t)) return
    setTags((prev) => [...prev, t])
    setTagInput('')
  }

  const onPhotos = (files: FileList | null) => {
    if (!files) return
    const next: PhotoPreview[] = []
    for (const file of Array.from(files)) {
      if (photos.length + next.length >= 10) break
      if (!/^image\/(png|jpe?g)$/i.test(file.type)) continue
      if (file.size > 5 * 1024 * 1024) continue
      next.push({
        id: `${file.name}-${file.size}-${Date.now()}`,
        name: file.name,
        url: URL.createObjectURL(file),
      })
    }
    setPhotos((prev) => [...prev, ...next].slice(0, 10))
  }

  const searchLocation = async (query = locationQuery) => {
    const q = query.trim()
    if (!q) return
    setGeoBusy(true)
    setError('')
    setGeoHint('')
    try {
      const hits = await searchGoogleLocations(q)
      if (!hits.length) {
        setSuggestions([])
        setShowSuggestions(false)
        setError('No location found. Try a different address or place name.')
        return
      }
      if (hits.length === 1) {
        applyLocation(hits[0])
        return
      }
      setSuggestions(hits)
      setShowSuggestions(true)
      setGeoHint(`${hits.length} matches — pick one below`)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Location search failed.')
    } finally {
      setGeoBusy(false)
    }
  }

  useEffect(() => {
    if (skipNextSuggest.current) {
      skipNextSuggest.current = false
      return
    }
    const q = locationQuery.trim()
    if (q.length < 3) {
      setSuggestions([])
      setShowSuggestions(false)
      return
    }
    if (suggestTimer.current) window.clearTimeout(suggestTimer.current)
    suggestTimer.current = window.setTimeout(() => {
      void (async () => {
        try {
          const hits = await searchGoogleLocations(q)
          setSuggestions(hits)
          setShowSuggestions(hits.length > 0)
        } catch {
          /* ignore live-suggest errors; Find button still works */
        }
      })()
    }, 350)
    return () => {
      if (suggestTimer.current) window.clearTimeout(suggestTimer.current)
    }
  }, [locationQuery])

  const onMapPick = (la: number, ln: number) => {
    const nextLat = Number(la.toFixed(6))
    const nextLng = Number(ln.toFixed(6))
    setLat(nextLat)
    setLng(nextLng)
    void (async () => {
      const hit = await reverseGeocode(nextLat, nextLng)
      if (!hit) return
      skipNextSuggest.current = true
      setLocationQuery(hit.label)
      setAddress(hit.address)
      if (hit.city) setCity(hit.city)
      if (hit.country) setCountry(hit.country)
    })()
  }

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError('')
    if (!name.trim()) {
      setError('Place name is required.')
      return
    }
    if (!category) {
      setError('Category is required.')
      return
    }
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      setError('Latitude and longitude are required.')
      return
    }
    if (!address.trim() && !locationQuery.trim()) {
      setError('Address or search location is required.')
      return
    }

    setBusy(true)
    try {
      await createPlace({
        name,
        category,
        description,
        shortDescription,
        phone: phone.trim() ? `${phoneCode} ${phone.trim()}` : '',
        website,
        email,
        hours,
        features: [...features],
        tags,
        active,
        lat,
        lng,
        address: address.trim() || locationQuery.trim(),
        city,
        country,
        verificationStatus,
        reviewerNotes,
        createdBy: user?.uid ?? '',
      })
      navigate('/places')
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setBusy(false)
    }
  }

  return (
    <form className="add-place" onSubmit={onSubmit}>
      <div className="page-head places-head">
        <div>
          <h1 className="page-title">Add New Place</h1>
          <nav className="breadcrumbs">
            <Link to="/">Dashboard</Link>
            <span>/</span>
            <Link to="/places">Places</Link>
            <span>/</span>
            <span className="current">Add New Place</span>
          </nav>
        </div>
        <div className="page-actions">
          <button
            className="btn btn-export"
            type="button"
            onClick={() => navigate('/places')}
          >
            Cancel
          </button>
          <button className="btn btn-solid-inline" type="submit" disabled={busy}>
            <IconSave width={16} height={16} />
            {busy ? 'Saving…' : 'Save Place'}
          </button>
        </div>
      </div>

      {error ? <div className="error">{error}</div> : null}

      <div className="add-place-grid">
        <div className="add-place-main">
          {/* Basic Information */}
          <section className="card form-card">
            <h2 className="form-card-title">Basic Information</h2>

            <div className="field">
              <label htmlFor="place-name">
                Place Name <span className="req">*</span>
              </label>
              <input
                id="place-name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. City General Hospital"
                required
              />
            </div>

            <div className="field">
              <label htmlFor="place-category">
                Category <span className="req">*</span>
              </label>
              <select
                id="place-category"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                required
              >
                <option value="">Select category</option>
                {CATEGORIES.map((c) => (
                  <option key={c.value} value={c.value}>
                    {c.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="field">
              <label htmlFor="place-short">Short Description</label>
              <textarea
                id="place-short"
                rows={3}
                maxLength={200}
                value={shortDescription}
                onChange={(e) => setShortDescription(e.target.value)}
                placeholder="Brief summary shown on place cards"
              />
              <div className="char-count">{shortDescription.length}/200</div>
            </div>

            <div className="field">
              <label htmlFor="place-phone">Phone Number</label>
              <div className="phone-row">
                <select
                  value={phoneCode}
                  onChange={(e) => setPhoneCode(e.target.value)}
                  aria-label="Country code"
                >
                  <option value="+92">🇵🇰 +92</option>
                  <option value="+33">🇫🇷 +33</option>
                  <option value="+1">🇺🇸 +1</option>
                  <option value="+44">🇬🇧 +44</option>
                </select>
                <input
                  id="place-phone"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="300 1234567"
                />
              </div>
            </div>

            <div className="field">
              <label htmlFor="place-web">Website (Optional)</label>
              <div className="input-icon">
                <IconGlobe className="leading-icon" />
                <input
                  id="place-web"
                  value={website}
                  onChange={(e) => setWebsite(e.target.value)}
                  placeholder="https://"
                />
              </div>
            </div>

            <div className="field">
              <label htmlFor="place-email">Email (Optional)</label>
              <div className="input-icon">
                <IconMail className="leading-icon" />
                <input
                  id="place-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="contact@example.com"
                />
              </div>
            </div>

            <div className="field">
              <label htmlFor="place-hours">Opening Hours</label>
              <div className="input-icon">
                <IconClock className="leading-icon" />
                <select
                  id="place-hours"
                  value={hours}
                  onChange={(e) => setHours(e.target.value)}
                >
                  {HOURS.map((h) => (
                    <option key={h} value={h}>
                      {h}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </section>

          {/* Accessibility Features */}
          <section className="card form-card">
            <h2 className="form-card-title">Accessibility Features</h2>
            <div className="feature-grid">
              {allFeatures.map((f) => {
                const on = features.has(f.key)
                return (
                  <button
                    key={f.key}
                    type="button"
                    className={`feature-tile${on ? ' on' : ''}`}
                    onClick={() => toggleFeature(f.key)}
                  >
                    <span className="feature-check">
                      <input type="checkbox" readOnly checked={on} tabIndex={-1} />
                    </span>
                    <span className="feature-icon">{f.icon}</span>
                    <span className="feature-label">{f.label}</span>
                  </button>
                )
              })}
              <button
                type="button"
                className="feature-tile feature-add"
                onClick={() => setShowCustom((v) => !v)}
              >
                <span className="feature-icon">
                  <IconPlus />
                </span>
                <span className="feature-label">Add Other Feature</span>
              </button>
            </div>
            {showCustom ? (
              <div className="custom-feature-row">
                <input
                  value={customFeature}
                  onChange={(e) => setCustomFeature(e.target.value)}
                  placeholder="Feature name"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault()
                      addCustomFeature()
                    }
                  }}
                />
                <button className="btn btn-solid-inline" type="button" onClick={addCustomFeature}>
                  Add
                </button>
              </div>
            ) : null}
          </section>

          {/* Additional Information */}
          <section className="card form-card">
            <h2 className="form-card-title">Additional Information</h2>

            <div className="field">
              <label htmlFor="place-desc">Detailed Description</label>
              <textarea
                id="place-desc"
                rows={5}
                maxLength={1000}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Describe entrances, parking, restrooms, and other accessibility details…"
              />
              <div className="char-count">{description.length}/1000</div>
            </div>

            <div className="field">
              <label htmlFor="place-tags">Tags (Optional)</label>
              <input
                id="place-tags"
                value={tagInput}
                onChange={(e) => setTagInput(e.target.value)}
                placeholder="Press Enter to add multiple tags"
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault()
                    addTag()
                  }
                }}
              />
              <div className="tags-row">
                {tags.map((t) => (
                  <button
                    key={t}
                    type="button"
                    className="tag-chip"
                    onClick={() => setTags((prev) => prev.filter((x) => x !== t))}
                  >
                    {t} ×
                  </button>
                ))}
                <span className="char-count inline">{tags.length}/10</span>
              </div>
            </div>

            <div className="toggle-row">
              <div>
                <strong>Is this place active?</strong>
                <p>Active places will be visible to users</p>
              </div>
              <button
                type="button"
                className={`toggle${active ? ' on' : ''}`}
                role="switch"
                aria-checked={active}
                onClick={() => setActive((v) => !v)}
              >
                <span className="toggle-knob" />
              </button>
            </div>
          </section>
        </div>

        <div className="add-place-side">
          {/* Location */}
          <section className="card form-card">
            <h2 className="form-card-title">Location</h2>

            <div className="field loc-search-field">
              <label htmlFor="loc-search">
                Search Location <span className="req">*</span>
              </label>
              <div className="loc-search-wrap">
                <div className="loc-search-row">
                  <div className="input-icon grow">
                    <IconSearch className="leading-icon" />
                    <input
                      id="loc-search"
                      value={locationQuery}
                      onChange={(e) => setLocationQuery(e.target.value)}
                      onFocus={() => {
                        if (suggestions.length) setShowSuggestions(true)
                      }}
                      onBlur={() => {
                        window.setTimeout(() => setShowSuggestions(false), 180)
                      }}
                      placeholder="Search address or place"
                      autoComplete="off"
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault()
                          void searchLocation()
                        }
                      }}
                    />
                  </div>
                  <button
                    className="btn btn-export"
                    type="button"
                    onClick={() => void searchLocation()}
                    disabled={geoBusy}
                  >
                    {geoBusy ? '…' : 'Find'}
                  </button>
                </div>
                {showSuggestions && suggestions.length > 0 ? (
                  <ul className="loc-suggestions" role="listbox">
                    {suggestions.map((s) => (
                      <li key={`${s.lat},${s.lng},${s.label}`}>
                        <button
                          type="button"
                          onMouseDown={(e) => e.preventDefault()}
                          onClick={() => applyLocation(s)}
                        >
                          <IconMapPin width={14} height={14} />
                          <span>{s.label}</span>
                        </button>
                      </li>
                    ))}
                  </ul>
                ) : null}
              </div>
              {geoHint ? <div className="geo-hint">{geoHint}</div> : null}
            </div>

            <LocationMapPicker
              lat={lat}
              lng={lng}
              onChange={onMapPick}
            />

            <div className="coord-row">
              <div className="field">
                <label htmlFor="lat">
                  Latitude <span className="req">*</span>
                </label>
                <input
                  id="lat"
                  type="number"
                  step="any"
                  value={lat}
                  onChange={(e) => setLat(Number(e.target.value))}
                  required
                />
              </div>
              <div className="field">
                <label htmlFor="lng">
                  Longitude <span className="req">*</span>
                </label>
                <input
                  id="lng"
                  type="number"
                  step="any"
                  value={lng}
                  onChange={(e) => setLng(Number(e.target.value))}
                  required
                />
              </div>
            </div>

            <div className="field">
              <label htmlFor="address">Address</label>
              <div className="input-icon">
                <IconMapPin className="leading-icon" />
                <input
                  id="address"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Full street address"
                />
              </div>
            </div>

            <div className="coord-row">
              <div className="field">
                <label htmlFor="city">City</label>
                <input
                  id="city"
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                />
              </div>
              <div className="field">
                <label htmlFor="country">Country</label>
                <input
                  id="country"
                  value={country}
                  onChange={(e) => setCountry(e.target.value)}
                />
              </div>
            </div>
          </section>

          {/* Photos */}
          <section className="card form-card">
            <h2 className="form-card-title">Photos</h2>
            <button
              type="button"
              className="upload-drop"
              onClick={() => fileRef.current?.click()}
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault()
                onPhotos(e.dataTransfer.files)
              }}
            >
              <span className="upload-icon">
                <IconUpload />
              </span>
              <strong>Drag & drop images here or click to browse</strong>
              <span className="upload-hint">PNG, JPG, JPEG up to 5MB each</span>
              <span className="upload-count">{photos.length}/10 photos</span>
            </button>
            <input
              ref={fileRef}
              type="file"
              accept="image/png,image/jpeg,image/jpg"
              multiple
              hidden
              onChange={(e) => {
                onPhotos(e.target.files)
                e.target.value = ''
              }}
            />
            {photos.length ? (
              <div className="photo-preview-grid">
                {photos.map((p) => (
                  <div key={p.id} className="photo-preview">
                    <img src={p.url} alt={p.name} />
                    <button
                      type="button"
                      className="photo-remove"
                      onClick={() =>
                        setPhotos((prev) => prev.filter((x) => x.id !== p.id))
                      }
                    >
                      ×
                    </button>
                  </div>
                ))}
              </div>
            ) : null}
            <ul className="upload-guidelines">
              <li>Add clear photos of entrance, parking, restroom, ramps, etc.</li>
              <li>Minimum 3 photos recommended</li>
              <li>Show accessibility features in context when possible</li>
            </ul>
          </section>

          {/* Verification Settings */}
          <section className="card form-card">
            <h2 className="form-card-title">Verification Settings</h2>
            <div className="field">
              <label htmlFor="verify-status">Initial Verification Status</label>
              <div className="input-icon">
                {verificationStatus === 'verified' ? (
                  <IconCheckCircle className="leading-icon verify-ok" />
                ) : verificationStatus === 'community' ? (
                  <IconBuilding className="leading-icon verify-community" />
                ) : (
                  <IconClock className="leading-icon verify-pending" />
                )}
                <select
                  id="verify-status"
                  value={verificationStatus}
                  onChange={(e) =>
                    setVerificationStatus(
                      e.target.value as 'pending' | 'verified' | 'community',
                    )
                  }
                >
                  <option value="pending">Pending Verification</option>
                  <option value="verified">Verified</option>
                  <option value="community">Community Verified</option>
                </select>
              </div>
            </div>
            <div className="field">
              <label htmlFor="reviewer-notes">Notes for Reviewers (Optional)</label>
              <textarea
                id="reviewer-notes"
                rows={4}
                maxLength={300}
                value={reviewerNotes}
                onChange={(e) => setReviewerNotes(e.target.value)}
                placeholder="Internal notes for moderators…"
              />
              <div className="char-count">{reviewerNotes.length}/300</div>
            </div>
          </section>
        </div>
      </div>
    </form>
  )
}
