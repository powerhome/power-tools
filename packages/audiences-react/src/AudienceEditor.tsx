import { Flex, Icon } from "playbook-ui"
import { Provider } from "use-http"

import AudienceForm from "./AudienceForm"
import useAudience from "./useAudience"

type AudienceEditorProps = {
  uri: string
  scimUri: string
  allowIndividuals?: boolean
}
export default function AudienceEditor({
  uri,
  scimUri,
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
    <Provider url={scimUri}>
      <AudienceForm
        context={context}
        allowIndividuals={allowIndividuals}
        onSave={updateContext}
      />
    </Provider>
  )
}
