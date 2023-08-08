// SCIM Version

export const UserSchema = "urn:ietf:params:scim:schemas:core:2.0:User"
export const GroupSchema = "urn:ietf:params:scim:schemas:core:2.0:Group"

export type SchemaType = typeof UserSchema | typeof GroupSchema | never

export const TerritoryGroupType = "Territory"
export const TitleGroupType = "Title"
export const DepartmentGroupType = "Department"

export type ScimListResponse<T> = {
  totalEntries: number
  Resources: T[]
}

export type ScimResourceType = {
  id: string
  name: string
  endpoint: string
  schema: string
  meta: {
    resourceType: string
  }
}

export interface BaseScim {
  schemas: SchemaType[]
  id: string
  displayName: string
  photoUrl?: string
  meta: {
    resourceType: string
  }
}

export type ScimUser = BaseScim & {
  username: string
}

export type ScimGroup = BaseScim

export type AudienceCriteria = {
  count?: number
  groups?: { [key: string]: ScimGroup[] }
}

export type AudienceContext = {
  key: string
  match_all: boolean
  criteria: AudienceCriteria[]
  extraMembers: ScimUser[]
  totalMembers: number
}
