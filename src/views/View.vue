<template>
  <main class="notes-shell ext:h-full ext:overflow-hidden ext:p-4 md:ext:p-6">
    <AppLoadingSpinner v-if="isLoading" />

    <template v-else>
      <section class="ext:flex ext:h-full ext:flex-col ext:gap-4">
        <header class="notes-hero ext:rounded-[2rem] ext:p-5 md:ext:p-6">
          <div class="ext:flex ext:flex-col ext:gap-5 xl:ext:flex-row xl:ext:items-end xl:ext:justify-between">
            <div class="ext:max-w-3xl">
              <div class="notes-hero__eyebrow">
                <oc-icon name="sticky-note" fill-type="line" size="small" />
                <span>{{ $gettext('Notes workspace') }}</span>
              </div>

              <h1 class="ext:mt-4 ext:mb-2 ext:text-3xl md:ext:text-4xl ext:leading-tight">
                {{ notebookTitle }}
              </h1>
              <p class="notes-hero__copy ext:mb-0 ext:text-base md:ext:text-lg">
                {{
                  $gettext(
                    'Markdown pages, nested sections and file-native structure. Fast enough for working notes, boring enough to stay maintainable.'
                  )
                }}
              </p>
            </div>

            <div class="ext:w-full ext:max-w-md ext:self-start xl:ext:self-auto">
              <oc-text-input
                v-model="filterTerm"
                :label="$gettext('Search notes')"
                :clear-button-enabled="true"
                :fix-message-line="true"
                :placeholder="$gettext('Find a note by title')"
              />
              <p class="notes-hero__summary ext:mt-2 ext:mb-0 ext:text-sm">
                {{ searchSummary }}
              </p>
            </div>
          </div>

          <div class="ext:mt-5 ext:flex ext:flex-wrap ext:gap-2">
            <div class="notes-stat-chip">
              <span class="notes-stat-chip__value">{{ noteCount }}</span>
              <span>{{ $gettext('pages') }}</span>
            </div>
            <div class="notes-stat-chip">
              <span class="notes-stat-chip__value">{{ folderCount }}</span>
              <span>{{ $gettext('sections') }}</span>
            </div>
            <div class="notes-stat-chip" :class="{ 'notes-stat-chip--dirty': isDocumentDirty }">
              <span class="notes-stat-chip__value">{{ statusLabel }}</span>
              <span>{{ $gettext('editor state') }}</span>
            </div>
          </div>
        </header>

        <div class="notes-workspace ext:grid ext:min-h-0 ext:flex-1 ext:gap-4 xl:ext:grid-cols-[24rem_minmax(0,1fr)]">
          <oc-card class="notes-panel ext:min-h-0 ext:overflow-hidden">
            <TocWrapper class="ext:h-full" :filter-term="filterTerm" />
          </oc-card>

          <oc-card class="notes-panel ext:min-h-0 ext:overflow-hidden">
            <div class="notes-editor ext:flex ext:h-full ext:flex-col">
              <div class="notes-editor__header ext:px-5 ext:py-4 md:ext:px-6">
                <div class="ext:flex ext:flex-col ext:gap-4 md:ext:flex-row md:ext:items-start md:ext:justify-between">
                  <div class="ext:min-w-0">
                    <p class="notes-editor__eyebrow ext:mb-2">{{ $gettext('Current page') }}</p>
                    <h2 class="ext:my-0 ext:truncate ext:text-2xl">{{ documentTitle }}</h2>
                    <p class="notes-editor__subcopy ext:mt-2 ext:mb-0">
                      {{ documentSubtitle }}
                    </p>
                  </div>

                  <span class="notes-status-pill" :class="{ 'notes-status-pill--dirty': isDocumentDirty }">
                    {{ statusLabel }}
                  </span>
                </div>
              </div>

              <div class="ext:min-h-0 ext:flex-1 ext:overflow-hidden">
                <NoPageSelected
                  v-if="!documentResource"
                  :filter-term="filterTerm"
                  :note-count="noteCount"
                />
                <TextEditor
                  v-else
                  :resource="documentResource"
                  :current-content="documentContent"
                  :is-read-only="isReadOnly"
                  :application-config="{}"
                  @update:current-content="setDocumentContent"
                />
              </div>
            </div>
          </oc-card>
        </div>
      </section>
    </template>
  </main>
