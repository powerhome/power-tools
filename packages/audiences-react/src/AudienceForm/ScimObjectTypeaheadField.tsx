import debounce from "lodash/debounce";
import isArray from "lodash/isArray";
import { useController } from "react-hook-form";
import { Typeahead } from "playbook-ui";

import { BaseScim } from "../types";

interface PlaybookOption {
  label: string;
  value: any;
  imageUrl?: string;
}
export type SearchCallback<T> = (
  search: string,
  callback: (options: T[]) => void
) => undefined;
export type SearchOptions<T> = T[] | SearchCallback<T>;

function mapPlaybookOptions(
  objects: BaseScim[]
): (BaseScim & PlaybookOption)[] {
  return objects
    ? objects.map((object) => ({
        label: object.name,
        value: object.id,
        imageUrl: object.photoUrl,
        ...object,
      }))
    : [];
}

export interface ScimObjectTypeaheadFieldProps {
  name: string;
  options: SearchOptions<BaseScim>;
  valueComponent?: any;
  label: string;
}
export default function ScimObjectTypeaheadField({
  name,
  options,
  ...typeaheadProps
}: ScimObjectTypeaheadFieldProps) {
  const async = !isArray(options);
  const handleLoadOptions: SearchCallback<PlaybookOption> = (
    search,
    playbookOptions
  ) => {
    async
      ? options(search, (users) => playbookOptions(mapPlaybookOptions(users)))
      : playbookOptions(mapPlaybookOptions(options));
  };
  const { field } = useController({ name });

  return (
    <Typeahead
      isMulti
      async
      loadOptions={debounce(handleLoadOptions, 300)}
      placeholder=""
      {...typeaheadProps}
      {...field}
      ref={undefined} // Warning: Function components cannot be given refs. Attempts to access this ref will fail. Did you mean to use React.forwardRef()?
      value={mapPlaybookOptions(field.value)}
    />
  );
}
