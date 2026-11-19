import { useEffect, useState } from 'react'
import type { Keys, PromptState, VehicleData } from './types'
import { Panel, PAGE_COUNT } from './Panel'
import { Prompt } from './Prompt'
import { Tracker } from './Tracker'
import { fetchNui, isBrowser, mockVehicle } from './nui'

// Browser preview (npm run dev): E toggles the panel, G cycles pages, ?view=tracker shows the tracker
const previewTracker = isBrowser && new URLSearchParams(location.search).get('view') === 'tracker'
const hiddenPrompt: PromptState = { visible: false, x: 0, y: 0, label: '', key: '' }

/** In-game overlay: hood inspect panel, its key prompt and the /tracker screen */
export default function App() {
  const [data, setData] = useState<VehicleData | null>(isBrowser && !previewTracker ? mockVehicle : null)
  const [keys, setKeys] = useState<Keys>({ close: 'E', cycle: 'G' })
  const [page, setPage] = useState(0)
  const [trackerOpen, setTrackerOpen] = useState(previewTracker)
  const [prompt, setPrompt] = useState<PromptState>(
    isBrowser && !previewTracker ? { visible: true, x: 0.42, y: 0.14, label: 'Close', key: 'E' } : hiddenPrompt,
  )

  const closeTracker = () => {
    setTrackerOpen(false)
    fetchNui('closeTracker')
  }

  // Messages from client Lua (SendNUIMessage)
  useEffect(() => {
    const onMessage = (e: MessageEvent) => {
      const msg = e.data
      switch (msg?.action) {
        case 'open':
          setData(msg.data)
          setKeys(msg.keys)
          setPage(0)
          break
        case 'close':
          setData(null)
          break
        case 'cycle':
          setPage((p) => (p + 1) % PAGE_COUNT)
          break
        case 'prompt':
          setPrompt(msg)
          break
        case 'tracker':
          setTrackerOpen(true)
          break
      }
    }
    window.addEventListener('message', onMessage)
    return () => window.removeEventListener('message', onMessage)
  }, [])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && trackerOpen) return closeTracker()
      if (!isBrowser || trackerOpen) return
      if (e.key.toLowerCase() === 'g') setPage((p) => (p + 1) % PAGE_COUNT)
      if (e.key.toLowerCase() === 'e') setData((d) => (d ? null : mockVehicle))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [trackerOpen])

  return (
    <>
      {isBrowser && <div className="preview-bg" />}
      <Prompt prompt={prompt} />
      {data && <Panel data={data} page={page} cycleKey={keys.cycle} />}
      {trackerOpen && (
        <div className="tracker-window">
          <Tracker onClose={closeTracker} />
        </div>
      )}
    </>
  )
}
