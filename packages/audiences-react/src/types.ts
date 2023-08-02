export type Option = {
  id: string
  name: string
}

export type Filter = {
  id: string
  size: number // the number of people that matches this filter audience
  userCount: number
  departments?: Option[]
  titles?: Option[]
  territories?: Option[]
}

export type Member = {
  id: string
  name: string
}

// SCIM Version

export const TerritoryGroupType = "Territory"
export const TitleGroupType = "Title"
export const DepartmentGroupType = "Department"

export interface Grouped {
  groups: ScimGroup[]
}

export interface BaseScim {
  id: string
  name: string
  photoUrl?: string
}

export type ScimUser = {
  id: string
  name: string
  photoUrl: string
  username: string
  groups: ScimGroup[]
}

export type ScimGroup = {
  id: string
  name: string
  groupType: string
}

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
