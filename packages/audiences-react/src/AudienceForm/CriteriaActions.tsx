import { Button, Icon, PbReactPopover, List, ListItem } from "playbook-ui"

import { useToggler } from "../hooks"

type CriteriaActionsProps = {
  onRequestRemove: () => void
  onRequestEdit: () => void
  onRequestViewMembers: () => void
}
export default function CriteriaActions({
  onRequestRemove,
  onRequestEdit,
  onRequestViewMembers,
}: CriteriaActionsProps) {
  const [showMenu, toggleShowMenu, setShowMenu] = useToggler(false)

  const actionPopoverTrigger = (
    <div className="pb_circle_icon_button_kit">
      <Button className="" onClick={toggleShowMenu} variant="link">
        <Icon fixedWidth fontStyle="fas" icon="ellipsis-vertical" />
      </Button>
    </div>
  )

  const handleAndClose = (handler: () => void) => {
    return () => {
      handler()
      setShowMenu(false)
    }
  }

  return (
    <PbReactPopover
      closeOnClick="outside"
      padding="xs"
      placement="bottom"
      reference={actionPopoverTrigger}
      shouldClosePopover={(close: boolean) => setShowMenu(!close)}
      show={showMenu}
    >
      <List>
        <ListItem padding="none">
          <Button
            variant="link"
            size="xs"
            padding="xs"
            onClick={handleAndClose(onRequestEdit)}
            text="Edit"
          />
        </ListItem>
        <ListItem padding="none">
          <Button
            variant="link"
            size="xs"
            padding="xs"
            onClick={handleAndClose(onRequestViewMembers)}
            text="Members"
          />
        </ListItem>
        <ListItem padding="none">
          <Button
            variant="link"
            size="xs"
            padding="xs"
            onClick={handleAndClose(onRequestRemove)}
            text="Delete"
          />
        </ListItem>
      </List>
    </PbReactPopover>
  )
}
