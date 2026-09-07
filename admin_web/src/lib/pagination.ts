import {
  collection,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  where,
  type DocumentData,
  type QueryConstraint,
  type QueryDocumentSnapshot,
} from 'firebase/firestore'
import { db } from './firebase'

export type PageCursor = QueryDocumentSnapshot<DocumentData> | null

export type ListPageResult = {
  items: Array<DocumentData & { id: string }>
  /** Pass to the next call as `cursor` for the following page. */
  nextCursor: PageCursor
  hasMore: boolean
  /** Snapshot of the last doc on this page (same as nextCursor when hasMore). */
  lastDoc: PageCursor
}

export type ListPageParams = {
  collectionName: string
  pageSize?: number
  /** Exclusive start — last document from the previous page. */
  cursor?: PageCursor
  orderField?: string
  orderDirection?: 'asc' | 'desc'
  /** Equality filters only (Firestore constraint). */
  equality?: Record<string, string | boolean | number>
}

function mapDocs(
  docs: QueryDocumentSnapshot<DocumentData>[],
): Array<DocumentData & { id: string }> {
  return docs.map((d) => ({ id: d.id, ...d.data() }))
}

/**
 * Cursor-based Firestore page fetch (Phase 3).
 * Falls back to unordered limit if orderBy/index fails.
 */
export async function fetchCollectionPage(
  params: ListPageParams,
): Promise<ListPageResult> {
  if (!db) {
    return { items: [], nextCursor: null, hasMore: false, lastDoc: null }
  }
  const pageSize = Math.min(Math.max(params.pageSize ?? 25, 1), 100)
  const orderField = params.orderField ?? 'createdAt'
  const direction = params.orderDirection ?? 'desc'
  const equality = params.equality ?? {}

  const build = (withOrder: boolean, withCursor: boolean) => {
    const constraints: QueryConstraint[] = []
    for (const [field, value] of Object.entries(equality)) {
      if (value === undefined || value === null || value === '') continue
      constraints.push(where(field, '==', value))
    }
    if (withOrder) constraints.push(orderBy(orderField, direction))
    if (withCursor && params.cursor) constraints.push(startAfter(params.cursor))
    constraints.push(limit(pageSize + 1))
    return query(collection(db!, params.collectionName), ...constraints)
  }

  let snap
  try {
    snap = await getDocs(build(true, true))
  } catch {
    try {
      snap = await getDocs(build(true, false))
    } catch {
      snap = await getDocs(
        query(collection(db, params.collectionName), limit(pageSize + 1)),
      )
    }
  }

  const docs = snap.docs
  const hasMore = docs.length > pageSize
  const pageDocs = hasMore ? docs.slice(0, pageSize) : docs
  const lastDoc = pageDocs.length ? pageDocs[pageDocs.length - 1]! : null

  return {
    items: mapDocs(pageDocs),
    nextCursor: hasMore ? lastDoc : null,
    hasMore,
    lastDoc,
  }
}
