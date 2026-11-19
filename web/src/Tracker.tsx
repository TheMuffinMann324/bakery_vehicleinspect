import { useEffect, useState } from 'react'
import type { TrackedVehicle } from './types'
import { fetchNui } from './nui'

const statusClass = { Parked: 'grey', Moving: 'green', Stored: 'dim' } as const

function distance(m?: number) {
  if (m == null) return ''
  return m >= 1000 ? `${(m / 1000).toFixed(1)} km` : `${m} m`
}

/** GPS tracker app: used inside phones (phone.html) and as the standalone /tracker screen */
export function Tracker({ onClose }: { onClose?: () => void }) {
  const [list, setList] = useState<TrackedVehicle[] | null>(null)

  useEffect(() => {
    let alive = true
    const load = () =>
      fetchNui<TrackedVehicle[]>('getTrackers')
        .then((l) => alive && setList(Array.isArray(l) ? l : []))
        .catch(() => alive && setList([]))
    load()
    const id = setInterval(load, 5000)
    return () => {
      alive = false
      clearInterval(id)
    }
  }, [])

  return (
    <div className="tracker">
      <header>
        <div>
          <div className="make">GPS</div>
          <div className="model">Tracker</div>
        </div>
        {onClose && (
          <button className="x" onClick={onClose} aria-label="Close">
            ✕
          </button>
        )}
      </header>

      <div className="tracker-list">
        {list === null && <div className="empty">Locating…</div>}
        {list?.length === 0 && (
          <div className="empty">No tracked vehicles. Fit one at the vehicle registration clerk.</div>
        )}
        {list?.map((v) => (
          <div className="tracked" key={v.plate}>
            <div className="vehicle-head">
              <span>
                <span className="brand">{v.brand}</span> {v.name}
              </span>
              <span className="plate">{v.plate}</span>
            </div>
            <div className="where">
              <span className={`status ${statusClass[v.status]}`}>{v.status}</span>
              {v.street && <span className="street">{v.street}</span>}
              {v.distance != null && <span className="dist">{distance(v.distance)}</span>}
            </div>
            {v.coords && (
              <div className="actions">
                <button className="action" onClick={() => fetchNui('trackerWaypoint', { plate: v.plate })}>
                  Set waypoint
                </button>
                <button className="action" onClick={() => fetchNui('trackerPing', { plate: v.plate })}>
                  Ping on map
                </button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
