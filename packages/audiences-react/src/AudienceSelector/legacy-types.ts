type Option = {
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
