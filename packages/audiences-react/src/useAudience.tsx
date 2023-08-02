import { useState, useEffect } from "react"
import { useFetch } from "use-http"

import { AudienceContext } from "./types"

export default function useAudience(
  uri: string,
): [AudienceContext | undefined, (uri: AudienceContext) => void] {
  const [context, setContext] = useState<AudienceContext>()
  const { get, put } = useFetch(uri)
  useEffect(() => {
    load()
  }, [])

  async function load() {
    return get().then(setContext)
  }
  async function updateContext(context: AudienceContext) {
    return put(context).then(setContext)
  }

  return [context, updateContext]
}
