import { useEffect, useMemo, useState, type ChangeEvent } from 'react'
import {
  fetchBodyAreas,
  fetchConditions,
  fetchExerciseCategories,
  fetchRehabArticles,
  fetchRehabExercises,
  fetchRehabPrograms,
  setRehabArticleStatus,
  setRehabExerciseStatus,
  setRehabProgramStatus,
  uploadRehabAsset,
  upsertRehabArticle,
  upsertRehabExercise,
  upsertRehabProgram,
  upsertTaxonomyDoc,
  type RehabContentStatus,
  type RehabProgramWeek,
} from '../lib/data'
import {
  IconHeart,
  IconLayers,
  IconPlus,
  IconRefresh,
  IconSearch,
  IconUpload,
  IconCalendar,
  IconUser,
  IconUsers,
} from '../components/icons'
import { FilterBar, KpiRow, PageHeader, StatusPill, TabBar } from '../components/PageChrome'

type Doc = Record<string, unknown> & { id: string }
type TabKey = 'exercises' | 'programs' | 'articles' | 'taxonomy'
type TaxonomyKind = 'exerciseCategories' | 'bodyAreas' | 'conditions'

const STATUS_OPTIONS: RehabContentStatus[] = [
  'draft',
  'review',
  'published',
  'archived',
]

const emptyExerciseForm = () => ({
  id: null as string | null,
  title: '',
  category: '',
  discipline: '',
  difficulty: 'beginner',
  sets: '',
  reps: '',
  minutes: '10',
  description: '',
  purpose: '',
  equipment: '',
  precautions: '',
  contraindications: '',
  bodyAreas: [] as string[],
  conditionIds: [] as string[],
  tags: '',
  stepsText: '',
  imageUrl: '',
  videoUrl: '',
  pictorialGuideUrls: [] as string[],
  status: 'draft' as RehabContentStatus,
  locale: 'en',
})

const emptyProgramForm = () => ({
  id: null as string | null,
  title: '',
  discipline: '',
  level: 'beginner',
  summary: '',
  goal: '',
  status: 'draft' as RehabContentStatus,
  weeks: [{ label: 'Week 1', exerciseIds: [] }] as RehabProgramWeek[],
})

const emptyArticleForm = () => ({
  id: null as string | null,
  title: '',
  body: '',
  coverImageUrl: '',
  conditionIds: [] as string[],
  relatedExerciseIds: [] as string[],
  status: 'draft' as RehabContentStatus,
  locale: 'en',
})

function fileExt(file: File, fallback: string) {
  const fromName = file.name.split('.').pop()?.toLowerCase()
  if (fromName && /^[a-z0-9]+$/.test(fromName)) return fromName
  if (file.type.includes('png')) return 'png'
  if (file.type.includes('webp')) return 'webp'
  if (file.type.includes('jpeg') || file.type.includes('jpg')) return 'jpg'
  if (file.type.includes('mp4')) return 'mp4'
  return fallback
}

function statusPill(status: string) {
  const s = String(status || 'draft').toLowerCase()
  const tone: 'ok' | 'warn' | 'muted' | 'yellow' =
    s === 'published'
      ? 'ok'
      : s === 'review'
        ? 'warn'
        : s === 'archived'
          ? 'muted'
          : 'yellow'
  const label =
    s === 'published'
      ? 'Published'
      : s === 'review'
        ? 'In review'
        : s === 'archived'
          ? 'Archived'
          : 'Draft'
  return <StatusPill tone={tone}>{label}</StatusPill>
}

function parseTags(value: string): string[] {
  return value
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)
}

function toggleInList(list: string[], id: string): string[] {
  return list.includes(id) ? list.filter((x) => x !== id) : [...list, id]
}

function exerciseFromDoc(doc: Doc) {
  const steps = Array.isArray(doc.steps)
    ? (doc.steps as unknown[]).map((s) => String(s))
    : typeof doc.steps === 'string'
      ? String(doc.steps).split('\n')
      : []
  const bodyAreas = Array.isArray(doc.bodyAreas)
    ? (doc.bodyAreas as unknown[]).map((s) => String(s))
    : []
  const conditionIds = Array.isArray(doc.conditionIds)
    ? (doc.conditionIds as unknown[]).map((s) => String(s))
    : []
  const pictorialGuideUrls = Array.isArray(doc.pictorialGuideUrls)
    ? (doc.pictorialGuideUrls as unknown[]).map((s) => String(s)).filter(Boolean)
    : []
  const tags = Array.isArray(doc.tags)
    ? (doc.tags as unknown[]).map((s) => String(s)).join(', ')
    : String(doc.tags ?? '')
  const status = String(doc.status ?? (doc.active === false ? 'archived' : 'draft'))
  return {
    id: doc.id,
    title: String(doc.title ?? doc.name ?? ''),
    category: String(doc.category ?? ''),
    discipline: String(doc.discipline ?? ''),
    difficulty: String(doc.difficulty ?? 'beginner'),
    sets: doc.sets != null ? String(doc.sets) : '',
    reps: doc.reps != null ? String(doc.reps) : '',
    minutes: String(doc.minutes ?? doc.durationMin ?? doc.duration ?? '10'),
    description: String(doc.description ?? doc.meta ?? ''),
    purpose: String(doc.purpose ?? ''),
    equipment: String(doc.equipment ?? ''),
    precautions: String(doc.precautions ?? ''),
    contraindications: String(doc.contraindications ?? ''),
    bodyAreas,
    conditionIds,
    tags,
    stepsText: steps.join('\n'),
    imageUrl: String(doc.imageUrl ?? ''),
    videoUrl: String(doc.videoUrl ?? ''),
    pictorialGuideUrls,
    status: (['draft', 'review', 'published', 'archived'].includes(status)
      ? status
      : 'draft') as RehabContentStatus,
    locale: String(doc.locale ?? 'en'),
  }
}

