import type { AudienceCriteria } from "../types"
import { toSentence } from "../helper"

type CriteriaDescriptionProps = {
  criteria?: AudienceCriteria
}
export const CriteriaDescription = ({ criteria }: CriteriaDescriptionProps) => {
  const { Title, Department, Territory } = criteria?.groups || {}

  return (
    <div>
      {"All "}
      {Title && <strong>{toSentence(Title)}</strong>}

      {Department && (
        <>
          {" in "}
          <strong>{toSentence(Department)}</strong>
        </>
      )}

      {Territory && (
        <>
          {" from "}
          <strong>{toSentence(Territory)}</strong>
        </>
      )}
      {"."}
    </div>
  )
}
