module Factory
  module_function

  def bulk_request(operations)
    {
      "failOnErrors": 1,
      "schemas": ["urn:ietf:params:scim:api:messages:2.0:BulkRequest"],
      "Operations": operations,
    }
  end

  def bulk_operation(method:, path:, data: nil)
    {
      method: method,
      path: path,
      bulkId: "ytrewq",
      data: data.deep_symbolize_keys,
    }.compact
  end
end
