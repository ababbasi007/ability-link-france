import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth'
import { auth, firebaseReady } from './firebase'
import {
  canAccessPanel,
  hasRole,
  isAdmin,
  isModerator,
  loadPlatformConfig,
  rolesForUid,
  seedPlatformConfigIfMissing,
  type AdminRole,
  type PlatformConfig,
} from './data'

type AuthState = {
  user: User | null
  config: PlatformConfig | null
  loading: boolean
  ready: boolean
  allowed: boolean
  admin: boolean
  roles: AdminRole[]
  hasRole: (role: AdminRole | AdminRole[]) => boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
  refreshConfig: () => Promise<void>
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthState | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [config, setConfig] = useState<PlatformConfig | null>(null)
  const [loading, setLoading] = useState(true)

  const refreshConfig = async () => {
    const next = await loadPlatformConfig()
    setConfig(next)
  }

  const refreshUser = async () => {
    if (!auth?.currentUser) return
    await auth.currentUser.reload()
    setUser(auth.currentUser)
  }

  useEffect(() => {
    if (!auth) {
      setLoading(false)
      return
    }
    return onAuthStateChanged(auth, async (u) => {
      setUser(u)
      if (u) {
        try {
          let next = await loadPlatformConfig()
          if (!next) {
            try {
              next = await seedPlatformConfigIfMissing(u.uid)
            } catch {
              // Rules may still block create until firestore.rules are deployed.
            }
          }
          setConfig(next)
        } catch {
          setConfig(null)
        }
      } else {
        setConfig(null)
      }
      setLoading(false)
    })
  }, [])

  const value = useMemo<AuthState>(
    () => ({
      user,
      config,
      loading,
      ready: firebaseReady,
      allowed: canAccessPanel(config, user?.uid ?? null),
      admin: isAdmin(config, user?.uid ?? null),
      roles: rolesForUid(config, user?.uid ?? null),
      hasRole: (role) => hasRole(config, user?.uid ?? null, role),
      login: async (email, password) => {
        if (!auth) throw new Error('Firebase not configured — copy .env.example to .env.local')
        await signInWithEmailAndPassword(auth, email, password)
      },
      logout: async () => {
        if (auth) await signOut(auth)
      },
      refreshConfig,
      refreshUser,
    }),
    [user, config, loading],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth outside AuthProvider')
  return ctx
}

/** Re-export for route guards. */
export { isModerator }
