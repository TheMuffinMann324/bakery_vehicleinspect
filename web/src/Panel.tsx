import type { ReactNode } from 'react'
import type { VehicleData } from './types'
import { BadgeIcon, Crown, GpsIcon, KeyCap, KeyIcon, PerfIcon, RoadIcon, ShieldIcon } from './icons'

export const PAGE_COUNT = 3

const money = (n: number) => '$' + Math.round(n).toLocaleString('en-US')

function Row({ label, children, tone }: { label: string; children: ReactNode; tone?: 'alert' | 'ok' }) {
  return (
    <div className={`row${tone ? ' ' + tone : ''}`}>
      <span className="label">{label}</span>
      <span className="value">{children}</span>
    </div>
  )
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div className="stat">
      <div className="stat-head">
        <span className="label">{label}</span>
        <span className="value">{value.toFixed(1)}</span>
      </div>
      <div className="bar">
        <div className="fill" style={{ width: `${Math.min(value, 10) * 10}%` }} />
      </div>
    </div>
  )
}

function AccessPage({ d }: { d: VehicleData }) {
  return (
    <div className="rows">
      <Row label="Access">
        {d.locked ? 'Locked' : 'Unlocked'}
        <span className={d.locked ? 'red' : 'green'}><KeyIcon /></span>
      </Row>
      <Row label="Security" tone={d.security === 'armed' ? 'alert' : d.security === 'owner' ? 'ok' : undefined}>
        {d.security === 'none' ? 'Deactivated' : d.security === 'armed' ? 'Alarm armed' : 'Alarm fitted'}
        <span className={d.security === 'armed' ? 'red' : d.security === 'owner' ? 'green' : 'grey'}>
          <ShieldIcon />
        </span>
      </Row>
      <Row label="Tracker" tone={d.tracker === 'fitted' ? 'alert' : d.tracker === 'owner' ? 'ok' : undefined}>
        {d.tracker === 'none' ? 'None' : 'GPS fitted'}
        {d.tracker !== 'none' && (
          <span className={d.tracker === 'fitted' ? 'amber' : 'green'}>
            <GpsIcon />
          </span>
        )}
      </Row>
      <Row label="Sell Value">{money(d.sellValue)}</Row>
      {d.registered ? (
        <Row label="Registration">
          Registered <span className="green">✓</span>
        </Row>
      ) : (
        <Row label="Cost to Register">{money(d.registerCost)}</Row>
      )}
    </div>
  )
}

function StatsPage({ d }: { d: VehicleData }) {
  return (
    <div className="rows stats">
      <Stat label="Speed" value={d.stats.speed} />
      <Stat label="Acceleration" value={d.stats.acceleration} />
      <Stat label="Asphalt Handling" value={d.stats.asphalt} />
      <Stat label="Off-Road Handling" value={d.stats.offroad} />
      <Stat label="Strength" value={d.stats.strength} />
      <div className="row rating">
        <span className="label">Rating</span>
        <span className="value">
          <span className="pair">{d.rating.road} <PerfIcon /></span>
          <span className="pair">{d.rating.offroad} <RoadIcon /></span>
        </span>
      </div>
    </div>
  )
}

function InfoPage({ d }: { d: VehicleData }) {
  return (
    <div className="rows">
      <Row label="Type">{d.info.type}</Row>
      <Row label="Era">{d.info.era}</Row>
      <Row label="Seats">{d.info.seats}</Row>
      <Row label="Storage">{d.info.storage}</Row>
      <Row label="Body Condition">{d.info.condition}</Row>
      <Row label="Specialist">
        {d.info.specialist}
        <BadgeIcon />
      </Row>
    </div>
  )
}

const pages = [AccessPage, StatsPage, InfoPage]

export function Panel({ data, page, cycleKey }: { data: VehicleData; page: number; cycleKey: string }) {
  const Page = pages[page]

  return (
    <div className="panel">
      <div className="pager">
        {pages.map((_, i) => (
          <span key={i} className={`dot${i === page ? ' active' : ''}`} />
        ))}
        <KeyCap label={cycleKey} />
      </div>

      <div className="card">
        <header>
          <div className="make">{data.make}</div>
          <div className="model">{data.model}</div>
          <Crown />
        </header>
        <div className="page" key={page}>
          <Page d={data} />
        </div>
      </div>
    </div>
  )
}
