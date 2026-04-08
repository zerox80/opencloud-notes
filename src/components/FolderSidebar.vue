<template>
  <div class="notes-sidebar ext:flex ext:h-full ext:flex-col ext:overflow-hidden">
    <div class="notes-sidebar__header ext:p-4 md:ext:p-5">
      <div class="ext:flex ext:items-start ext:justify-between ext:gap-3">
        <div class="ext:min-w-0">
          <p class="notes-sidebar__eyebrow ext:mb-2">{{ $gettext('Navigator') }}</p>
          <h2 
            class="ext:my-0 ext:truncate ext:text-2xl ext:cursor-pointer"
            @click="folderStore.setActiveFolder(null)"
          >
            {{ notebookTitle }}
          </h2>
          <p class="notes-sidebar__copy ext:mt-2 ext:mb-0">
            {{ $gettext('%{count} folders', { count: folderCount }) }}
          </p>
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
      <TocEmpty v-if="!folderNodes?.length" />
      <template v-else>
        <TocList class="ext:text-sm" :nodes="folderNodes" />
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
import {
  useActionsCreateFolder,
  useDragAndDrop,
  useFolderStore,
  useNotebookStore,
  useTocStore
} from '../composables'
import { getResourceLabel, countFolders, filterFoldersTree } from '../util'

const { $gettext } = useGettext()

const notebookStore = useNotebookStore()
const { notebook } = storeToRefs(notebookStore)

const tocStore = useTocStore()
const { tocNodes, isDragAndDropActive, dragOverRoot } = storeToRefs(tocStore)

const folderStore = useFolderStore()

const { onDragOverRoot, onDragLeaveRoot, onDropOnRoot } = useDragAndDrop()

const { actions } = useActionsCreateFolder(null)
const rootActions = computed(() => {
  if (!notebook.value) return []
  return actions.filter((a) => a.isVisible({ space: notebookStore.space, resources: [notebook.value!] }))
})

const notebookTitle = computed(() => {
  return notebook.value ? getResourceLabel(notebook.value) : $gettext('Notes')
})

const folderCount = computed(() => countFolders(tocNodes.value || []))

// Only pass down the folders to the tree view
const folderNodes = computed(() => filterFoldersTree(tocNodes.value || []))
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
  color: var(--oc-color-role-on-surface-variant, rgb(from var(--oc-color-role-on-surface, #0f172a) r g b / 70%));
}

.notes-sidebar__copy {
  font-size: 0.85rem;
  color: var(--oc-color-role-on-surface-variant, rgb(from var(--oc-color-role-on-surface, #0f172a) r g b / 70%));
}

.notes-root-dropzone {
  margin-top: 1rem;
  padding: 1.5rem 1rem;
  border-radius: 1rem;
  border: 2px dashed var(--oc-color-role-outline, #cbd5e1);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--oc-color-role-on-surface-variant, rgb(from var(--oc-color-role-on-surface, #0f172a) r g b / 70%));
  transition: all 120ms ease;
}

.notes-root-dropzone--active {
  border-color: var(--oc-color-role-primary, #2563eb);
  background: rgb(from var(--oc-color-role-primary, #2563eb) r g b / 5%);
}
</style>