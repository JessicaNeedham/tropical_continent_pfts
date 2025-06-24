#!/bin/sh
# ==============================================================================
# ==============================================================================
export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SROF_SGLC_SWAV 
export RES=f45_f45
export MACH=pm-cpu
export PROJECT=e3sm
export COMPILER=gnu

export TAG='nocomp_africa'
export CASEROOT=/pscratch/sd/j/jneedham/elm_runs/tropical_fb
export CIMEROOT=/global/homes/j/jneedham/E3SM-dev/E3SM/cime/scripts
cd ${CIMEROOT}

export CIME_HASH=`git log -n 1 --pretty=%h`
export ELM_HASH=`(cd ../../components/elm/src;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}	
export CASE_NAME=${CASEROOT}/${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`


# REMOVE EXISTING CASE DIRECTORY IF PRESENT 
rm -rf ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --project=${PROJECT}

cd ${CASE_NAME}

./xmlchange STOP_N=20
./xmlchange STOP_OPTION=nyears
./xmlchange REST_N=10
./xmlchange REST_OPTION=nyears
./xmlchange RESUBMIT=4
./xmlchange SAVE_TIMING=FALSE
./xmlchange DEBUG=FALSE

./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange RUN_STARTDATE='1900-01-01'
./xmlchange DATM_CLMNCEP_YR_ALIGN=1965
./xmlchange DATM_CLMNCEP_YR_START=1965
./xmlchange DATM_CLMNCEP_YR_END=2014

./xmlchange LND_DOMAIN_FILE=africa_domain.nc
./xmlchange LND_DOMAIN_PATH=/global/homes/j/jneedham/tropical-fixed-biog/domainsurf
./xmlchange ATM_DOMAIN_FILE=africa_domain.nc
./xmlchange ATM_DOMAIN_PATH=/global/homes/j/jneedham/tropical-fixed-biog/domainsurf


#./xmlchange JOB_WALLCLOCK_TIME=14:58:00
#./xmlchange JOB_QUEUE=regular
./xmlchange JOB_WALLCLOCK_TIME=00:28:00
./xmlchange JOB_QUEUE=debug

./xmlchange GMAKE=make
#./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
#./xmlchange DOUT_S=TRUE
#./xmlchange DOUT_S_ROOT='$CASEROOT/run'
./xmlchange RUNDIR=${CASE_NAME}/run
./xmlchange EXEROOT=${CASE_NAME}/bld

cat >>  user_nl_elm <<EOF
use_fates_sp=.false.
use_fates_nocomp=.true.
use_fates_fixed_biogeog=.true.
fates_electron_transport_model='FvCB1980'
fates_radiation_model='twostream'
use_fates_daylength_factor=.true.
fates_spitfire_mode=1
fsurdat = '/global/homes/j/jneedham/tropical-fixed-biog/domainsurf/africa_surf.nc'
fates_paramfile='/global/homes/j/jneedham/tropical-fixed-biog/param_files/v2/fates_params_africa.nc'
hist_fincl1='FATES_VEGC', 'FATES_FRACTION', 'FATES_GPP','FATES_NEP','FATES_AUTORESP', 'FATES_HET_RESP', 'QVEGE', 'QVEGT',
'QSOIL','EFLX_LH_TOT','FSH','FSR', 'FSDS','FSA','FIRE','FLDS','FATES_LAI', 
 'FATES_GPP_PF', 'FATES_NPP_PF', 'FATES_LEAFAREA_HT',  'FATES_CANOPYAREA_HT',
'FATES_VEGC_PF','FATES_VEGC_ABOVEGROUND_SZPF', 'FATES_DDBH_SZPF', 'FATES_NPLANT_SZPF','FATES_ZSTAR_AP', 
 'FATES_CROWNAREA_PF', 'FATES_RECRUITMENT_PF','FATES_MORTALITY_HYDRAULIC_SZPF','FATES_BURNFRAC_AP',
'FATES_FIRE_INTENSITY_BURNFRAC_AP','FATES_PATCHAREA_AP',  'FATES_M3_MORTALITY_CANOPY_SZPF', 
'FATES_M3_MORTALITY_USTORY_SZPF', 'FATES_NPLANT_CANOPY_SZPF',  'FATES_NPLANT_USTORY_SZPF',
'FATES_MORTALITY_FIRE_SZPF','FATES_MORTALITY_CSTARV_SZPF',  'FATES_MORTALITY_TERMINATION_SZPF',
'FATES_LEAFC_PF', 'FATES_STOREC_PF', 'FATES_SEED_BANK', 'FATES_SEEDS_IN', 'FATES_SEED_ALLOC_SZPF',
'FATES_LEAF_ALLOC_SZPF'
EOF


cat >> user_nl_datm <<EOF
taxmode = "cycle", "cycle", "cycle"
EOF

./case.setup
./case.build
./case.submit
