#!/bin/tcsh -f
#-------------------------------------------
# qflow exec script for project /home/lab-user/riscv_soc/qflow_proj
#-------------------------------------------

# /apps/vlsi/share/qflow/scripts/synthesize.sh /home/lab-user/riscv_soc/qflow_proj top /home/lab-user/riscv_soc/qflow_proj/source/top.v || exit 1
/apps/vlsi/share/qflow/scripts/placement.sh -d /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/opensta.sh  /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/opentimer.sh -a /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/vesta.sh -a /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/router.sh /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/opensta.sh  -d /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/opentimer.sh -a -d /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/vesta.sh -a -d /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/migrate.sh /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/drc.sh /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/lvs.sh /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/gdsii.sh /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/cleanup.sh /home/lab-user/riscv_soc/qflow_proj top || exit 1
# /apps/vlsi/share/qflow/scripts/display.sh /home/lab-user/riscv_soc/qflow_proj top || exit 1
