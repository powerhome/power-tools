import { Flex, FlexItem, Caption } from "playbook-ui"

import type { AudienceContext } from "../types"

import Members from "../AudienceSelector/Members"

type HeaderProps = React.PropsWithChildren & {
  context: AudienceContext
  touched: boolean | undefined
}
export default function Header({ context, children, touched }: HeaderProps) {
  return (
    <Flex orientation="row" spacing="between" wrap>
      <FlexItem>
        {touched ? (
          <>
            <Caption tag="span" text="Audience Total" />
            <Caption
              size="xs"
              text="Audience total will update when the page is saved"
            />
          </>
        ) : (
          <Members
            count={context.totalMembers}
            showAll
            onShowAllMembers={() => undefined}
          />
        )}
      </FlexItem>
      <FlexItem>
        <Flex justify="right" orientation="row">
          {children}
        </Flex>
      </FlexItem>
    </Flex>
  )
}
