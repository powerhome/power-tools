import { useState } from "react";

export function useToggler(
  startValue: boolean = false
): [boolean, () => void, (show: boolean) => void] {
  const [show, toggle] = useState(startValue);
  const toggler = () => toggle(!show);

  return [show, toggler, toggle];
}
