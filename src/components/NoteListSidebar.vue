<template>
  <div class="notes-sidebar ext:flex ext:h-full ext:flex-col ext:overflow-hidden">
    <div class="notes-sidebar__header ext:p-4 md:ext:p-5">
      <div class="ext:flex ext:items-start ext:justify-between ext:gap-3">
        <div class="ext:min-w-0">
          <p class="notes-sidebar__eyebrow ext:mb-2">{{ activeFolderTitle }}</p>
          <h2 class="ext:my-0 ext:truncate ext:text-2xl">{{ filterTerm ? $gettext('Search Results') : $gettext('Pages') }}</h2>
          <p class="notes-sidebar__copy ext:mt-2 ext:mb-0">
            {{ $gettext('%{count} pages', { count: displayedNotes.length }) }}
          </p>
        </div>
      </div>

      <div class="ext:mt-4 ext:flex ext:flex-wrap ext:gap-2" v-if="!filterTerm">
        <ActionIconButton
          v-for="action in folderActions"
          :key="`action-button-${action.name}`"
          :resource="folderStore.activeFolder || notebook"
          :action="action"
        />
      </div>
    </div>

    <div class="ext:min-h-0 ext:flex-1 ext:overflow-auto ext:p-4 md:ext:p-5">
      <div v-if="displayedNotes.length" class="ext:flex ext:flex-col ext:gap-2">
        <button
          v-for="node in displayedNotes"
          :key="`note-list-result-${node.resource.id}`"
          type="button"
          class="notes-search-result"
          :class="{ 'notes-search-result--active': node.resource.id === documentId }"
          :draggable="!filterTerm"
          @dragstart="onDragStart(node, $event)"
          @dragend="onDragEnd"
          @click="openSearchResult(node)"
        >
          <span class="notes-search-result__icon">
            <oc-icon name="article" fill-type="line" size="small" />
          </span>
          <span class="notes-search-result__copy ext:text-left">
            <span class="notes-search-result__title">{{ getResourceLabel(node.resource) }}</span>
            <span class="notes-search-result__meta" v-if="filterTerm">
              {{ getNotebookPathLabel(notebook, node.resource) }}
            </span>
          </span>
        </button>
      </div>

      <div v-else class="notes-search-empty ext:text-center ext:mt-8">
        <oc-icon :name="filterTerm ? 'search' : 'file-text'" fill-type="line" size="large" />
        <h3 class="ext:mb-2 ext:mt-3">
          {{ filterTerm ? $gettext('No matching pages') : $gettext('This section is empty') }}
        </h3>
        <p class="ext:my-0 ext:text-sm ext:text-gray-600">
          {{ filterTerm ? $gettext('Try a different title.') : $gettext('Create a new page here to get started.') }}
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import ActionIconButton from './ActionIconButton.vue'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useGettext } from 'vue3-gettext'
import { TocNode } from '../types'
import {
  buildDocumentRoute,
  useActionsCreateNote,
  useDocumentStore,
  useDragAndDrop,
  useFolderStore,
  useNotebookStore,
  useTocStore
} from '../composables'
import { getResourceLabel, getNotebookPathLabel, getNotesInFolder, searchNoteNodes } from '../util'
import { useRouter } from '@opencloud-eu/web-pkg'

const props = defineProps<{
  filterTerm: string
}>()

const { $gettext } = useGettext()
const router = useRouter()

const notebookStore = useNotebookStore()
const { notebook } = storeToRefs(notebookStore)

const tocStore = useTocStore()
const { tocNodes } = storeToRefs(tocStore)

const documentStore = useDocumentStore()
const { documentId } = storeToRefs(documentStore)

const folderStore = useFolderStore()
const { onDragStart, onDragEnd } = useDragAndDrop()

const { actions: actionsCreateNote } = useActionsCreateNote(folderStore.activeFolder || notebook.value)
const folderActions = computed(() => {
  const target = folderStore.activeFolder || notebook.value
  if (!target) return []
  return actionsCreateNote.filter((a) => a.isVisible({ space: notebookStore.space, resources: [target] }))
})

const activeFolderTitle = computed(() => {
  if (props.filterTerm) return $gettext('Searching')
  if (!folderStore.activeFolder) return $gettext('Root section')
  return folderStore.activeFolder.name
})

const displayedNotes = computed(() => {
  if (props.filterTerm.trim()) {
    return searchNoteNodes(tocNodes.value || [], props.filterTerm)
  }
  return getNotesInFolder(tocNodes.value || [], folderStore.activeFolder?.id || null)
})

const openSearchResult = (node: TocNode) => {
  if (!notebook.value) return
  if (node.resource.id === documentId.value) return

  const route = buildDocumentRoute(node.resource)
  router.push(route)
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

.notes-sidebar__copy {
  font-size: 0.85rem;
  color: var(--oc-color-role-on-surface-variant, rgba(15, 23, 42, 0.7));
}

.notes-search-result {
  display: grid;
  grid-template-columns: auto 1fr;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.7rem 0.85rem;
  background: transparent;
  border-radius: 1.1rem;
  border: 1px solid transparent;
  cursor: pointer;
  transition: all 120ms ease;
}

.notes-search-result:hover,
.notes-search-result--active {
  border-color: var(--oc-color-role-outline-variant, #d7dde5);
  background: rgba(255, 255, 255, 0.82);
}

.notes-search-result--active {
  box-shadow: inset 0 0 0 1.5px var(--oc-color-role-primary, #2563eb);
  border-color: var(--oc-color-role-primary, #2563eb);
}

.notes-search-result__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 2.25rem;
  height: 2.25rem;
  border-radius: 0.7rem;
  background: rgba(37, 99, 235, 0.05);
  color: var(--oc-color-role-primary, #2563eb);
}

.notes-search-result__copy {
  display: flex;
  min-width: 0;
  flex-direction: column;
  line-height: 1.35;
}

.notes-search-result__title,
.notes-search-result__meta {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.notes-search-result__title {
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--oc-color-role-on-background, #0f172a);
}

.notes-search-result__meta {
  font-size: 0.8rem;
  color: var(--oc-color-role-on-surface-variant, rgba(15, 23, 42, 0.7));
}

.notes-search-empty {
  color: var(--oc-color-role-on-surface-variant, rgba(15, 23, 42, 0.7));
}
</style>