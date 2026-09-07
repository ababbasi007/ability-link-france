import { useEffect, useRef, useState } from 'react'
import {
  loadGoogleMaps,
  triggerMapResize,
  type GoogleMap,
  type GoogleMarker,
} from '../lib/googleMaps'

export function LocationMapPicker({
  lat,
  lng,
  onChange,
}: {
  lat: number
  lng: number
  onChange: (lat: number, lng: number) => void
}) {
  const hostRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<GoogleMap | null>(null)
  const markerRef = useRef<GoogleMarker | null>(null)
  const onChangeRef = useRef(onChange)
  const [error, setError] = useState('')

  useEffect(() => {
    onChangeRef.current = onChange
  }, [onChange])

  useEffect(() => {
    let cancelled = false
    let clickListener: { remove: () => void } | undefined
    let dragListener: { remove: () => void } | undefined

    void (async () => {
      try {
        const maps = await loadGoogleMaps()
        if (cancelled || !hostRef.current) return

        const center = { lat, lng }
        const map = new maps.Map(hostRef.current, {
          center,
          zoom: 15,
          mapTypeId: 'roadmap',
          disableDefaultUI: false,
          zoomControl: true,
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: false,
          clickableIcons: false,
        })
        mapRef.current = map

        const marker = new maps.Marker({
          map,
          position: center,
          draggable: true,
          animation: maps.Animation.DROP,
        })
        markerRef.current = marker

        window.requestAnimationFrame(() => {
          triggerMapResize(map)
          map.setCenter(center)
        })

        clickListener = map.addListener('click', (e) => {
          if (!e.latLng) return
          const next = { lat: e.latLng.lat(), lng: e.latLng.lng() }
          marker.setPosition(next)
          onChangeRef.current(next.lat, next.lng)
        })

        dragListener = marker.addListener('dragend', () => {
          const pos = marker.getPosition()
          if (!pos) return
          onChangeRef.current(pos.lat(), pos.lng())
        })
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : 'Google Maps unavailable')
        }
      }
    })()

    return () => {
      cancelled = true
      clickListener?.remove()
      dragListener?.remove()
      markerRef.current?.setMap(null)
      markerRef.current = null
      mapRef.current = null
    }
    // Init once; lat/lng updates handled below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    const map = mapRef.current
    const marker = markerRef.current
    if (!map || !marker) return
    const next = { lat, lng }
    marker.setPosition(next)
    map.panTo(next)
  }, [lat, lng])

  return (
    <div className="add-map-frame">
      <div ref={hostRef} className="google-map-host" />
      {error ? <div className="map-fallback-error">{error}</div> : null}
    </div>
  )
}
