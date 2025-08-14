# @summary Patch nodes collected by a fact group
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

    $batch_results = $batches.map |$batch| {
      # out::message("patch_group.pp: Patching with nodes: ${batch}")
      run_plan('os_patching::patch_batch', { batch => $batch })
    }

    # Merge all batch results into a single hash by combining arrays
    $initial_result = {
      'targets'      => [],
      'patched'      => [],
      'failed'       => [],
      'skipped'      => [],
      'health_check' => $batch_results[0]['health_check'], # Get from first batch
    }

    $result = $batch_results.reduce($initial_result) |$merged, $batch_result| {
      {
        'targets'      => ($merged['targets'] + $batch_result['targets']).flatten,
        'patched'      => ($merged['patched'] + $batch_result['patched']).flatten,
        'failed'       => ($merged['failed'] + $batch_result['failed']).flatten,
        'skipped'      => ($merged['skipped'] + $batch_result['skipped']).flatten,
        'health_check' => $merged['health_check'],
      }
    }
  } else {
    out::message('patch_group.pp: Patching in batches is disabled')
    out::message("patch_group.pp: Patching all targets at once: ${targets}")
    $result = run_plan('os_patching::patch_batch', { batch => $targets })
  }

  return $result
}
