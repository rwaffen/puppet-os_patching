# @summary Patch nodes
#
plan os_patching::patch_group (
  String[1] $group,
  Boolean $patch_in_batches = true,
  Integer $batch_size       = 15,
) {
  $pql_query = puppetdb_query("inventory[certname] { facts.os_patching.group = '${group}'}")
  $certnames = $pql_query.map |$item| { $item['certname'] }
  $targets   = get_targets($certnames)

  out::message("patch_group.pp: Patching group: ${group}")
  out::message("patch_group.pp: Targets in group: ${targets}")

  if $patch_in_batches {
    out::message('patch_group.pp: Patching in batches is enabled')
    out::message("patch_group.pp: Patching in batches of size: ${batch_size}")

    $batches = slice($targets, $batch_size)
    out::message("patch_group.pp: Patching batches created: ${batches}")

    $batches.each |$batch| {
      out::message("patch_group.pp: Patching batch size: ${batch.size} with nodes: ${batch}")
      $result = run_plan('os_patching::batch', { batch => $batch })
    }
  } else {
    out::message('patch_group.pp: Patching in batches is disabled')
    out::message("patch_group.pp: Patching all targets at once: ${targets}")
    $result = run_plan('os_patching::batch', { batch => $targets })
  }

  return $result
}
