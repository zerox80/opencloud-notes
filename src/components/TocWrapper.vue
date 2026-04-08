<template>
  <div class="notes-sidebar ext:flex ext:h-full ext:flex-col ext:overflow-hidden">
    <div class="notes-sidebar__header ext:p-4 md:ext:p-5">
      <div class="ext:flex ext:items-start ext:justify-between ext:gap-3">
        <div class="ext:min-w-0">
          <p class="notes-sidebar__eyebrow ext:mb-2">{{ $gettext('Navigator') }}</p>
          <h2 class="ext:my-0 ext:truncate ext:text-2xl">{{ notebookTitle }}</h2>
          <p class="notes-sidebar__copy ext:mt-2 ext:mb-0">
            {{ sidebarSummary }}
          </p>
        </div>

        <div class="notes-sidebar__count">
          <span class="notes-sidebar__count-value">{{ noteCount }}</span>
          <span>{{ $gettext('pages') }}</span>
        </div>
      </div>

      <div class="ext:mt-4 ext:flex ext:flex-wrap ext:gap-2">
        <ActionIconButton
          v-for="action in rootActions"
          :key="`root-action-button-${action.name}`"
          :resource="notebook"
          :action="action"
        />
      </div>
    </div>

    <div class="ext:min-h-0 ext:flex-1 ext:overflow-auto ext:p-4 md:ext:p-5">
      <template v-if="hasSearchResultsView">
        <div v-if="filteredNotes.length" class="ext:flex ext:flex-col ext:gap-2">
          <button
            v-for="node in filteredNotes"
            :key="`note-search-result-${node.resource.id}`"
            type="button"
            class="notes-search-result"
            :class="{ 'notes-search-result--active': node.resource.id === documentId }"
            @click="openSearchResult(node)"
          >
            <span class="notes-search-result__icon">
              <oc-icon name="article" fill-type="line" size="small" />
            </span>
            <span class="notes-search-result__copy">
              <span class="notes-search-result__title">{{ getResourceLabel(node.resource) }}</span>
              <span class="notes-search-result__meta">
                {{ getNotebookPathLabel(notebook, node.resource) }}
              </span>
            </span>
          </button>
        </div>

        <div v-else class="notes-search-empty">
          <oc-icon name="search" fill-type="line" size="large" />
          <h3 class="ext:mb-2 ext:mt-3">{{ $gettext('No matching pages') }}</h3>
          <p class="ext:my-0">
            {{ $gettext('Try a different title or clear the search field to return to the full notebook tree.') }}
          </p>
        </div>
      </template>

      <template v-else>
        <TocEmpty v-if="!tocNodes?.length" />
        <template v-else>
          <TocList class="ext:text-sm" :nodes="tocNodes" />
          <div
            v-if="isDragAndDropActive"
            class="notes-root-dropzone"
            :class="{ 'bg-role-secondary-container': dragOverRoot, 'notes-root-dropzone--active': dragOverRoot }"
            :aria-label="$gettext('Root drop zone')"
            @dragover.prevent="onDragOverRoot()"
            @dragleave="onDragLeaveRoot"
            @drop.prevent="onDropOnRoot()"
          >
            <span class="ext:text-sm ext:text-center">
              {{ $gettext('Drop here to move item to root of notebook') }}
            </span>
          </div>
        </template>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import ActionIconButton from './ActionIconButton.vue'
import TocEmpty from './TocEmpty.vue'
import TocList from './TocList.vue'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useGettext } from 'vue3-gettext'
import { TocNode } from '../types'
import {
  buildDocumentRoute,
  useActionsCreateFolder,
  useActionsCreateNote,
  useDocumentStore,
  useDragAndDrop,
  useNotebookStore,
  useTocStore
} from '../composables'
import {
  countFolders,
  countNotes,
  getNotebookPathLabel,
  getResourceLabel,
  searchNoteNodes
} from '../util'
import { useRouter } from '@opencloud-eu/web-pkg'

const { $gettext } = useGettext()
const props = withDefaults(
  defineProps<{
    filterTerm?: string
  }>(),
  {
    filterTerm: ''
  }
)

const router = useRouter()