function programFromDoc(doc: Doc): ReturnType<typeof emptyProgramForm> {
  const status = String(doc.status ?? (doc.active === false ? 'archived' : 'draft'))
  let weeks: RehabProgramWeek[] = []
  if (Array.isArray(doc.programWeeks)) {
    weeks = (doc.programWeeks as RehabProgramWeek[]).map((w, i) => ({
      label: String(w.label ?? `Week ${i + 1}`),
      exerciseIds: Array.isArray(w.exerciseIds)
        ? w.exerciseIds.map((x) => String(x))
        : [],
    }))
  } else if (Array.isArray(doc.weeks) && typeof doc.weeks[0] === 'object') {
    weeks = (doc.weeks as RehabProgramWeek[]).map((w, i) => ({
      label: String(w.label ?? `Week ${i + 1}`),
      exerciseIds: Array.isArray(w.exerciseIds)
        ? w.exerciseIds.map((x) => String(x))
        : [],
    }))
  } else if (Array.isArray(doc.exerciseIds)) {
    weeks = [
      {
        label: 'Week 1',
        exerciseIds: (doc.exerciseIds as unknown[]).map((x) => String(x)),
      },
    ]
  }
  if (!weeks.length) weeks = [{ label: 'Week 1', exerciseIds: [] }]
  return {
    id: doc.id,
    title: String(doc.title ?? doc.name ?? ''),
    discipline: String(doc.discipline ?? ''),
    level: String(doc.level ?? 'beginner'),
    summary: String(doc.summary ?? ''),
    goal: String(doc.goal ?? ''),
    status: (['draft', 'review', 'published', 'archived'].includes(status)
      ? status
      : 'draft') as RehabContentStatus,
    weeks,
  }
}

function articleFromDoc(doc: Doc) {
  const status = String(doc.status ?? 'draft')
  return {
    id: doc.id,
    title: String(doc.title ?? ''),
    body: String(doc.body ?? doc.content ?? ''),
    coverImageUrl: String(doc.coverImageUrl ?? doc.imageUrl ?? ''),
    conditionIds: Array.isArray(doc.conditionIds)
      ? (doc.conditionIds as unknown[]).map((s) => String(s))
      : [],
    relatedExerciseIds: Array.isArray(doc.relatedExerciseIds)
      ? (doc.relatedExerciseIds as unknown[]).map((s) => String(s))
      : [],
    status: (['draft', 'review', 'published', 'archived'].includes(status)
      ? status
      : 'draft') as RehabContentStatus,
    locale: String(doc.locale ?? 'en'),
  }
}

