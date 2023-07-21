import find from "lodash/find";
import join from "lodash/join";
import map from "lodash/map";

import type { Grouped, ScimGroup } from "./types";

export function toSentence(groups: ScimGroup[]) {
  const names = map(groups, "name");

  if (names.length == 1) {
    return names;
  }
  if (names.length == 2) {
    return join(names, " and ");
  }

  if (names.length > 2) {
    const lastOne = names.pop();

    return `${join(names, ", ")}, and ${lastOne}`;
  }

  return "";
}

export function groupName(
  { groups }: Grouped,
  groupType: string
): string | undefined {
  const group = find(groups, { groupType });
  return group?.name;
}
