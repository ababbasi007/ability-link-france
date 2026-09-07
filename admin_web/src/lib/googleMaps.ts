const SCRIPT_ID = 'ability-link-google-maps'

export type LatLngLiteral = { lat: number; lng: number }

export type GeocodeHit = {
  label: string
  address: string
  lat: number
  lng: number
  city: string
  country: string
}

export type GoogleMapsApi = {
  Map: new (
    el: HTMLElement,
    opts: Record<string, unknown>,
  ) => GoogleMap
  Marker: new (opts: Record<string, unknown>) => GoogleMarker
  LatLngBounds: new () => GoogleLatLngBounds
  Geocoder: new () => GoogleGeocoder
  SymbolPath: { CIRCLE: number }
  Animation: { DROP: number }
  event: {
    addListener: (
      instance: unknown,
      eventName: string,
      handler: (...args: unknown[]) => void,
    ) => { remove: () => void }
    trigger: (instance: unknown, eventName: string) => void
  }
  places?: {
    AutocompleteService: new () => GoogleAutocompleteService
    PlacesService: new (attrContainer: HTMLDivElement | GoogleMap) => GooglePlacesService
    PlacesServiceStatus: Record<string, string>
  }
}

export type GoogleMap = {
  setCenter: (c: LatLngLiteral) => void
  panTo: (c: LatLngLiteral) => void
  setZoom: (z: number) => void
  fitBounds: (b: GoogleLatLngBounds, padding?: number) => void
  addListener: (
    eventName: string,
    handler: (e: { latLng?: { lat: () => number; lng: () => number } | null }) => void,
  ) => { remove: () => void }
}

export type GoogleMarker = {
  setMap: (map: GoogleMap | null) => void
  setPosition: (c: LatLngLiteral) => void
  getPosition: () => { lat: () => number; lng: () => number } | null
  addListener: (
    eventName: string,
    handler: () => void,
  ) => { remove: () => void }
}

export type GoogleLatLngBounds = {
  extend: (c: LatLngLiteral) => void
}

type GeocoderAddressComponent = {
  long_name: string
  short_name: string
  types: string[]
}

type GeocoderResult = {
  formatted_address: string
  geometry: { location: { lat: () => number; lng: () => number } }
  address_components?: GeocoderAddressComponent[]
}

export type GoogleGeocoder = {
  geocode: (
    req: { address?: string; location?: LatLngLiteral },
    cb: (results: GeocoderResult[] | null, status: string) => void,
  ) => void
}

type AutocompletePrediction = {
  description: string
  place_id: string
}

export type GoogleAutocompleteService = {
  getPlacePredictions: (
    req: { input: string; types?: string[] },
    cb: (predictions: AutocompletePrediction[] | null, status: string) => void,
  ) => void
}

export type GooglePlacesService = {
  getDetails: (
    req: { placeId: string; fields: string[] },
    cb: (
      place: {
        formatted_address?: string
        name?: string
        geometry?: { location?: { lat: () => number; lng: () => number } }
        address_components?: GeocoderAddressComponent[]
      } | null,
      status: string,
    ) => void,
  ) => void
}

declare global {
  interface Window {
    google?: { maps: GoogleMapsApi }
    __abilityLinkMapsReady?: Promise<GoogleMapsApi>
    gm_authFailure?: () => void
  }
}

/** Firebase Browser key for web (Maps JavaScript API). */
export const GOOGLE_MAPS_API_KEY =
  import.meta.env.VITE_GOOGLE_MAPS_API_KEY ||
  'AIzaSyCPBAJMnXo5x0Hz4n7TetyvV-Bmt7VLq-s'

function componentName(
  comps: GeocoderAddressComponent[] | undefined,
  type: string,
): string {
  return comps?.find((c) => c.types.includes(type))?.long_name ?? ''
}

function hitFromGeocode(r: GeocoderResult): GeocodeHit {
  const comps = r.address_components
  const city =
    componentName(comps, 'locality') ||
    componentName(comps, 'administrative_area_level_2') ||
    componentName(comps, 'administrative_area_level_1')
  const country = componentName(comps, 'country')
  return {
    label: r.formatted_address,
    address: r.formatted_address,
    lat: r.geometry.location.lat(),
    lng: r.geometry.location.lng(),
    city,
    country,
  }
}

