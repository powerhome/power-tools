import join from "lodash/join"
import map from "lodash/map"

import type { ScimGroup } from "./types"

export function toSentence(groups: ScimGroup[]) {
  const names = map(groups, "displayName")

  if (names.length == 1) {
    return names
  }
  if (names.length == 2) {
    return join(names, " and ")
  }

  if (names.length > 2) {
    const lastOne = names.pop()

    return `${join(names, ", ")}, and ${lastOne}`
  }

  return ""
}
