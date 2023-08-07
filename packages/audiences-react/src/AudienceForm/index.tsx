import { FormProvider, useForm } from "react-hook-form"
import { Button, Card, Toggle, Caption, User, Flex } from "playbook-ui"

import { AudienceContext, ScimUser, UserSchema } from "../types"

import Header from "./Header"
import ScimResourceTypeahead from "./ScimResourceTypeahead"
import CriteriaListFields from "./CriteriaListFields"
import { useScimResources } from "../useScimResources"

type AudienceFormProps = {
  allowIndividuals: boolean
  context: AudienceContext
  loading?: boolean
  onSave: (updatedContext: AudienceContext) => void
  saving?: boolean
}

const AudienceForm = ({
  allowIndividuals = true,
  context,
  onSave,
  saving,
}: AudienceFormProps) => {
  const form = useForm({ values: context })
  const [userResource] = useScimResources(UserSchema)

  const all = form.watch("match_all")

  return (
    <FormProvider {...form}>
      <Card margin="xs" padding="xs">
        <Card.Header headerColor="white">
          <Header context={context}>
            <Flex align="center">
              <Toggle>
                <input {...form.register("match_all")} type="checkbox" />
              </Toggle>
              <Caption marginLeft="xs" size="xs" text="All Employees" />
            </Flex>
          </Header>
        </Card.Header>

        {all || (
          <Card.Body>
            <CriteriaListFields name="criteria" />

            {allowIndividuals && userResource && (
              <ScimResourceTypeahead
                label="Other Members"
                name="extraMembers"
                resource={userResource}
                valueComponent={(user: ScimUser) => (
                  <User
                    avatar
                    avatarUrl={user.photoUrl}
                    name={user.displayName}
                  />
                )}
              />
            )}
          </Card.Body>
        )}

        <Card.Body>
          <div className="mt-5 pt-5">
            <Button
              disabled={saving}
              onClick={form.handleSubmit(onSave)}
              loading={saving}
              text="Save"
            />
            {form.formState.isDirty && (
              <Button
                marginLeft="sm"
                onClick={() => form.reset()}
                text="Cancel"
                variant="link"
              />
            )}
          </div>
        </Card.Body>
      </Card>
    </FormProvider>
  )
}
export default AudienceForm
