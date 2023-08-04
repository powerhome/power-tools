import isEmpty from "lodash/isEmpty"
import map from "lodash/map"
import { Button, Dialog } from "playbook-ui"
import { useFormContext } from "react-hook-form"

import { CriteriaDescription } from "./CriteriaDescription"
import ScimResourceTypeahead from "./ScimResourceTypeahead"
import { GroupSchema, ScimResourceType } from "../types"
import { useScimResources } from "../useScimResources"

export type CriteriaFieldsModalProps = {
  current: string
  onSave: () => void
  onCancel: () => void
}
export default function CriteriaFieldsModal({
  current,
  onSave,
  onCancel,
}: CriteriaFieldsModalProps) {
  const resourceTypes = useScimResources(GroupSchema)
  const { watch } = useFormContext()
  const value = watch(current)

  return (
    <Dialog onClose={onCancel} opened>
      <Dialog.Header>
        <CriteriaDescription criteria={value} />
      </Dialog.Header>
      <Dialog.Body>
        {map(resourceTypes, (resource) => (
          <ScimResourceTypeahead
            resource={resource}
            key={`${current}.groups.${resource.id}`}
            label={resource.name}
            name={`${current}.groups.${resource.id}` as const}
          />
        ))}
      </Dialog.Body>
      <Dialog.Footer>
        <Button
          onClick={onSave}
          text="Save"
          disabled={isEmpty(value?.groups)}
        />
        <Button onClick={onCancel} text="Cancel" variant="link" />
      </Dialog.Footer>
    </Dialog>
  )
}
