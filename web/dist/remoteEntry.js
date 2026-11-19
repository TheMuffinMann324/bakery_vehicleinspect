// NPWD external app entry.
// NPWD loads https://cfx-nui-<resource>/web/dist/remoteEntry.js as a Vite module-federation
// remote and asks it for './config'. This is a tiny hand-written remote: it bundles no React,
// it uses NPWD's own React from the shared scope (see npwd-config.js).

export const __tla = Promise.resolve()

/** NPWD passes its shared modules (react, react-dom, ...) here. */
export const init = (shared) => {
  const root = (globalThis.__federation_shared__ = globalThis.__federation_shared__ || {})
  for (const [name, versions] of Object.entries(shared || {})) {
    for (const [version, entry] of Object.entries(versions)) {
      const scope = (root[entry.scope || 'default'] = root[entry.scope || 'default'] || {})
      scope[name] = scope[name] || {}
      scope[name][version] = entry
    }
  }
}

export const get = async (module) => {
  if (module !== './config') throw new Error('Can not find remote module ' + module)
  const mod = await import('./npwd-config.js')
  return () => mod
}

export const dynamicLoadingCss = () => {}
