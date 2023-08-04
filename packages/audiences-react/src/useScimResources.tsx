import { ScimListResponse, ScimResourceType } from "./types"
import { useFetch } from "use-http"

export function useScimResources(schema: string) {
  const { data } = useFetch<ScimListResponse<ScimResourceType>>(
    "/ResourceTypes",
    { persist: true },
    [],
  )
  const resource = data?.Resources || []
  return resource.filter((resource) => resource.schema == schema)
}
