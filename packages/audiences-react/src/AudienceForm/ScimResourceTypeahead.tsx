import debounce from "lodash/debounce"
import { useController } from "react-hook-form"
import { Typeahead } from "playbook-ui"

import {
  BaseScim,
  ScimListResponse,
  ScimResourceType,
  ScimUser,
} from "../types"
import { useFetch } from "use-http"

interface PlaybookOption {
  label: string
  value: any
  imageUrl?: string
}
function mapPlaybookOptions(
  objects: BaseScim[],
): (BaseScim & PlaybookOption)[] {
  return objects
    ? objects.map((object) => ({
        label: object.displayName,
        value: object.id,
        imageUrl: object.photoUrl,
        ...object,
      }))
    : []
}

export interface ScimResourceTypeahead {
  name: string
  resource: ScimResourceType
  valueComponent?: any
  label: string
}
export default function ScimResourceTypeahead({
  name,
  resource,
  ...typeaheadProps
}: ScimResourceTypeahead) {
  const { get } = useFetch<ScimListResponse<BaseScim>>(resource.endpoint)

  const searchResourceOptions = async (
    _search: string,
    callback: (options: PlaybookOption[]) => void,
  ) => {
    const options = await get()
    callback(mapPlaybookOptions(options.Resources))
  }
  const { field } = useController({ name })

  return (
    <Typeahead
      isMulti
      async
      loadOptions={debounce(searchResourceOptions, 300)}
      placeholder=""
      {...typeaheadProps}
      {...field}
      ref={undefined} // Warning: Function components cannot be given refs. Attempts to access this ref will fail. Did you mean to use React.forwardRef()?
      value={mapPlaybookOptions(field.value)}
    />
  )
}
