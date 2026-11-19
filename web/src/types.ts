export interface VehicleData {
  make: string
  model: string
  locked: boolean
  /** none = no security system, armed = fitted (sets off for you), owner = fitted on your own car */
  security: 'none' | 'armed' | 'owner'
  tracker: 'none' | 'fitted' | 'owner'
  registered?: boolean
  sellValue: number
  registerCost: number
  stats: {
    speed: number
    acceleration: number
    asphalt: number
    offroad: number
    strength: number
  }
  rating: { road: number; offroad: number }
  info: {
    type: string
    era: string
    seats: number
    storage: number
    condition: string
    specialist: string
  }
}

export interface TrackedVehicle {
  plate: string
  brand?: string
  name?: string
  status: 'Parked' | 'Moving' | 'Stored'
  street?: string
  distance?: number
  coords?: { x: number; y: number; z: number }
}

export interface Keys {
  close: string
  cycle: string
}

export interface PromptState {
  visible: boolean
  x: number
  y: number
  label: string
  key: string
}
