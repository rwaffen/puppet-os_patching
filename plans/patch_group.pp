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

  if $patch_in_batches {
    $batches = slice($targets, $batch_size)

    $batches.each |$batch| {
      $result = run_plan('os_patching::batch', { batch => $batch })
    }
  } else {
    $result = run_plan('os_patching::batch', { batch => $targets })
  }
}
