import { Caption, Button } from "playbook-ui"

const style = {
  memberCounter: {},
  viewAllLink: {
    fontWeight: 400,
    fontSize: "12px",
  },
}

type MembersProps = {
  count?: number
  showAll?: boolean
  onShowAllMembers: () => void
}

export default function Members({
  showAll = false,
  count,
  onShowAllMembers,
}: MembersProps) {
  return (
    <>
      <Caption tag="span" text="Audience" />

      {count == 0 ? (
        <Caption
          style={style.memberCounter}
          marginLeft="xs"
          size="xs"
          tag="span"
          text="0"
        />
      ) : (
        <>
          <Caption
            style={style.memberCounter}
            marginLeft="xs"
            tag="span"
            text={count}
          />
          {showAll && (
            <div>
              <Button
                style={style.viewAllLink}
                onClick={onShowAllMembers}
                padding="none"
                text="View All Members"
                variant="link"
              />
            </div>
          )}
        </>
      )}
    </>
  )
}
