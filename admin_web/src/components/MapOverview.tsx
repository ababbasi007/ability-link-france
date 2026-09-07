import { useEffect, useMemo, useRef, useState } from 'react'
import {
  loadGoogleMaps,
  triggerMapResize,
  type GoogleMap,
  type GoogleMarker,
} from '../lib/googleMaps'

type Place = {
  id: string
  name?: unknown
  lat?: unknown
  lng?: unknown
  verified?: unknown
  communityVerified?: unknown
}

type Counts = {
  verified: number
  pending: number
  reported: number
}

export function MapOverview({
  places,
  counts,
}: {
  places: Place[]
  counts?: Counts
}) {
  const hostRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<GoogleMap | null>(null)
  const markersRef = useRef<GoogleMarker[]>([])
  const [error, setError] = useState('')

  const points = useMemo(
    () =>
      places
        .map((p) => ({
          id: p.id,
          name: String(p.name ?? 'Place'),
          lat: Number(p.lat),
          lng: Number(p.lng),
          verified: p.verified === true || p.communityVerified === true,
        }))
        .filter((p) => Number.isFinite(p.lat) && Number.isFinite(p.lng)),
    [places],
  )

  const verifiedPts = points.filter((p) => p.verified)
  const pendingPts = points.filter((p) => !p.verified)

  const demoClusters = useMemo(
    () =>
      points.length < 3
        ? [
            { lat: 31.55, lng: 74.35, n: 42, color: '#22c55e' },
            { lat: 31.48, lng: 74.3, n: 18, color: '#f97316' },
            { lat: 31.52, lng: 74.42, n: 7, color: '#ef4444' },
            { lat: 31.46, lng: 74.38, n: 25, color: '#22c55e' },
          ]
        : [],
    [points.length],
  )

  const legend = counts ?? {
    verified: verifiedPts.length,
    pending: pendingPts.length,
    reported: 0,
  }

  useEffect(() => {
    let cancelled = false

    void (async () => {
      try {
        const maps = await loadGoogleMaps()
        if (cancelled || !hostRef.current) return

        const center =
          points[0] != null
            ? { lat: points[0].lat, lng: points[0].lng }
            : { lat: 31.5204, lng: 74.3587 }

        if (!mapRef.current) {
          mapRef.current = new maps.Map(hostRef.current, {
            center,
            zoom: points.length ? 11 : 12,
            mapTypeId: 'roadmap',
            zoomControl: true,
            mapTypeControl: false,
            streetViewControl: false,
            fullscreenControl: false,
            clickableIcons: false,
          })
        }

        const map = mapRef.current
        markersRef.current.forEach((m) => m.setMap(null))
        markersRef.current = []

        const bounds = new maps.LatLngBounds()

        for (const c of demoClusters) {
          const marker = new maps.Marker({
            map,
            position: { lat: c.lat, lng: c.lng },
            label: {
              text: String(c.n),
              color: '#fff',
              fontWeight: '700',
              fontSize: '11px',
            },
            icon: {
              path: maps.SymbolPath.CIRCLE,
              scale: 16,
              fillColor: c.color,
              fillOpacity: 1,
              strokeColor: '#fff',
              strokeWeight: 2,
            },
          })
          markersRef.current.push(marker)
          bounds.extend({ lat: c.lat, lng: c.lng })
        }

        for (const p of points.slice(0, 80)) {
          const color = p.verified ? '#22c55e' : '#f97316'
          const marker = new maps.Marker({
            map,
            position: { lat: p.lat, lng: p.lng },
            title: `${p.name} · ${p.verified ? 'Verified' : 'Pending'}`,
            icon: {
              path: maps.SymbolPath.CIRCLE,
              scale: 8,
              fillColor: color,
              fillOpacity: 0.95,
              strokeColor: p.verified ? '#15803d' : '#ea580c',
              strokeWeight: 2,
            },
          })
          markersRef.current.push(marker)
          bounds.extend({ lat: p.lat, lng: p.lng })
        }

        if (points.length + demoClusters.length >= 2) {
          map.fitBounds(bounds, 36)
        } else {
          map.setCenter(center)
        }
        window.requestAnimationFrame(() => triggerMapResize(map))
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : 'Google Maps unavailable')
        }
      }
    })()

    return () => {
      cancelled = true
    }
  }, [points, demoClusters])

  return (
    <div className="map-wrap">
      <div className="map-frame">
        <div ref={hostRef} className="google-map-host" />
        {error ? <div className="map-fallback-error">{error}</div> : null}
      </div>
      <div className="map-legend">
        <span>
          <i className="dot" style={{ background: '#22c55e' }} />
          Verified <strong>{legend.verified.toLocaleString()}</strong>
        </span>
        <span>
          <i className="dot" style={{ background: '#f97316' }} />
          Pending <strong>{legend.pending.toLocaleString()}</strong>
        </span>
        <span>
          <i className="dot" style={{ background: '#ef4444' }} />
          Reported <strong>{legend.reported.toLocaleString()}</strong>
        </span>
      </div>
    </div>
  )
}
