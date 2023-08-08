import React from "react"
import get from "lodash/get"
import {
  Body,
  User,
  Caption,
  Card,
  Button,
  TextInput,
  Dialog,
} from "playbook-ui"

import type { Filter, Member } from "./legacy-types"
import { CriteriaDescription } from "../AudienceForm/CriteriaDescription"

const style = {
  listContentModal: {
    overflow: "scroll",
    height: "300px",
    padding: "10px 25px",
  },
  listHeaderModal: {
    padding: "7px 14px 0",
  },
  listLoadMoreModal: {},
}

type MembersModalContentProps = {
  allAudienceMembers: boolean
  fetchMore: () => void
  filter?: Filter
  loading: boolean
  membersList: Member[]
  memberName: string
  show: boolean
  onHide: () => void
  setMemberName: React.Dispatch<React.SetStateAction<string>>
  total: number
}

const MembersModalContent = ({
  allAudienceMembers,
  fetchMore,
  filter,
  loading,
  membersList,
  memberName,
  show,
  onHide,
  setMemberName,
  total,
}: MembersModalContentProps) => {
  const handleMemberNameSearch = ({
    target,
  }: React.ChangeEvent<HTMLInputElement>) => {
    setMemberName(target.value)
  }

  return (
    <Dialog
      onCancel={onHide}
      onClose={onHide}
      opened={show}
      title={`View members ${total}`}
    >
      {!allAudienceMembers && (
        <Body marginBottom="sm">
          <CriteriaDescription criteria={{}} />
        </Body>
      )}
      <Card padding="none">
        <div style={style.listHeaderModal}>
          <TextInput
            onChange={handleMemberNameSearch}
            placeholder="Filter for members"
            value={memberName}
          />
        </div>
        <div style={style.listContentModal}>
          {membersList.length == 0
            ? "No members"
            : membersList.map((member, index) => (
                <User
                  avatar
                  avatarUrl={get(member, "photo.url")}
                  key={index}
                  marginBottom="xs"
                  name={member.name}
                  territory={get(member, "territory.abbr")}
                  title={get(member, "title.name")}
                />
              ))}
        </div>
        <div style={style.listLoadMoreModal}>
          {fetchMore && !loading && (
            <div className="text-center">
              <Button
                key={`load-more-${loading}`}
                onClick={fetchMore}
                text="Load More"
                variant="link"
              />
            </div>
          )}
        </div>
      </Card>
      <Caption
        className="text-center mt-4"
        size="xs"
        text={`Showing ${membersList.length} of ${total}`}
      />
    </Dialog>
  )
}

export default MembersModalContent