</template>

<script setup lang="ts">
import NoPageSelected from '../components/NoPageSelected.vue'
import TocWrapper from '../components/TocWrapper.vue'
import { extractNameWithoutExtension, Resource, SpaceResource } from '@opencloud-eu/web-client'
import { computed, onBeforeUnmount, onMounted, ref, unref, watchEffect } from 'vue'
import {
  AppLoadingSpinner,
  // @ts-ignore
  TextEditor,
  UnsavedChangesModal,
  queryItemAsString,
  useClientService,
  useModals,
  useRouteQuery,
  useRouter
} from '@opencloud-eu/web-pkg'
import {
  useActionsSaveCurrentDocument,
  useDocumentStore,
  useLoadToc,
  useNotebookStore,
  useSSE,
  useTocStore
} from '../composables'
import { storeToRefs } from 'pinia'
import { useGettext } from 'vue3-gettext'
import { countFolders, countNotes, getResourceLabel, searchNoteNodes } from '../util'

const { $gettext } = useGettext()
const { webdav } = useClientService()
const { dispatchModal } = useModals()
const { registerSSE, deregisterSSE } = useSSE()
const { savePage } = useActionsSaveCurrentDocument()
const router = useRouter()

const {
  space,
  resource,
  isReadOnly = false
} = defineProps<{
  currentContent: string
  space: SpaceResource
  resource: Resource
  isReadOnly?: boolean
}>()

const notebookStore = useNotebookStore()
const tocStore = useTocStore()
const { notebook } = storeToRefs(notebookStore)
const { tocNodes } = storeToRefs(tocStore)
const { loadToc } = useLoadToc()
watchEffect(async () => {
  notebookStore.setNotebook(space, resource)
  await loadToc()
})
const isLoading = computed(() => {
  return !notebookStore.isLoaded || !tocStore.isLoaded
})

const pageFileIdQuery = useRouteQuery('pageFileId', '')
const pageFileId = computed(() => {
  return queryItemAsString(unref(pageFileIdQuery))
})
const documentStore = useDocumentStore()
const { setDocumentContent } = documentStore
const { documentResource, documentContent, isDocumentDirty } = storeToRefs(documentStore)
const filterTerm = ref('')

const notebookTitle = computed(() => {
  return notebook.value ? getResourceLabel(notebook.value) : $gettext('Notes')
})

const noteCount = computed(() => countNotes(unref(tocNodes) || []))
const folderCount = computed(() => countFolders(unref(tocNodes) || []))
const searchMatchCount = computed(() => searchNoteNodes(unref(tocNodes) || [], unref(filterTerm)).length)

const searchSummary = computed(() => {
  if (unref(filterTerm).trim()) {
    return $gettext('%{count} matching pages', { count: searchMatchCount.value })
  }

  return $gettext('%{notes} pages across %{folders} sections', {
    notes: noteCount.value,
    folders: folderCount.value
  })
})

const documentTitle = computed(() => {
  if (!unref(documentResource)) {
    return $gettext('Nothing open yet')
  }

  return extractNameWithoutExtension(unref(documentResource))
})

const documentSubtitle = computed(() => {
  if (!unref(documentResource)) {
    if (unref(filterTerm).trim()) {
      return $gettext('Use the search results in the navigator to jump straight into a page.')
    }

    return $gettext('Select a page from the navigator or create a new note to begin writing.')
  }

  return $gettext('Markdown page inside %{name}', { name: notebookTitle.value })
})

