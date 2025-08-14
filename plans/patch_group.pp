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

  out::message("Patching group: ${group}")
  out::message("Targets in group: ${targets}")

  if $patch_in_batches {
    out::message('Patching in batches is enabled')
    out::message("Patching in batches of size: ${batch_size}")

    $batches = slice($targets, $batch_size)
    out::message("Patching batches created: ${batches}")

    $batches.each |$batch| {
      out::message("Patching batch of size: ${batch.size} with nodes: ${batch}")
      $result = run_plan('os_patching::batch', { batch => $batch })
    }
  } else {
    $result = run_plan('os_patching::batch', { batch => $targets })
  }

  return $result
}