const notebookStore = useNotebookStore()
const { notebook } = storeToRefs(notebookStore)

const tocStore = useTocStore()
const { tocNodes, isDragAndDropActive, dragOverRoot } = storeToRefs(tocStore)
const documentStore = useDocumentStore()
const { documentId } = storeToRefs(documentStore)

const { onDragOverRoot, onDragLeaveRoot, onDropOnRoot } = useDragAndDrop()

const { actions: actionsCreateFolder } = useActionsCreateFolder(null)
const { actions: actionsCreateNote } = useActionsCreateNote(null)
const notebookTitle = computed(() => {
  return notebook.value ? getResourceLabel(notebook.value) : $gettext('Notes')
})
const noteCount = computed(() => countNotes(tocNodes.value || []))
const folderCount = computed(() => countFolders(tocNodes.value || []))
const filteredNotes = computed(() => searchNoteNodes(tocNodes.value || [], props.filterTerm))
const hasSearchResultsView = computed(() => props.filterTerm.trim().length > 0)
const sidebarSummary = computed(() => {
  if (hasSearchResultsView.value) {
    return $gettext('%{count} pages match your current filter', { count: filteredNotes.value.length })
  }

  return $gettext('%{notes} pages arranged in %{folders} sections', {
    notes: noteCount.value,
    folders: folderCount.value
  })
})

const rootActions = computed(() => {
  return [...actionsCreateFolder, ...actionsCreateNote].filter((action) =>
    action.isVisible({ space: notebookStore.space, resources: [notebookStore.notebook] })
  )
})

const openSearchResult = async (node: TocNode) => {
  await router.push(buildDocumentRoute(notebookStore.space, notebookStore.notebook, node))
}
</script>

<style scoped>
.notes-sidebar__header {
  border-bottom: 1px solid var(--oc-color-role-outline-variant, #d7dde5);
}

.notes-sidebar__eyebrow {
  font-size: 0.74rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--oc-color-role-on-surface-variant, rgba(15, 23, 42, 0.7));
}

.notes-sidebar__copy,
.notes-search-result__meta,
.notes-search-empty {
  color: var(--oc-color-role-on-surface-variant, rgba(15, 23, 42, 0.7));
}

.notes-sidebar__count {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-width: 4.25rem;
  padding: 0.75rem;
  border-radius: 1.15rem;
  border: 1px solid var(--oc-color-role-outline-variant, #d7dde5);
  background: var(--oc-color-role-surface-container, rgba(128, 128, 128, 0.1));
  font-size: 0.78rem;
  font-weight: 600;
}

.notes-sidebar__count-value {
  font-size: 1.35rem;
  font-weight: 800;
  line-height: 1;
}

.notes-search-result {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.85rem;
  align-items: center;
  width: 100%;
  padding: 0.9rem 1rem;
  border-radius: 1rem;
  border: 1px solid var(--oc-color-role-outline-variant, #d7dde5);
  background: var(--oc-color-role-surface-container, rgba(128, 128, 128, 0.1));
  text-align: left;
  transition:
    border-color 120ms ease,
    transform 120ms ease,
    background-color 120ms ease;
}

.notes-search-result:hover {
  transform: translateY(-1px);
  border-color: var(--oc-color-role-primary, #2563eb);
}

.notes-search-result--active {
  background: rgba(244, 187, 68, 0.16);
  border-color: rgba(244, 187, 68, 0.55);
}

.notes-search-result__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 2.25rem;
  height: 2.25rem;
  border-radius: 0.8rem;
  background: rgba(244, 187, 68, 0.16);
  color: var(--oc-color-icon-notes);
}

.notes-search-result__copy {
  display: flex;
  min-width: 0;
  flex-direction: column;
  gap: 0.15rem;
}

.notes-search-result__title {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 700;
}

.notes-search-result__meta {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 0.82rem;
}

.notes-search-empty,
.notes-root-dropzone {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.65rem;
  min-height: 10rem;
  border-radius: 1.25rem;
  border: 1px dashed var(--oc-color-role-outline-variant, #d7dde5);
  padding: 1.5rem;
  text-align: center;
}

.notes-root-dropzone--active {
  border-style: solid;
}
</style>
