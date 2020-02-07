#!/bin/bash

set +e # stop erroneous failures reported by Jenkins

STUCKVMS=0
sleepduration=30
retries=61
cloudmonkey set output json

# shutdown_vms

  # dont wait for async job - execute in parallel until told otherwise
  cloudmonkey set asyncblock false

  # TODO: N/A

  cloudmonkey set asyncblock false
    for vmid in $(cmk list virtualmachines listall=true state="Running" | jq -r '.virtualmachine[].id'); do
      echo "Stopping VM $vmid"
      cmk stop virtualmachine id=$vmid || true
    done


  tries=$retries
  while [ $tries -gt 0 ]     
  do 
    NUM_GCVMS=`cmk list virtualmachines listall=true state="Running" | jq -r '.virtualmachine[].id' | wc -l`
    if [[ $NUM_GCVMS -gt 0 ]]; then
      echo "Still $NUM_GCVMS left. waiting.."
      sleep $sleepduration
      tries=$(($tries-1))
      if [ $tries -eq 0 ]; then STUCKVMS=$NUM_GCVMS; fi
    else
      tries=0
    fi
  done

# shutdown_routers
echo ""
    for vmid in $(cmk list routers listall=true state="Running" | jq -r '.router[].id'); do
      echo "Stopping Router $vmid"
      cmk stop router id=$vmid || true
    done

  tries=$retries
  while [ $tries -gt 0 ]     
  do 
    NUM_GCVMS=`cmk list routers listall=true state="Running" | jq -r '.router[].id' | wc -l`
    if [[ $NUM_GCVMS -gt 0 ]]; then
      echo "Still $NUM_GCVMS left. waiting.."
      sleep $sleepduration
      tries=$(($tries-1))
      if [ $tries -eq 0 ]; then STUCKVMS=$NUM_GCVMS; fi
    else
      tries=0
    fi
  done

echo ""
# disable_zone
  cloudmonkey set asyncblock true
  for ZoneID in $(cmk list zones listall=true | jq -r '.zone[].id'); do
    echo "Disabling Zone $ZoneID"
    cmk update zone allocationstate='Disabled' id=${ZoneID} || true
  done

  for pri_stor_id in $(cmk list storagepools listall=true | jq -r '.storagepool[].id'); do
    echo "Disabling storagepool $pri_stor_id"
    cmk  enable storagemaintenance id=${pri_stor_id} || true
  done

# shutdown_system_vms
echo ""
  cloudmonkey set asyncblock false
    for vmid in $(cmk list systemvms listall=true state="Running" | jq -r '.systemvm[].id'); do
      echo "Stoppping system VM $vmid"
      cmk stop systemvm id=$vmid || true
    done

  tries=$retries
  while [ $tries -gt 0 ]     
  do 
    NUM_GCVMS=`cmk list systemvms listall=true state="Running" | jq -r '.systemvm[].id' | wc -l`
    if [[ $NUM_GCVMS -gt 0 ]]; then
      echo "Still $NUM_GCVMS left. waiting.."
      sleep $sleepduration
      tries=$(($tries-1))
      if [ $tries -eq 0 ]; then STUCKVMS=$NUM_GCVMS; fi
    else
      tries=0
    fi
  done
 cloudmonkey set asyncblock true