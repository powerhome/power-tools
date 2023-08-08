import { useState, useEffect } from "react"
import { useFetch } from "use-http"

import { AudienceContext } from "./types"

export default function useAudience(
  uri: string,
): [AudienceContext | undefined, (uri: AudienceContext) => void] {
  const [context, setContext] = useState<AudienceContext>()
  const { get, put } = useFetch(uri, {
    onError({ error }) {
      throw error.message
    },
  })
  useEffect(() => {
    get().then(setContext)
  }, [])

  async function updateContext(context: AudienceContext) {
    try {
      const updatedContext = await put(context)
      setContext(updatedContext)
    } catch (e) {
      console.log(context, e)
    }
  }

  return [context, updateContext]
}