const statusLabel = computed(() => {
  if (!unref(documentResource)) {
    return $gettext('Ready')
  }

  return unref(isDocumentDirty) ? $gettext('Unsaved') : $gettext('Saved')
})

watchEffect(async () => {
  if (!unref(pageFileId)) {
    return
  }
  const path = await webdav.getPathForFileId(unref(pageFileId))
  const [resource, content] = await Promise.all([
    webdav.getFileInfo(space, { fileId: unref(pageFileId), path }),
    webdav.getFileContents(space, { fileId: unref(pageFileId), path })
  ])
  documentStore.setDocument(resource, content.body)
})

let unregisterRouterGuard: (() => void) | undefined
const preventBrowserClose = (e: Event) => {
  if (unref(isDocumentDirty)) {
    e.preventDefault()
  }
}

onMounted(() => {
  registerSSE()

  // register document-content safeguards
  window.addEventListener('beforeunload', preventBrowserClose)
  unregisterRouterGuard = router.beforeEach((_to, _from, next) => {
    if (unref(isDocumentDirty)) {
      dispatchModal({
        title: $gettext('Unsaved changes'),
        customComponent: UnsavedChangesModal,
        focusTrapInitial: '.oc-modal-body-actions-confirm',
        hideActions: true,
        customComponentAttrs: () => {
          return {
            closeCallback: () => {
              next()
            }
          }
        },
        async onConfirm() {
          await savePage(() => {
            next()
          })
        }
      })
      return
    }
    next()
  })
})

onBeforeUnmount(() => {
  notebookStore.clearNotebook()
  tocStore.clearTocNodes()
  documentStore.clearDocument()
  deregisterSSE()

  // unregister document-content safeguards
  unregisterRouterGuard?.()
  window.removeEventListener('beforeunload', preventBrowserClose)
})
</script>

<style scoped>
.notes-shell {
  background:
    radial-gradient(circle at 10% 10%, rgba(37, 99, 235, 0.15), transparent 45%),
    radial-gradient(circle at 90% 90%, rgba(139, 92, 246, 0.12), transparent 40%),
    linear-gradient(180deg, rgba(15, 23, 42, 0.02), transparent 36%);
}

.notes-hero {
  border: 1px solid rgba(255, 255, 255, 0.4);
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.6) 0%, rgba(255, 255, 255, 0.15) 100%);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.06);
}

.notes-panel {
  border: 1px solid rgba(255, 255, 255, 0.4);
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.6), rgba(255, 255, 255, 0.2));
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.04);
}

.notes-hero__eyebrow,
.notes-status-pill,
.notes-stat-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.6);
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.8), rgba(255, 255, 255, 0.4));
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03);
  transition: transform 0.3s ease, box-shadow 0.3s ease, background 0.3s ease;
}

.notes-stat-chip:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(37, 99, 235, 0.1);
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.9), rgba(255, 255, 255, 0.5));
}

.notes-hero__eyebrow {
  padding: 0.45rem 0.85rem;
  font-size: 0.84rem;
  font-weight: 700;
}

.notes-hero__copy,
.notes-hero__summary,
.notes-editor__subcopy,
.notes-editor__eyebrow {
  color: var(--oc-color-role-on-surface-variant, rgba(15, 23, 42, 0.7));
}

.notes-stat-chip {
  padding: 0.5rem 0.85rem;
  font-size: 0.85rem;
}

.notes-stat-chip__value {
  font-weight: 800;
}

.notes-stat-chip--dirty,
.notes-status-pill--dirty {
  background: rgba(244, 187, 68, 0.18);
  border-color: rgba(244, 187, 68, 0.4);
}

.notes-editor__header {
  border-bottom: 1px solid rgba(255, 255, 255, 0.3);
}

.notes-editor__eyebrow {
  font-size: 0.74rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.notes-status-pill {
  padding: 0.5rem 0.8rem;
  font-size: 0.82rem;
  font-weight: 700;
}
</style>