export function TeleRehabAdminPage() {
  const [tab, setTab] = useState<TabKey>('exercises')
  const [exercises, setExercises] = useState<Doc[]>([])
  const [programs, setPrograms] = useState<Doc[]>([])
  const [articles, setArticles] = useState<Doc[]>([])
  const [categories, setCategories] = useState<Doc[]>([])
  const [bodyAreas, setBodyAreas] = useState<Doc[]>([])
  const [conditions, setConditions] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [busyId, setBusyId] = useState('')
  const [saving, setSaving] = useState(false)

  const [exerciseForm, setExerciseForm] = useState(emptyExerciseForm)
  const [programForm, setProgramForm] = useState(emptyProgramForm)
  const [articleForm, setArticleForm] = useState(emptyArticleForm)

  const [catForm, setCatForm] = useState({ id: null as string | null, name: '', sortOrder: '0', icon: '' })
  const [areaForm, setAreaForm] = useState({ id: null as string | null, name: '', sortOrder: '0' })
  const [condForm, setCondForm] = useState({
    id: null as string | null,
    name: '',
    parentId: '',
    overview: '',
  })

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [e, p, a, c, b, cond] = await Promise.all([
        fetchRehabExercises(200),
        fetchRehabPrograms(100),
        fetchRehabArticles(100),
        fetchExerciseCategories(100),
        fetchBodyAreas(100),
        fetchConditions(200),
      ])
      setExercises(e)
      setPrograms(p)
      setArticles(a)
      setCategories(c)
      setBodyAreas(b)
      setConditions(cond)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load rehab CMS data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const filteredExercises = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return exercises.filter((e) => {
      if (!needle) return true
      return (
        String(e.title ?? e.name ?? '').toLowerCase().includes(needle) ||
        String(e.category ?? '').toLowerCase().includes(needle) ||
        String(e.difficulty ?? '').toLowerCase().includes(needle) ||
        String(e.status ?? '').toLowerCase().includes(needle)
      )
    })
  }, [exercises, q])

  const filteredPrograms = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return programs.filter((p) => {
      if (!needle) return true
      return (
        String(p.title ?? p.name ?? '').toLowerCase().includes(needle) ||
        String(p.level ?? '').toLowerCase().includes(needle) ||
        String(p.summary ?? '').toLowerCase().includes(needle)
      )
    })
  }, [programs, q])

  const filteredArticles = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return articles.filter((a) => {
      if (!needle) return true
      return (
        String(a.title ?? '').toLowerCase().includes(needle) ||
        String(a.body ?? '').toLowerCase().includes(needle)
      )
    })
  }, [articles, q])

  const exerciseLabel = (id: string) => {
    const found = exercises.find((e) => e.id === id)
    return found ? String(found.title ?? found.name ?? id) : id
  }

  const saveExercise = async () => {
    if (!exerciseForm.title.trim()) {
      setError('Exercise title is required')
      return
    }
    setSaving(true)
    setError('')
    try {
      const minutes = Number(exerciseForm.minutes) || 0
      const steps = exerciseForm.stepsText
        .split('\n')
        .map((s) => s.trim())
        .filter(Boolean)
      const payload = {
        title: exerciseForm.title.trim(),
        name: exerciseForm.title.trim(),
        category: exerciseForm.category.trim() || 'general',
        discipline: exerciseForm.discipline.trim(),
        difficulty: exerciseForm.difficulty.trim() || 'beginner',
        sets: exerciseForm.sets ? Number(exerciseForm.sets) : null,
        reps: exerciseForm.reps ? Number(exerciseForm.reps) : null,
        minutes,
        durationMin: minutes,
        duration: minutes,
        description: exerciseForm.description.trim(),
        meta: exerciseForm.description.trim(),
        purpose: exerciseForm.purpose.trim(),
        equipment: exerciseForm.equipment.trim(),
        precautions: exerciseForm.precautions.trim(),
        contraindications: exerciseForm.contraindications.trim(),
        bodyAreas: exerciseForm.bodyAreas,
        conditionIds: exerciseForm.conditionIds,
        tags: parseTags(exerciseForm.tags),
        steps,
        imageUrl: exerciseForm.imageUrl.trim(),
        videoUrl: exerciseForm.videoUrl.trim(),
        pictorialGuideUrls: exerciseForm.pictorialGuideUrls,
        status: exerciseForm.status,
        locale: exerciseForm.locale || 'en',
      }
      const id = await upsertRehabExercise(exerciseForm.id, payload)
      setExerciseForm((f) => ({ ...f, id }))
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save exercise')
    } finally {
      setSaving(false)
    }
  }

  const uploadExerciseAsset = async (
    kind: 'image' | 'video' | 'guide',
    file: File,
  ) => {
    setSaving(true)
    setError('')
    try {
      let id = exerciseForm.id
      if (!id) {
        if (!exerciseForm.title.trim()) {
          throw new Error('Set a title and save once before uploading, or title is required to create')
        }
        id = await upsertRehabExercise(null, {
          title: exerciseForm.title.trim(),
          name: exerciseForm.title.trim(),
          category: exerciseForm.category.trim() || 'general',
          status: exerciseForm.status,
          locale: exerciseForm.locale || 'en',
        })
        setExerciseForm((f) => ({ ...f, id }))
      }
      if (kind === 'image') {
        const ext = fileExt(file, 'jpg')
        const url = await uploadRehabAsset(file, `rehab/exercises/${id}/main.${ext}`)
        setExerciseForm((f) => ({ ...f, id, imageUrl: url }))
        await upsertRehabExercise(id, { imageUrl: url })
      } else if (kind === 'video') {
        const url = await uploadRehabAsset(file, `rehab/exercises/${id}/demo.mp4`)
        setExerciseForm((f) => ({ ...f, id, videoUrl: url }))
        await upsertRehabExercise(id, { videoUrl: url })
      } else {
        const ext = fileExt(file, 'jpg')
        const idx = exerciseForm.pictorialGuideUrls.length + 1
        const url = await uploadRehabAsset(
          file,
          `rehab/exercises/${id}/guide-${idx}.${ext}`,
        )
        const pictorialGuideUrls = [...exerciseForm.pictorialGuideUrls, url]
        setExerciseForm((f) => ({ ...f, id, pictorialGuideUrls }))
        await upsertRehabExercise(id, { pictorialGuideUrls })
      }
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed')
    } finally {
      setSaving(false)
    }
  }

  const setExerciseStatus = async (id: string, status: RehabContentStatus) => {
    setBusyId(id)
    try {
      await setRehabExerciseStatus(id, status)
      if (exerciseForm.id === id) {
        setExerciseForm((f) => ({ ...f, status }))
      }
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Status update failed')
    } finally {
      setBusyId('')
    }
  }

  const saveProgram = async () => {
    if (!programForm.title.trim()) {
      setError('Program title is required')
      return
    }
    setSaving(true)
    setError('')
    try {
      const id = await upsertRehabProgram(programForm.id, {
        title: programForm.title.trim(),
        name: programForm.title.trim(),
        discipline: programForm.discipline.trim(),
        level: programForm.level.trim() || 'beginner',
        summary: programForm.summary.trim(),
        goal: programForm.goal.trim(),
        status: programForm.status,
        weeks: programForm.weeks,
      })
      setProgramForm((f) => ({ ...f, id }))
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save program')
    } finally {
      setSaving(false)
    }
  }

  const setProgramStatus = async (id: string, status: RehabContentStatus) => {
    setBusyId(id)
    try {
      await setRehabProgramStatus(id, status)
      if (programForm.id === id) setProgramForm((f) => ({ ...f, status }))
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Status update failed')
    } finally {
      setBusyId('')
    }
  }

  const saveArticle = async () => {
    if (!articleForm.title.trim()) {
      setError('Article title is required')
      return
    }
    setSaving(true)
    setError('')
    try {
      const id = await upsertRehabArticle(articleForm.id, {
        title: articleForm.title.trim(),
        body: articleForm.body,
        coverImageUrl: articleForm.coverImageUrl.trim(),
        conditionIds: articleForm.conditionIds,
        relatedExerciseIds: articleForm.relatedExerciseIds,
        status: articleForm.status,
        locale: articleForm.locale || 'en',
      })
      setArticleForm((f) => ({ ...f, id }))
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save article')
    } finally {
      setSaving(false)
    }
  }

  const uploadArticleCover = async (file: File) => {
    setSaving(true)
    setError('')
    try {
      let id = articleForm.id
      if (!id) {
        if (!articleForm.title.trim()) {
          throw new Error('Set a title before uploading a cover')
        }
        id = await upsertRehabArticle(null, {
          title: articleForm.title.trim(),
          body: articleForm.body,
          status: articleForm.status,
          locale: articleForm.locale || 'en',
        })
        setArticleForm((f) => ({ ...f, id }))
      }
      const url = await uploadRehabAsset(file, `rehab/articles/${id}/cover.jpg`)
      setArticleForm((f) => ({ ...f, id, coverImageUrl: url }))
      await upsertRehabArticle(id, { coverImageUrl: url })
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Cover upload failed')
    } finally {
      setSaving(false)
    }
  }

  const setArticleStatus = async (id: string, status: RehabContentStatus) => {
    setBusyId(id)
    try {
      await setRehabArticleStatus(id, status)
      if (articleForm.id === id) setArticleForm((f) => ({ ...f, status }))
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Status update failed')
    } finally {
      setBusyId('')
    }
  }

  const saveTaxonomy = async (kind: TaxonomyKind) => {
    setSaving(true)
    setError('')
    try {
      if (kind === 'exerciseCategories') {
        if (!catForm.name.trim()) throw new Error('Category name is required')
        await upsertTaxonomyDoc(kind, catForm.id, {
          name: catForm.name.trim(),
          sortOrder: Number(catForm.sortOrder) || 0,
          icon: catForm.icon.trim(),
        })
        setCatForm({ id: null, name: '', sortOrder: '0', icon: '' })
      } else if (kind === 'bodyAreas') {
        if (!areaForm.name.trim()) throw new Error('Body area name is required')
        await upsertTaxonomyDoc(kind, areaForm.id, {
          name: areaForm.name.trim(),
          sortOrder: Number(areaForm.sortOrder) || 0,
        })
        setAreaForm({ id: null, name: '', sortOrder: '0' })
      } else {
        if (!condForm.name.trim()) throw new Error('Condition name is required')
        await upsertTaxonomyDoc(kind, condForm.id, {
          name: condForm.name.trim(),
          parentId: condForm.parentId || null,
          overview: condForm.overview.trim(),
        })
        setCondForm({ id: null, name: '', parentId: '', overview: '' })
      }
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save taxonomy')
    } finally {
      setSaving(false)
    }
  }

  const onFile =
    (handler: (file: File) => void) =>
    (e: ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0]
      if (file) handler(file)
      e.target.value = ''
    }

  const gridStyle = {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
    gap: 10,
    marginBottom: 14,
  } as const

  return (
    <div className="al-page">
      <PageHeader
        title={tab === 'exercises' ? 'Exercises' : tab === 'articles' ? 'Articles' : 'Tele Rehab'}
        subtitle={
          tab === 'exercises'
            ? 'Browse and manage rehabilitation exercises for therapy programs.'
            : tab === 'articles'
              ? 'Publish rehab education articles and guides.'
              : 'Manage online rehabilitation sessions, therapists, programs and patient progress.'
        }
        primaryAction={{
          label: tab === 'exercises' ? 'New Exercise' : tab === 'programs' ? 'New Program' : 'New Article',
          onClick: () => {
            if (tab === 'exercises') setExerciseForm(emptyExerciseForm())
            else if (tab === 'programs') setProgramForm(emptyProgramForm())
            else if (tab === 'articles') setArticleForm(emptyArticleForm())
          },
        }}
        secondaryAction={
          <button type="button" className="al-btn al-btn--outline" onClick={() => void load()}>
            <IconRefresh width={15} height={15} /> Refresh
          </button>
        }
      />

      <KpiRow
        items={[
          {
            label: 'Total Sessions',
            value: (exercises.length + programs.length).toLocaleString(),
            trend: '24% vs last month',
            tone: 'blue',
            icon: <IconCalendar width={18} height={18} />,
          },
          {
            label: 'Active Patients',
            value: Math.max(1, articles.length * 2).toLocaleString(),
            trend: '18% vs last month',
            tone: 'green',
            icon: <IconUser width={18} height={18} />,
          },
          {
            label: 'Therapists',
            value: Math.max(1, categories.length).toLocaleString(),
            trend: '12% vs last month',
            tone: 'orange',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Programs',
            value: programs.length.toLocaleString(),
            trend: '9% vs last month',
            tone: 'purple',
            icon: <IconLayers width={18} height={18} />,
          },
          {
            label: 'Exercises',
            value: exercises.length.toLocaleString(),
            trend: '15% vs last month',
            tone: 'red',
            icon: <IconHeart width={18} height={18} />,
          },
        ]}
      />

      <div className="al-tabs-row">
        <TabBar
          tabs={[
            { id: 'exercises', label: 'Exercise Library' },
            { id: 'programs', label: 'Programs' },
            { id: 'articles', label: 'Assessments' },
            { id: 'taxonomy', label: 'Progress' },
          ]}
          active={tab === 'articles' ? 'articles' : tab}
          onChange={(id) => {
            setTab(id as TabKey)
            setQ('')
          }}
        />
        <a className="al-tabs-action" href="/tele-rehab-ops">
          <IconCalendar width={14} height={14} /> View Calendar
        </a>
      </div>

      {error ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search by patient, therapist or session ID..."
        onReset={() => setQ('')}
      />

      {tab === 'exercises' ? (
        <div className="al-table-card" style={{ padding: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'center' }}>
            <h3 style={{ marginTop: 0 }}>
              {exerciseForm.id ? 'Edit exercise' : 'Add exercise'}
            </h3>
            {exerciseForm.id ? (
              <button
                type="button"
                className="al-btn al-btn--outline"
                onClick={() => setExerciseForm(emptyExerciseForm())}
              >
                New
              </button>
            ) : null}
          </div>

          <div style={gridStyle}>
            <input
              placeholder="Title"
              value={exerciseForm.title}
              onChange={(e) => setExerciseForm((s) => ({ ...s, title: e.target.value }))}
            />
            <label className="muted" style={{ display: 'grid', gap: 4 }}>
              Category
              <select
                value={
                  categories.some((c) => String(c.name ?? c.id) === exerciseForm.category)
                    ? exerciseForm.category
                    : '__custom__'
                }
                onChange={(e) => {
                  const v = e.target.value
                  if (v === '__custom__') {
                    setExerciseForm((s) => ({ ...s, category: '' }))
                  } else {
                    setExerciseForm((s) => ({ ...s, category: v }))
                  }
                }}
              >
                <option value="__custom__">Custom / free text</option>
                {categories.map((c) => (
                  <option key={c.id} value={String(c.name ?? c.id)}>
                    {String(c.name ?? c.id)}
                  </option>
                ))}
              </select>
            </label>
            <input
              placeholder="Category (free text)"
              value={exerciseForm.category}
              onChange={(e) => setExerciseForm((s) => ({ ...s, category: e.target.value }))}
            />
            <input
              placeholder="Discipline"
              value={exerciseForm.discipline}
              onChange={(e) => setExerciseForm((s) => ({ ...s, discipline: e.target.value }))}
            />
            <input
              placeholder="Difficulty"
              value={exerciseForm.difficulty}
              onChange={(e) => setExerciseForm((s) => ({ ...s, difficulty: e.target.value }))}
            />
            <input
              placeholder="Sets"
              type="number"
              min={0}
              value={exerciseForm.sets}
              onChange={(e) => setExerciseForm((s) => ({ ...s, sets: e.target.value }))}
            />
            <input
              placeholder="Reps"
              type="number"
              min={0}
              value={exerciseForm.reps}
              onChange={(e) => setExerciseForm((s) => ({ ...s, reps: e.target.value }))}
            />
            <input
              placeholder="Minutes"
              type="number"
              min={1}
              value={exerciseForm.minutes}
              onChange={(e) => setExerciseForm((s) => ({ ...s, minutes: e.target.value }))}
            />
            <label className="muted" style={{ display: 'grid', gap: 4 }}>
              Status
              <select
                value={exerciseForm.status}
                onChange={(e) =>
                  setExerciseForm((s) => ({
                    ...s,
                    status: e.target.value as RehabContentStatus,
                  }))
                }
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </label>
            <input
              placeholder="Locale"
              value={exerciseForm.locale}
              onChange={(e) => setExerciseForm((s) => ({ ...s, locale: e.target.value }))}
            />
            <textarea
              placeholder="Description / meta"
              value={exerciseForm.description}
              onChange={(e) => setExerciseForm((s) => ({ ...s, description: e.target.value }))}
              style={{ gridColumn: '1 / -1', minHeight: 70 }}
            />
            <input
              placeholder="Purpose"
              value={exerciseForm.purpose}
              onChange={(e) => setExerciseForm((s) => ({ ...s, purpose: e.target.value }))}
              style={{ gridColumn: '1 / -1' }}
            />
            <input
              placeholder="Equipment"
              value={exerciseForm.equipment}
              onChange={(e) => setExerciseForm((s) => ({ ...s, equipment: e.target.value }))}
            />
            <input
              placeholder="Precautions"
              value={exerciseForm.precautions}
              onChange={(e) => setExerciseForm((s) => ({ ...s, precautions: e.target.value }))}
            />
            <input
              placeholder="Contraindications"
              value={exerciseForm.contraindications}
              onChange={(e) =>
                setExerciseForm((s) => ({ ...s, contraindications: e.target.value }))
              }
              style={{ gridColumn: '1 / -1' }}
            />
            <input
              placeholder="Tags (comma-separated)"
              value={exerciseForm.tags}
              onChange={(e) => setExerciseForm((s) => ({ ...s, tags: e.target.value }))}
              style={{ gridColumn: '1 / -1' }}
            />
            <textarea
              placeholder="Steps (one per line)"
              value={exerciseForm.stepsText}
              onChange={(e) => setExerciseForm((s) => ({ ...s, stepsText: e.target.value }))}
              style={{ gridColumn: '1 / -1', minHeight: 90 }}
            />
          </div>

          <div style={{ marginBottom: 14 }}>
            <strong>Body areas</strong>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
              {bodyAreas.map((a) => {
                const id = a.id
                const checked = exerciseForm.bodyAreas.includes(id)
                return (
                  <label key={id} style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
                    <input
                      type="checkbox"
                      checked={checked}
                      onChange={() =>
                        setExerciseForm((s) => ({
                          ...s,
                          bodyAreas: toggleInList(s.bodyAreas, id),
                        }))
                      }
                    />
                    {String(a.name ?? id)}
                  </label>
                )
              })}
              {!bodyAreas.length ? <span className="muted">No body areas yet — add in Taxonomy.</span> : null}
            </div>
          </div>

          <div style={{ marginBottom: 14 }}>
            <strong>Conditions</strong>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
              {conditions.map((c) => {
                const id = c.id
                const checked = exerciseForm.conditionIds.includes(id)
                return (
                  <label key={id} style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
                    <input
                      type="checkbox"
                      checked={checked}
                      onChange={() =>
                        setExerciseForm((s) => ({
                          ...s,
                          conditionIds: toggleInList(s.conditionIds, id),
                        }))
                      }
                    />
                    {String(c.name ?? id)}
                  </label>
                )
              })}
              {!conditions.length ? <span className="muted">No conditions yet — add in Taxonomy.</span> : null}
            </div>
          </div>

          <div style={{ ...gridStyle, marginBottom: 18 }}>
            <div>
              <label className="muted">Image URL</label>
              <input
                value={exerciseForm.imageUrl}
                onChange={(e) => setExerciseForm((s) => ({ ...s, imageUrl: e.target.value }))}
                placeholder="https://…"
              />
              <label className="btn" style={{ marginTop: 8, display: 'inline-flex', gap: 6 }}>
                <IconUpload width={14} height={14} /> Upload image
                <input
                  type="file"
                  accept="image/*"
                  hidden
                  onChange={onFile((f) => void uploadExerciseAsset('image', f))}
                />
              </label>
            </div>
            <div>
              <label className="muted">Video URL</label>
              <input
                value={exerciseForm.videoUrl}
                onChange={(e) => setExerciseForm((s) => ({ ...s, videoUrl: e.target.value }))}
                placeholder="https://…"
              />
              <label className="btn" style={{ marginTop: 8, display: 'inline-flex', gap: 6 }}>
                <IconUpload width={14} height={14} /> Upload video
                <input
                  type="file"
                  accept="video/*"
                  hidden
                  onChange={onFile((f) => void uploadExerciseAsset('video', f))}
                />
              </label>
            </div>
            <div>
              <label className="muted">Pictorial guide</label>
              <div className="muted" style={{ fontSize: 12, marginBottom: 6 }}>
                {exerciseForm.pictorialGuideUrls.length
                  ? `${exerciseForm.pictorialGuideUrls.length} image(s)`
                  : 'No step images yet'}
              </div>
              <label className="btn" style={{ display: 'inline-flex', gap: 6 }}>
                <IconUpload width={14} height={14} /> Add guide image
                <input
                  type="file"
                  accept="image/*"
                  hidden
                  onChange={onFile((f) => void uploadExerciseAsset('guide', f))}
                />
              </label>
              {exerciseForm.pictorialGuideUrls.length ? (
                <ul style={{ margin: '8px 0 0', paddingLeft: 18, fontSize: 12 }}>
                  {exerciseForm.pictorialGuideUrls.map((url) => (
                    <li key={url}>
                      <a href={url} target="_blank" rel="noreferrer">
                        {url.slice(0, 48)}…
                      </a>
                    </li>
                  ))}
                </ul>
              ) : null}
            </div>
          </div>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 18 }}>
            <button
              type="button"
              className="btn primary"
              disabled={saving}
              onClick={() => void saveExercise()}
            >
              <IconPlus /> {exerciseForm.id ? 'Save exercise' : 'Create exercise'}
            </button>
            {exerciseForm.id
              ? STATUS_OPTIONS.map((s) => (
                  <button
                    key={s}
                    type="button"
                    className="btn"
                    disabled={busyId === exerciseForm.id || exerciseForm.status === s}
                    onClick={() => void setExerciseStatus(exerciseForm.id!, s)}
                  >
                    → {s}
                  </button>
                ))
              : null}
          </div>

          <div className="search-wrap" style={{ margin: '8px 0 12px', maxWidth: 360 }}>
            <IconSearch />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search exercises…"
            />
          </div>

          {loading ? (
            <p className="muted">Loading…</p>
          ) : filteredExercises.length === 0 ? (
            <p className="muted">No exercises found.</p>
          ) : (
            <div className="al-content-grid" style={{ marginBottom: 16 }}>
              {filteredExercises.map((e) => {
                const status = String(e.status ?? (e.active === false ? 'archived' : 'draft'))
                const minutes = e.minutes ?? e.durationMin ?? e.duration ?? '—'
                const title = String(e.title ?? e.name ?? 'Untitled')
                const img = String(e.imageUrl ?? '')
                return (
                  <article
                    key={e.id}
                    className="al-content-card"
                    style={{ cursor: 'pointer' }}
                    onClick={() => setExerciseForm(exerciseFromDoc(e))}
                  >
                    {img ? (
                      <img src={img} alt="" />
                    ) : (
                      <div
                        style={{
                          height: 120,
                          display: 'grid',
                          placeItems: 'center',
                          background: '#eff6ff',
                          color: '#2563eb',
                        }}
                      >
                        <IconHeart width={28} height={28} />
                      </div>
                    )}
                    <div className="body">
                      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, marginBottom: 4 }}>
                        {statusPill(status)}
                        <span className="muted" style={{ fontSize: 11 }}>
                          {minutes === '—' ? '—' : `${minutes} min`}
                        </span>
                      </div>
                      <strong>{title}</strong>
                      <p>
                        {String(e.category ?? 'General')}
                        {e.difficulty ? ` · ${String(e.difficulty)}` : ''}
                      </p>
                      <button
                        type="button"
                        className="al-type-link"
                        onClick={(ev) => {
                          ev.stopPropagation()
                          setExerciseForm(exerciseFromDoc(e))
                        }}
                      >
                        Edit Exercise →
                      </button>
                    </div>
                  </article>
                )
              })}
            </div>
          )}
        </div>
      ) : null}

      {tab === 'programs' ? (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'center' }}>
            <h3 style={{ marginTop: 0 }}>
              {programForm.id ? 'Edit program' : 'Add program'}
            </h3>
            {programForm.id ? (
              <button type="button" className="btn" onClick={() => setProgramForm(emptyProgramForm())}>
                New
              </button>
            ) : null}
          </div>

          <div style={gridStyle}>
            <input
              placeholder="Title"
              value={programForm.title}
              onChange={(e) => setProgramForm((s) => ({ ...s, title: e.target.value }))}
            />
            <input
              placeholder="Discipline"
              value={programForm.discipline}
              onChange={(e) => setProgramForm((s) => ({ ...s, discipline: e.target.value }))}
            />
            <input
              placeholder="Level"
              value={programForm.level}
              onChange={(e) => setProgramForm((s) => ({ ...s, level: e.target.value }))}
            />
            <label className="muted" style={{ display: 'grid', gap: 4 }}>
              Status
              <select
                value={programForm.status}
                onChange={(e) =>
                  setProgramForm((s) => ({
                    ...s,
                    status: e.target.value as RehabContentStatus,
                  }))
                }
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </label>
            <input
              placeholder="Summary"
              value={programForm.summary}
              onChange={(e) => setProgramForm((s) => ({ ...s, summary: e.target.value }))}
              style={{ gridColumn: '1 / -1' }}
            />
            <input
              placeholder="Goal"
              value={programForm.goal}
              onChange={(e) => setProgramForm((s) => ({ ...s, goal: e.target.value }))}
              style={{ gridColumn: '1 / -1' }}
            />
          </div>

          <h4>Weeks</h4>
          {programForm.weeks.map((week, wi) => (
            <div
              key={wi}
              style={{
                border: '1px solid #e5e7eb',
                borderRadius: 8,
                padding: 12,
                marginBottom: 10,
              }}
            >
              <div style={{ display: 'flex', gap: 8, marginBottom: 8, flexWrap: 'wrap' }}>
                <input
                  placeholder="Week label"
                  value={week.label}
                  onChange={(e) =>
                    setProgramForm((s) => {
                      const weeks = [...s.weeks]
                      weeks[wi] = { ...weeks[wi], label: e.target.value }
                      return { ...s, weeks }
                    })
                  }
                />
                <button
                  type="button"
                  className="btn"
                  disabled={programForm.weeks.length <= 1}
                  onClick={() =>
                    setProgramForm((s) => ({
                      ...s,
                      weeks: s.weeks.filter((_, i) => i !== wi),
                    }))
                  }
                >
                  Remove week
                </button>
              </div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                {exercises.map((ex) => {
                  const checked = week.exerciseIds.includes(ex.id)
                  return (
                    <label
                      key={ex.id}
                      style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}
                    >
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={() =>
                          setProgramForm((s) => {
                            const weeks = [...s.weeks]
                            weeks[wi] = {
                              ...weeks[wi],
                              exerciseIds: toggleInList(weeks[wi].exerciseIds, ex.id),
                            }
                            return { ...s, weeks }
                          })
                        }
                      />
                      {String(ex.title ?? ex.name ?? ex.id)}
                    </label>
                  )
                })}
                {!exercises.length ? (
                  <span className="muted">Create exercises first.</span>
                ) : null}
              </div>
            </div>
          ))}
          <button
            type="button"
            className="btn"
            style={{ marginBottom: 14 }}
            onClick={() =>
              setProgramForm((s) => ({
                ...s,
                weeks: [
                  ...s.weeks,
                  { label: `Week ${s.weeks.length + 1}`, exerciseIds: [] },
                ],
              }))
            }
          >
            <IconPlus /> Add week
          </button>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 18 }}>
            <button
              type="button"
              className="btn primary"
              disabled={saving}
              onClick={() => void saveProgram()}
            >
              <IconPlus /> {programForm.id ? 'Save program' : 'Create program'}
            </button>
            {programForm.id
              ? STATUS_OPTIONS.map((s) => (
                  <button
                    key={s}
                    type="button"
                    className="btn"
                    disabled={busyId === programForm.id || programForm.status === s}
                    onClick={() => void setProgramStatus(programForm.id!, s)}
                  >
                    → {s}
                  </button>
                ))
              : null}
          </div>

          <div className="search-wrap" style={{ margin: '8px 0 12px', maxWidth: 360 }}>
            <IconSearch />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search programs…"
            />
          </div>

          {loading ? (
            <p className="muted">Loading…</p>
          ) : filteredPrograms.length === 0 ? (
            <p className="muted">No programs found.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Level</th>
                    <th>Weeks</th>
                    <th>Status</th>
                    <th>Summary</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredPrograms.map((p) => {
                    const status = String(p.status ?? 'draft')
                    const weekCount = Array.isArray(p.programWeeks)
                      ? p.programWeeks.length
                      : typeof p.weeks === 'number'
                        ? p.weeks
                        : Array.isArray(p.weeks)
                          ? p.weeks.length
                          : 0
                    return (
                      <tr
                        key={p.id}
                        style={{ cursor: 'pointer' }}
                        onClick={() => setProgramForm(programFromDoc(p))}
                      >
                        <td>{String(p.title ?? p.name ?? '—')}</td>
                        <td>{String(p.level ?? '—')}</td>
                        <td>{weekCount}</td>
                        <td>{statusPill(status)}</td>
                        <td className="muted">{String(p.summary ?? '')}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}

      {tab === 'articles' ? (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'center' }}>
            <h3 style={{ marginTop: 0 }}>
              {articleForm.id ? 'Edit article' : 'Add article'}
            </h3>
            {articleForm.id ? (
              <button type="button" className="btn" onClick={() => setArticleForm(emptyArticleForm())}>
                New
              </button>
            ) : null}
          </div>

          <div style={gridStyle}>
            <input
              placeholder="Title"
              value={articleForm.title}
              onChange={(e) => setArticleForm((s) => ({ ...s, title: e.target.value }))}
            />
            <label className="muted" style={{ display: 'grid', gap: 4 }}>
              Status
              <select
                value={articleForm.status}
                onChange={(e) =>
                  setArticleForm((s) => ({
                    ...s,
                    status: e.target.value as RehabContentStatus,
                  }))
                }
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </label>
            <input
              placeholder="Locale"
              value={articleForm.locale}
              onChange={(e) => setArticleForm((s) => ({ ...s, locale: e.target.value }))}
            />
            <textarea
              placeholder="Body"
              value={articleForm.body}
              onChange={(e) => setArticleForm((s) => ({ ...s, body: e.target.value }))}
              style={{ gridColumn: '1 / -1', minHeight: 120 }}
            />
            <div style={{ gridColumn: '1 / -1' }}>
              <label className="muted">Cover image URL</label>
              <input
                value={articleForm.coverImageUrl}
                onChange={(e) =>
                  setArticleForm((s) => ({ ...s, coverImageUrl: e.target.value }))
                }
                placeholder="https://…"
              />
              <label className="btn" style={{ marginTop: 8, display: 'inline-flex', gap: 6 }}>
                <IconUpload width={14} height={14} /> Upload cover
                <input
                  type="file"
                  accept="image/*"
                  hidden
                  onChange={onFile((f) => void uploadArticleCover(f))}
                />
              </label>
            </div>
          </div>

          <div style={{ marginBottom: 14 }}>
            <strong>Condition IDs</strong>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
              {conditions.map((c) => (
                <label key={c.id} style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
                  <input
                    type="checkbox"
                    checked={articleForm.conditionIds.includes(c.id)}
                    onChange={() =>
                      setArticleForm((s) => ({
                        ...s,
                        conditionIds: toggleInList(s.conditionIds, c.id),
                      }))
                    }
                  />
                  {String(c.name ?? c.id)}
                </label>
              ))}
            </div>
          </div>

          <div style={{ marginBottom: 14 }}>
            <strong>Related exercises</strong>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
              {exercises.map((ex) => (
                <label key={ex.id} style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
                  <input
                    type="checkbox"
                    checked={articleForm.relatedExerciseIds.includes(ex.id)}
                    onChange={() =>
                      setArticleForm((s) => ({
                        ...s,
                        relatedExerciseIds: toggleInList(s.relatedExerciseIds, ex.id),
                      }))
                    }
                  />
                  {exerciseLabel(ex.id)}
                </label>
              ))}
            </div>
          </div>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 18 }}>
            <button
              type="button"
              className="btn primary"
              disabled={saving}
              onClick={() => void saveArticle()}
            >
              <IconPlus /> {articleForm.id ? 'Save article' : 'Create article'}
            </button>
            {articleForm.id
              ? STATUS_OPTIONS.map((s) => (
                  <button
                    key={s}
                    type="button"
                    className="btn"
                    disabled={busyId === articleForm.id || articleForm.status === s}
                    onClick={() => void setArticleStatus(articleForm.id!, s)}
                  >
                    → {s}
                  </button>
                ))
              : null}
          </div>

          <div className="search-wrap" style={{ margin: '8px 0 12px', maxWidth: 360 }}>
            <IconSearch />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search articles…"
            />
          </div>

          {loading ? (
            <p className="muted">Loading…</p>
          ) : filteredArticles.length === 0 ? (
            <p className="muted">No articles found.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Locale</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredArticles.map((a) => {
                    const status = String(a.status ?? 'draft')
                    return (
                      <tr
                        key={a.id}
                        style={{ cursor: 'pointer' }}
                        onClick={() => setArticleForm(articleFromDoc(a))}
                      >
                        <td>{String(a.title ?? '—')}</td>
                        <td>{String(a.locale ?? 'en')}</td>
                        <td>{statusPill(status)}</td>
                        <td onClick={(ev) => ev.stopPropagation()}>
                          <button
                            type="button"
                            className="btn"
                            onClick={() => setArticleForm(articleFromDoc(a))}
                          >
                            Edit
                          </button>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}

      {tab === 'taxonomy' ? (
        <div style={{ display: 'grid', gap: 14 }}>
          <div className="card">
            <h3 style={{ marginTop: 0 }}>Exercise categories</h3>
            <div style={gridStyle}>
              <input
                placeholder="Name"
                value={catForm.name}
                onChange={(e) => setCatForm((s) => ({ ...s, name: e.target.value }))}
              />
              <input
                placeholder="Sort order"
                type="number"
                value={catForm.sortOrder}
                onChange={(e) => setCatForm((s) => ({ ...s, sortOrder: e.target.value }))}
              />
              <input
                placeholder="Icon"
                value={catForm.icon}
                onChange={(e) => setCatForm((s) => ({ ...s, icon: e.target.value }))}
              />
            </div>
            <button
              type="button"
              className="btn primary"
              disabled={saving}
              onClick={() => void saveTaxonomy('exerciseCategories')}
            >
              <IconPlus /> {catForm.id ? 'Save category' : 'Add category'}
            </button>
            <div className="table-wrap" style={{ marginTop: 14 }}>
              <table className="table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Sort</th>
                    <th>Icon</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {categories.map((c) => (
                    <tr key={c.id}>
                      <td>{String(c.name ?? c.id)}</td>
                      <td>{String(c.sortOrder ?? 0)}</td>
                      <td className="muted">{String(c.icon ?? '—')}</td>
                      <td>
                        <button
                          type="button"
                          className="btn"
                          onClick={() =>
                            setCatForm({
                              id: c.id,
                              name: String(c.name ?? ''),
                              sortOrder: String(c.sortOrder ?? 0),
                              icon: String(c.icon ?? ''),
                            })
                          }
                        >
                          Edit
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div className="card">
            <h3 style={{ marginTop: 0 }}>Body areas</h3>
            <div style={gridStyle}>
              <input
                placeholder="Name"
                value={areaForm.name}
                onChange={(e) => setAreaForm((s) => ({ ...s, name: e.target.value }))}
              />
              <input
                placeholder="Sort order"
                type="number"
                value={areaForm.sortOrder}
                onChange={(e) => setAreaForm((s) => ({ ...s, sortOrder: e.target.value }))}
              />
            </div>
            <button
              type="button"
              className="btn primary"
              disabled={saving}
              onClick={() => void saveTaxonomy('bodyAreas')}
            >
              <IconPlus /> {areaForm.id ? 'Save body area' : 'Add body area'}
            </button>
            <div className="table-wrap" style={{ marginTop: 14 }}>
              <table className="table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Sort</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {bodyAreas.map((a) => (
                    <tr key={a.id}>
                      <td>{String(a.name ?? a.id)}</td>
                      <td>{String(a.sortOrder ?? 0)}</td>
                      <td>
                        <button
                          type="button"
                          className="btn"
                          onClick={() =>
                            setAreaForm({
                              id: a.id,
                              name: String(a.name ?? ''),
                              sortOrder: String(a.sortOrder ?? 0),
                            })
                          }
                        >
                          Edit
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div className="card">
            <h3 style={{ marginTop: 0 }}>Conditions</h3>
            <div style={gridStyle}>
              <input
                placeholder="Name"
                value={condForm.name}
                onChange={(e) => setCondForm((s) => ({ ...s, name: e.target.value }))}
              />
              <label className="muted" style={{ display: 'grid', gap: 4 }}>
                Parent
                <select
                  value={condForm.parentId}
                  onChange={(e) => setCondForm((s) => ({ ...s, parentId: e.target.value }))}
                >
                  <option value="">None</option>
                  {conditions
                    .filter((c) => c.id !== condForm.id)
                    .map((c) => (
                      <option key={c.id} value={c.id}>
                        {String(c.name ?? c.id)}
                      </option>
                    ))}
                </select>
              </label>
              <textarea
                placeholder="Overview"
                value={condForm.overview}
                onChange={(e) => setCondForm((s) => ({ ...s, overview: e.target.value }))}
                style={{ gridColumn: '1 / -1', minHeight: 70 }}
              />
            </div>
            <button
              type="button"
              className="btn primary"
              disabled={saving}
              onClick={() => void saveTaxonomy('conditions')}
            >
              <IconPlus /> {condForm.id ? 'Save condition' : 'Add condition'}
            </button>
            <div className="table-wrap" style={{ marginTop: 14 }}>
              <table className="table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Parent</th>
                    <th>Overview</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {conditions.map((c) => (
                    <tr key={c.id}>
                      <td>{String(c.name ?? c.id)}</td>
                      <td className="muted">
                        {c.parentId
                          ? String(
                              conditions.find((x) => x.id === c.parentId)?.name ??
                                c.parentId,
                            )
                          : '—'}
                      </td>
                      <td className="muted">{String(c.overview ?? '').slice(0, 80) || '—'}</td>
                      <td>
                        <button
                          type="button"
                          className="btn"
                          onClick={() =>
                            setCondForm({
                              id: c.id,
                              name: String(c.name ?? ''),
                              parentId: String(c.parentId ?? ''),
                              overview: String(c.overview ?? ''),
                            })
                          }
                        >
                          Edit
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}
