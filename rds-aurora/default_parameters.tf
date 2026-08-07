# default_parameters.tf
locals {
  # ---------------------------------------------------------------
  # Default parameters, keyed by parameter name.
  # apply_method is explicit here because several are static.
  # ---------------------------------------------------------------
  default_cluster_parameters_mysql = {
    character_set_server   = { value = "utf8mb4", apply_method = "pending-reboot" }
    collation_server       = { value = "utf8mb4_0900_ai_ci", apply_method = "pending-reboot" }
    lower_case_table_names = { value = "1", apply_method = "pending-reboot" }
  }

  default_cluster_parameters_postgres = {
    log_min_duration_statement = { value = "1000", apply_method = "immediate" }
    log_connections            = { value = "1", apply_method = "immediate" }
    log_disconnections         = { value = "1", apply_method = "immediate" }
    timezone                   = { value = "UTC", apply_method = "immediate" }
  }

  default_instance_parameters_mysql = {
    slow_query_log                = { value = "1", apply_method = "immediate" }
    long_query_time               = { value = "1", apply_method = "immediate" }
    log_queries_not_using_indexes = { value = "1", apply_method = "immediate" }
    performance_schema            = { value = "1", apply_method = "immediate" }
  }
  default_instance_parameters_postgres = {}

  # ---------------------------------------------------------------
  # Select defaults by engine, then gate on use_default_parameters.
  # ---------------------------------------------------------------
  selected_default_cluster_parameters = (
    local.is_mysql ? local.default_cluster_parameters_mysql :
    local.default_cluster_parameters_postgres
  )

  selected_default_instance_parameters = (
    local.is_mysql ? local.default_instance_parameters_mysql :
    local.default_instance_parameters_postgres
  )

  # ---------------------------------------------------------------
  # Caller input, list to map keyed by name.
  # ---------------------------------------------------------------
  caller_cluster_parameters = {
    for p in var.cluster_parameters : p.name => {
      value        = p.value
      apply_method = p.apply_method
    }
  }

  caller_instance_parameters = {
    for p in var.instance_parameters : p.name => {
      value        = p.value
      apply_method = p.apply_method
    }
  }

  # ---------------------------------------------------------------
  # Merge. The caller overrides the default. apply_method falls back to the
  # default entry's method, then to "immediate".
  # ---------------------------------------------------------------
  merged_cluster_parameters = {
    for name in toset(concat(
      keys(local.selected_default_cluster_parameters),
      keys(local.caller_cluster_parameters)
      )) : name => {
      value = try(
        local.caller_cluster_parameters[name].value,
        local.selected_default_cluster_parameters[name].value
      )
      apply_method = coalesce(
        try(local.caller_cluster_parameters[name].apply_method, null),
        try(local.selected_default_cluster_parameters[name].apply_method, null),
        "immediate"
      )
    }
  }

  merged_instance_parameters = {
    for name in toset(concat(
      keys(local.selected_default_instance_parameters),
      keys(local.caller_instance_parameters)
      )) : name => {
      value = try(
        local.caller_instance_parameters[name].value,
        local.selected_default_instance_parameters[name].value
      )
      apply_method = coalesce(
        try(local.caller_instance_parameters[name].apply_method, null),
        try(local.selected_default_instance_parameters[name].apply_method, null),
        "immediate"
      )
    }
  }

  # ---------------------------------------------------------------
  # Create a group only when we have parameters AND the caller did
  # not point at an existing group.
  # ---------------------------------------------------------------
  create_cluster_parameter_group = (
    length(local.merged_cluster_parameters) > 0 &&
    var.cluster_parameter_group_name == null
  )

  create_instance_parameter_group = (
    length(local.merged_instance_parameters) > 0 &&
    var.instance_parameter_group_name == null
  )
}
