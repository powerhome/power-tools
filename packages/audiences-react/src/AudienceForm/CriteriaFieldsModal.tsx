import isEmpty from "lodash/isEmpty"
import map from "lodash/map"
import { Button, Dialog } from "playbook-ui"
import { useFormContext } from "react-hook-form"

import { ScimGroup } from "../types"

import { CriteriaDescription } from "./CriteriaDescription"
import ScimObjectTypeaheadField, {
  SearchOptions,
} from "./ScimObjectTypeaheadField"

export type CriteriaFieldsModalProps = {
  current: string
  onSave: () => void
  onCancel: () => void
  groupTypes: string[] | (() => string[])
  groupOptions: {
    [groupType: string]: SearchOptions<ScimGroup>
  }
}
export default function CriteriaFieldsModal({
  current,
  groupOptions,
  groupTypes,
  onSave,
  onCancel,
}: CriteriaFieldsModalProps) {
  const { watch } = useFormContext()
  const value = watch(current)

  return (
    <Dialog onClose={onCancel} opened>
      <Dialog.Header>
        <CriteriaDescription criteria={value} />
      </Dialog.Header>
      <Dialog.Body>
        {map(groupTypes, (type) => (
          <ScimObjectTypeaheadField
            key={`${current}.groups.${type}`}
            label={type}
            name={`${current}.groups.${type}` as const}
            options={groupOptions[type]}
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
