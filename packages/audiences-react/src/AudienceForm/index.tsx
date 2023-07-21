import { FormProvider, useForm } from "react-hook-form";
import { Button, Card, Icon, Toggle, Caption, User, Flex } from "playbook-ui";

import {
  AudienceContext,
  ScimUser,
  TerritoryGroupType,
  TitleGroupType,
} from "../types";
import { groupName } from "../helper";

import Header from "./Header";
import ScimObjectTypeaheadField, {
  SearchOptions,
} from "./ScimObjectTypeaheadField";
import CriteriaListFields, { CriteriaListProps } from "./CriteriaListFields";

type AudienceFormProps = {
  allowIndividuals: boolean;
  context: AudienceContext;
  groupOptions: CriteriaListProps["groupOptions"];
  groupTypes: CriteriaListProps["groupTypes"];
  loading?: boolean;
  onSave: (updatedContext: AudienceContext) => void;
  saving?: boolean;
  userOptions: SearchOptions<ScimUser>;
};

const AudienceForm = ({
  allowIndividuals = true,
  context,
  groupOptions,
  groupTypes,
  loading,
  onSave,
  saving,
  userOptions,
}: AudienceFormProps) => {
  const form = useForm({ values: context });

  const all = form.watch("all");

  if (loading) return <Icon icon="user" />;

  return (
    <FormProvider {...form}>
      <Card margin="xs" padding="xs">
        <Card.Header headerColor="white">
          <Header context={context} touched={form.formState.isDirty}>
            <Flex align="center">
              <Toggle>
                <input {...form.register("all")} type="checkbox" />
              </Toggle>
              <Caption marginLeft="xs" size="xs" text="All Employees" />
            </Flex>
          </Header>
        </Card.Header>

        {all || (
          <Card.Body>
            <CriteriaListFields
              name="criteria"
              groupOptions={groupOptions}
              groupTypes={groupTypes}
            />

            {allowIndividuals && (
              <ScimObjectTypeaheadField
                label="Other Members"
                name="extraMembers"
                options={userOptions}
                valueComponent={(user: ScimUser) => (
                  <User
                    avatar
                    avatarUrl={user.photoUrl}
                    name={user.name}
                    territory={groupName(user, TerritoryGroupType)}
                    title={groupName(user, TitleGroupType)}
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
  );
};
export default AudienceForm;
