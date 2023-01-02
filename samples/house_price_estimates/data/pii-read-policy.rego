package dataapi.authz

rule[{"action": {"name":"RedactAction", "columns": column_names}, "policy": description}] {
  description := "Redact columns tagged as PII.Sensitive in datasets tagged with Purpose.Housing = true"
  input.action.actionType == "read"
  input.resource.metadata.tags["Purpose.Housing"]
  column_names := [input.resource.metadata.columns[i].name | input.resource.metadata.columns[i].tags["PII.Sensitive"]]
  count(column_names) > 0
}
