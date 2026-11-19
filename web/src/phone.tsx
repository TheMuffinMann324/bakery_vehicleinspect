import { createRoot } from 'react-dom/client'
import '@fontsource/barlow-semi-condensed/500.css'
import '@fontsource/barlow-semi-condensed/600.css'
import '@fontsource/barlow-semi-condensed/700.css'
import './styles.css'
import { Tracker } from './Tracker'

// Phone app entry (LB Phone / GKS / CodeM / NPWD load web/dist/phone.html in an iframe)
document.documentElement.classList.add('phone')
// NPWD shows the app below its own status bar, so no top padding there
if (new URLSearchParams(location.search).has('embedded')) document.documentElement.classList.add('embedded')
createRoot(document.getElementById('root')!).render(<Tracker />)