export function loadGoogleMaps(): Promise<GoogleMapsApi> {
  if (typeof window === 'undefined') {
    return Promise.reject(new Error('Google Maps requires a browser'))
  }
  if (window.google?.maps?.Map) {
    return Promise.resolve(window.google.maps)
  }
  if (window.__abilityLinkMapsReady) {
    return window.__abilityLinkMapsReady
  }

  window.__abilityLinkMapsReady = new Promise<GoogleMapsApi>((resolve, reject) => {
    const fail = (message: string) => {
      window.__abilityLinkMapsReady = undefined
      reject(new Error(message))
    }

    window.gm_authFailure = () => {
      fail(
        'Google Maps auth failed. Check Maps JavaScript API is enabled and this browser key allows your domain.',
      )
    }

    const existing = document.getElementById(SCRIPT_ID) as HTMLScriptElement | null
    if (existing) {
      const wait = () => {
        if (window.google?.maps?.Map) resolve(window.google.maps)
        else setTimeout(wait, 50)
      }
      existing.addEventListener('error', () => fail('Failed to load Google Maps script'))
      wait()
      return
    }

    const callbackName = '__abilityLinkMapsInit'
    ;(window as unknown as Record<string, unknown>)[callbackName] = () => {
      if (window.google?.maps?.Map) resolve(window.google.maps)
      else fail('Google Maps loaded without Map constructor')
      delete (window as unknown as Record<string, unknown>)[callbackName]
    }

    const script = document.createElement('script')
    script.id = SCRIPT_ID
    script.async = true
    script.defer = true
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(GOOGLE_MAPS_API_KEY)}&v=weekly&libraries=places&callback=${callbackName}`
    script.onerror = () => fail('Failed to load Google Maps script')
    document.head.appendChild(script)

    window.setTimeout(() => {
      if (!window.google?.maps?.Map) {
        fail('Google Maps load timed out')
      }
    }, 15000)
  })

  return window.__abilityLinkMapsReady
}

export function triggerMapResize(map: GoogleMap | null) {
  if (!map || !window.google?.maps?.event) return
  window.google.maps.event.trigger(map, 'resize')
}

/** Resolve an address / place query via Google Geocoder (+ Places when available). */
export async function searchGoogleLocations(query: string): Promise<GeocodeHit[]> {
  const q = query.trim()
  if (!q) return []

  const maps = await loadGoogleMaps()

  // Prefer Places autocomplete → details for richer place names.
  if (maps.places?.AutocompleteService && maps.places.PlacesService) {
    try {
      const predictions = await new Promise<AutocompletePrediction[]>((resolve) => {
        const svc = new maps.places!.AutocompleteService()
        svc.getPlacePredictions({ input: q }, (preds, status) => {
          if (status === 'OK' && preds?.length) resolve(preds)
          else resolve([])
        })
      })

      if (predictions.length) {
        const holder = document.createElement('div')
        const placesSvc = new maps.places.PlacesService(holder)
        const details = await Promise.all(
          predictions.slice(0, 6).map(
            (p) =>
              new Promise<GeocodeHit | null>((resolve) => {
                placesSvc.getDetails(
                  {
                    placeId: p.place_id,
                    fields: ['formatted_address', 'geometry', 'name', 'address_components'],
                  },
                  (place, status) => {
                    if (status !== 'OK' || !place?.geometry?.location) {
                      resolve(null)
                      return
                    }
                    const comps = place.address_components
                    const city =
                      componentName(comps, 'locality') ||
                      componentName(comps, 'administrative_area_level_2') ||
                      componentName(comps, 'administrative_area_level_1')
                    const country = componentName(comps, 'country')
                    const address = place.formatted_address || p.description
                    resolve({
                      label: place.name ? `${place.name} — ${address}` : p.description,
                      address,
                      lat: place.geometry.location.lat(),
                      lng: place.geometry.location.lng(),
                      city,
                      country,
                    })
                  },
                )
              }),
          ),
        )
        const hits = details.filter((h): h is GeocodeHit => h != null)
        if (hits.length) return hits
      }
    } catch {
      // fall through to Geocoder
    }
  }

  return new Promise<GeocodeHit[]>((resolve, reject) => {
    const geocoder = new maps.Geocoder()
    geocoder.geocode({ address: q }, (results, status) => {
      if (status === 'OK' && results?.length) {
        resolve(results.slice(0, 6).map(hitFromGeocode))
        return
      }
      if (status === 'ZERO_RESULTS') {
        resolve([])
        return
      }
      reject(new Error(`Location search failed (${status}). Try a fuller address.`))
    })
  })
}

/** Reverse-geocode a map pin into address fields. */
export async function reverseGeocode(lat: number, lng: number): Promise<GeocodeHit | null> {
  const maps = await loadGoogleMaps()
  return new Promise((resolve) => {
    const geocoder = new maps.Geocoder()
    geocoder.geocode({ location: { lat, lng } }, (results, status) => {
      if (status === 'OK' && results?.[0]) resolve(hitFromGeocode(results[0]))
      else resolve(null)
    })
  })
}
