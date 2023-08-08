import { useState } from "react"
import get from "lodash/get"
import MembersModalContent from "./MembersModalContent"

import type { Filter } from "./legacy-types"

type MembersModalProps = {
  allAudienceMembers: boolean
  filter: Filter
  show: boolean
  onHide: () => void
}

const MembersModal = ({
  allAudienceMembers,
  filter,
  show,
  onHide,
}: MembersModalProps) => {
  // const sanitizeFilter = (input: FilterInput) => ({
  //   titleIds: input.titles?.map((title) => parseInt(title.id)),
  //   departmentIds: input.departments?.map((department) => parseInt(department.id)),
  //   territoryIds: input.territories?.map((territory) => parseInt(territory.id)),
  // })
  const [memberName, setMemberName] = useState("")
  // sanitizeFilter(filter), ownerType, search: {full_name: memberName}
  const fetchMore = () => undefined
  const loading = false
  const data = {
    members: {
      nodes: [],
      totalEntries: 0,
    },
  }

  const membersList = get(data, "members.nodes", [])
  const total = get(data, "members.totalEntries", 0)

  if (!show) return null

  return (
    <MembersModalContent
      allAudienceMembers={allAudienceMembers}
      fetchMore={fetchMore}
      filter={filter}
      loading={loading}
      memberName={memberName}
      membersList={membersList}
      onHide={onHide}
      setMemberName={setMemberName}
      show={show}
      total={total}
    />
  )
}

export default MembersModal
