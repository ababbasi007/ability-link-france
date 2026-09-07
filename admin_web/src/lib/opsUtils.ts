export type OpsDoc = Record<string, unknown> & { id: string }

export function asDate(value: unknown): Date | null {
  if (!value) return null
  if (typeof value === 'string') {
    const d = new Date(value)
    return Number.isNaN(d.getTime()) ? null : d
  }
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    return (value as { toDate: () => Date }).toDate()
  }
  return null
}

export function formatWhen(value: unknown): string {
  const d = asDate(value)
  if (!d) return '—'
  return d.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

export function formatMoney(cents: unknown, currency = 'PKR'): string {
  const n = typeof cents === 'number' ? cents : Number(cents)
  if (!Number.isFinite(n)) return '—'
  const amount = n / 100
  return `${currency} ${amount.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`
}

export function cell(value: unknown): string {
  if (value == null || value === '') return '—'
  if (typeof value === 'object') return JSON.stringify(value).slice(0, 80)
  return String(value)
}
