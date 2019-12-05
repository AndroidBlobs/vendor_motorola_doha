#!/vendor/bin/sh
#
# Identify fingerprint sensor model
#
# Copyright (c) 2019 Lenovo
# All rights reserved.
#
# Changed Log:
# ---------------------------------
# April 15, 2019  chengql2@lenovo.com  Initial version
# April 28, 2019  chengql2  Add fps_id creating step
#

script_name=${0##*/}
script_name=${script_name%.*}
function log {
    echo "$script_name: $*" > /dev/kmsg
}

utag_name_fps_id=fps_id
utag_fps_id=/proc/hw/$utag_name_fps_id

FPS_VENDOR_EGIS=egis
FPS_VENDOR_FPC=fpc

function ident_fps {
    log "- install FPC driver"
    insmod /vendor/lib/modules/fpc1020_mmi.ko
    log "- identify FPC sensor"
    /vendor/bin/hw/fpc_ident
    if [ $? == 0 ]; then
        log "ok"
        echo $FPS_VENDOR_FPC > $utag_fps_id/ascii
        return 0
    else
        log "fail"
        log "- remove FPC driver"
        rmmod fpc1020_mmi
    fi

    log "- install Egis driver"
    insmod /vendor/lib/modules/ets_fps_mmi.ko
    echo $FPS_VENDOR_EGIS > $utag_fps_id/ascii
    return 0
}

utag_reload=/proc/hw/reload

status=$(cat $utag_reload)
if [ $status == 2 ]; then
    log "start to reload utag procfs ..."
    echo "1" > $utag_reload
    status=$(cat $utag_reload)
    while [ $status == 1 ]; do
        sleep 1
        status=$(cat $utag_reload)
    done
    log "finish"
fi

utag_new=/proc/hw/all/new

if [ ! -d $utag_fps_id ]; then
    log "- create utag: $utag_name_fps_id"
    echo $utag_name_fps_id > $utag_new
    ident_fps
    return $?
fi

fps_vendor=$(cat $utag_fps_id/ascii)
log "FPS vendor: $fps_vendor"

if [ $fps_vendor == $FPS_VENDOR_EGIS ]; then
    log "- install Egis driver"
    insmod /vendor/lib/modules/ets_fps_mmi.ko
    return $?
fi

if [ $fps_vendor == $FPS_VENDOR_FPC ]; then
    log "- install FPC driver"
    insmod /vendor/lib/modules/fpc1020_mmi.ko
    return $?
fi

ident_fps
return $?
