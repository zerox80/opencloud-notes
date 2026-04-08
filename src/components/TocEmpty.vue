<template>
  <div class="notes-empty-state">
    <span class="notes-empty-state__icon">
      <oc-icon name="sticky-note" fill-type="line" size="xlarge" />
    </span>

    <div class="ext:max-w-[18rem]">
      <h3 class="ext:my-0">{{ $gettext('This notebook is still empty') }}</h3>
      <p class="ext:mt-2 ext:mb-0 notes-empty-state__copy">
        <span v-if="hasWriteAccess">{{ $gettext('Create your first note or folder with the actions above.') }}</span>
        <span v-else>{{ $gettext('There are no notes in this notebook, yet.') }}</span>
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useGettext } from 'vue3-gettext'
import { useNotebookStore } from '../composables'
import { storeToRefs } from 'pinia'

const { $gettext } = useGettext()
const notebookStore = useNotebookStore()
const { hasWriteAccess } = storeToRefs(notebookStore)
</script>

<style scoped>
.notes-empty-state {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  border-radius: 1.4rem;
  border: 1px dashed var(--oc-color-role-outline-variant, #d7dde5);
  background: var(--oc-color-role-surface-container);
}

.notes-empty-state__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 3.75rem;
  height: 3.75rem;
  border-radius: 1.1rem;
  background: color-mix(in srgb, var(--oc-color-icon-notes, #f4bb44) 16%, transparent);
  color: var(--oc-color-icon-notes);
}

.notes-empty-state__copy {
  color: var(--oc-color-role-on-surface-variant, color-mix(in srgb, var(--oc-color-role-on-surface, #0f172a) 70%, transparent));
}
</style>
