import type { PromptState } from './types'
import { KeyCap } from './icons'

export function Prompt({ prompt }: { prompt: PromptState }) {
  if (!prompt.visible) return null

  return (
    <div className="prompt" style={{ left: `${prompt.x * 100}vw`, top: `${prompt.y * 100}vh` }}>
      <KeyCap label={prompt.key} />
      <span>{prompt.label}</span>
    </div>
  )
}
