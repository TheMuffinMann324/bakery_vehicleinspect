// NPWD app config for the GPS tracker.
// The app itself is the same tracker page the other phones use (phone.html), shown in an iframe.

const base = new URL('.', import.meta.url).href // https://cfx-nui-<resource>/web/dist/
const resource = new URL(import.meta.url).hostname.replace(/^cfx-nui-/, '')

/** NPWD's own React (module federation shared scope) */
async function hostReact() {
  const versions = globalThis.__federation_shared__?.default?.react
  if (!versions) throw new Error('NPWD did not share React')
  const mod = await (await Object.values(versions)[0].get())()
  return mod.createElement ? mod : mod.default
}

const React = await hostReact()
const h = React.createElement

const App = () =>
  h(
    'div',
    { style: { width: '100%', height: '100%', background: '#181a26' } },
    h('iframe', {
      src: base + 'phone.html?embedded=1',
      title: 'Tracker',
      style: { width: '100%', height: '100%', border: 0, display: 'block' },
    }),
  )

const Icon = () =>
  h('img', { src: base + 'tracker-icon.svg', alt: '', style: { width: '100%', height: '100%' } })

export const path = '/' + resource

export default () => ({
  id: resource,
  nameLocale: 'Tracker',
  color: '#ffffff',
  backgroundColor: '#2e3048',
  path,
  icon: Icon,
  notificationIcon: Icon,
  app: App,
})
