import { useState } from "react"
import { Button, Flex, FlexItem } from "playbook-ui"
import { useFieldArray, useFormContext } from "react-hook-form"

import { AudienceCriteria } from "../types"

import CriteriaActions from "./CriteriaActions"
import CriteriaCard from "./CriteriaCard"
import CriteriaFieldsModal from "./CriteriaFieldsModal"

type AudienceCriteriaField = AudienceCriteria & { id: string }
export type CriteriaListProps = {
  name: string
}
export default function CriteriaListFields({ name }: CriteriaListProps) {
  const form = useFormContext()
  const { fields, remove, append } = useFieldArray({ name })
  const [editCriteriaField, setEditCriteriaField] =
    useState<Parameters<typeof form.resetField>[0]>()

  const watchFieldArray = form.watch(name)
  const controlledFields = fields.map((field, index) => {
    return {
      ...field,
      ...watchFieldArray[index],
    }
  })

  const closeEditor = () => setEditCriteriaField(undefined)
  const editCriteria = (index: number) =>
    setEditCriteriaField(`${name}.${index}`)

  const handleCreateCriteria = () => {
    append({})
    editCriteria(fields.length)
  }
  const handleRemoveCriteria = (index: number) => {
    if (confirm("Remove criteria?")) {
      remove(index)
    }
  }
  const handleCancelEditCriteria = () => {
    form.resetField(editCriteriaField!)
    closeEditor()
  }

  return (
    <Flex orientation="column" justify="center" align="stretch">
      <FlexItem>
        {(controlledFields as AudienceCriteriaField[]).map(
          (criteria, index: number) => (
            <CriteriaCard criteria={criteria} key={criteria.id}>
              <CriteriaActions
                onRequestRemove={() => handleRemoveCriteria(index)}
                onRequestEdit={() => editCriteria(index)}
                onRequestViewMembers={() => {}}
              />
            </CriteriaCard>
          ),
        )}
      </FlexItem>

      <FlexItem grow alignSelf="center">
        <Button
          fixedWidth
          onClick={handleCreateCriteria}
          text="Add Audience Criteria"
          variant="link"
        />
      </FlexItem>

      {editCriteriaField !== undefined && (
        <CriteriaFieldsModal
          current={editCriteriaField}
          onCancel={handleCancelEditCriteria}
          onSave={closeEditor}
        />
      )}
    </Flex>
  )
}
