import type { TrackedVehicle, VehicleData } from './types'

/**
 * In game every page (our overlay and the phone app iframe) is served from
 * https://cfx-nui-<resource>/... — anything else is the browser preview (npm run dev).
 */
const host = window.location.hostname
export const isBrowser = !host.startsWith('cfx-nui-')
const resource = isBrowser ? 'bakery_vehicleinspect' : host.slice('cfx-nui-'.length)

/** Calls a RegisterNUICallback in this resource. Works from the overlay and from phone iframes. */
export async function fetchNui<T = unknown>(event: string, data: unknown = {}): Promise<T> {
  if (isBrowser) return mockNui(event) as T
  const res = await fetch(`https://${resource}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  })
  return res.json()
}

// ---------- browser preview data ----------

export const mockVehicle: VehicleData = {
  make: 'Albany',
  model: "'85 Emperor",
  locked: false,
  security: 'armed',
  tracker: 'fitted',
  registered: false,
  sellValue: 860,
  registerCost: 5650,
  stats: { speed: 3.3, acceleration: 3.0, asphalt: 2.7, offroad: 3.3, strength: 3.0 },
  rating: { road: 191, offroad: 305 },
  info: { type: 'Sedan', era: '1980s Classic', seats: 4, storage: 4, condition: 'Average', specialist: 'Lowriders' },
}

const mockTrackers: TrackedVehicle[] = [
  { plate: 'BFQSAU2C', brand: 'Grotti', name: 'GT500', status: 'Parked', street: 'Carcer Way', distance: 52, coords: { x: 0, y: 0, z: 0 } },
  { plate: '0LF7PF22', brand: 'Pegassi', name: 'Faggio Sport', status: 'Stored' },
]

function mockNui(event: string) {
  return event === 'getTrackers' ? structuredClone(mockTrackers) : true
}
