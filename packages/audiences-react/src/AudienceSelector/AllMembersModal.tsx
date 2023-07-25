import { useState } from "react"
import get from "lodash/get"
import MembersModalContent from "./MembersModalContent"

type AllMembersModalProps = {
  allAudienceMembers: boolean
  show: boolean
  onHide: () => void
  ownerId: string
  ownerType: string
}

const AllMembersModal = ({
  allAudienceMembers,
  show,
  onHide,
  ownerId,
  ownerType,
}: AllMembersModalProps) => {
  const [memberName, setMemberName] = useState("")

  const data = {
    members: {
      nodes: [],
      totalEntries: 0,
    },
  }
  const loading = !show
  const fetchMore = () => undefined

  const membersList = get(data, "members.nodes", [])
  const total = get(data, "members.totalEntries", 0)

  if (!show) return null

  return (
    <MembersModalContent
      allAudienceMembers={allAudienceMembers}
      fetchMore={fetchMore}
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

export default AllMembersModal
