import { Flex, Icon } from "playbook-ui"
import AudienceForm from "./AudienceForm"
import {
  DepartmentGroupType,
  TerritoryGroupType,
  TitleGroupType,
} from "./types"
import useAudience from "./useAudience"

type AudienceEditorProps = {
  uri: string
  allowIndividuals?: boolean
}
export function AudienceEditor({
  uri,
  allowIndividuals = true,
}: AudienceEditorProps) {
  const [context, updateContext] = useAudience(uri)

  if (!context) {
    return (
      <Flex justify="center">
        <Icon fontStyle="fas" icon="spinner" spin />
      </Flex>
    )
  }

  return (
    <AudienceForm
      context={context}
      allowIndividuals={allowIndividuals}
      onSave={updateContext}
      userOptions={[
        {
          id: "1",
          name: "Wade Winningham",
          groups: [],
          username: "wwinningham",
          photoUrl: "https://nitro.powerhrg.com/api/v1/users/1/avatar/badge",
        },
        {
          id: "2",
          name: "Tim Wenhold",
          groups: [],
          username: "twenhold",
          photoUrl: "https://nitro.powerhrg.com/api/v1/users/2/avatar/badge",
        },
      ]}
      groupTypes={[TitleGroupType, DepartmentGroupType, TerritoryGroupType]}
      groupOptions={{
        Territory: [
          {
            groupType: "Territory",
            name: "Philadelphia",
            id: "1",
          },
        ],
        Department: [
          {
            groupType: "Department",
            name: "Business Technology",
            id: "123",
          },
        ],
        Title: [
          {
            groupType: "Title",
            name: "Director",
            id: "123",
          },
          {
            groupType: "Title",
            name: "Developer",
            id: "321",
          },
        ],
      }}
    />
  )
}
