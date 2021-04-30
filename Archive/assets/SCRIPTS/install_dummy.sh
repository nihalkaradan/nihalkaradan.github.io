#!/bin/bash
#set -e
 
# This function will exit the script and prints error message and exit code of last command
exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

# enable !! command completion
set -o history -o histexpand

# Read properties file
source cp4d.properties

echo "DRY RUN  = "$dry_run
echo "Namespace = "$namespace

# Check if project exists on cluster. If not create new project
if ! oc get project $namespace;
then
	echo "Project $namespace does not exists. Creating project ........."
	oc new-project $namespace
else
	echo "Project $namespace already exists. Using project .........."
	# Load project
	oc project $namespace
fi

# create image pull secret
echo "Creating ImagePullSecret"
oc create -f secret.yaml --dry-run=$dry_run

# create route to openshift-image-registry
echo "Creating image registry route"
oc create -f registryroute.yaml --dry-run=$dry_run

# set kernel params on kube-system project
echo "Setting Kernel parameters"
oc create -f setkernelparams.yaml --dry-run=$dry_run

# enable root sqaush on kube-system project
echo "Enabling no root squash"
oc create -f norootsquash.yaml --dry-run=$dry_run

# create admin permission for lite installation
echo "Creating admin permissions for lite installation"
./cpd-linux adm --repo repo.yaml --assembly lite --namespace $namespace --apply --accept-all-licenses

# install lite
echo "Installing cp4d lite in namespace = "$namespace

COMMAND="./cpd-linux -s repo.yaml -a lite --verbose --target-registry-password $(oc whoami -t) --target-registry-username $(oc whoami) --insecure-skip-tls-verify --cluster-pull-prefix image-registry.openshift-image-registry.svc:5000/$namespace --transfer-image-to $(oc get route -n openshift-image-registry |tail -1|awk '{print $2}')/$namespace -n $namespace -c ibmc-file-gold-gid --accept-all-licenses --override override.yaml"

if [ $dry_run == "true" ]
then
	echo "******** DRYRUN *************"
	COMMAND=$COMMAND" --dry-run"
	$COMMAND
else
	echo "******** NO DRYRUN *************"
	$COMMAND
fi
exit_on_error $?

# Create routes for CP4D web console
#echo "Creating routes for cp4d web console"
#oc create -f routes.yaml -n $namespace --dry-run=$dry_run

# Create admin permission for ds installation
echo "Creating admin permissions for ds installation"
./cpd-linux adm --repo repo.yaml --assembly ds --namespace $namespace --apply --accept-all-licenses
exit_on_error $?

# install Datastage (ds)
echo "Installing Datastage (ds) in namespace = "$namespace

COMMAND="./cpd-linux -s repo.yaml -a ds --verbose --target-registry-password $(oc whoami -t) --target-registry-username $(oc whoami) --insecure-skip-tls-verify --cluster-pull-prefix image-registry.openshift-image-registry.svc:5000/$namespace --transfer-image-to $(oc get route -n openshift-image-registry |tail -1|awk '{print $2}')/$namespace -n $namespace -c ibmc-file-gold-gid --accept-all-licenses --override override.yaml"

if [ $dry_run == "true" ]
then
	echo "******** DRYRUN *************"
	COMMAND=$COMMAND" --dry-run"
	$COMMAND
else
	echo "******** NO DRYRUN *************"
	$COMMAND
fi
exit_on_error $? 

# Create admin permission for db2oltp installation
echo "Creating admin permissions for ds installation"
./cpd-linux adm --repo repo.yaml --assembly db2oltp --namespace $namespace --apply --accept-all-licenses
exit_on_error $?

# install db2oltp
echo "Installing db2oltp in namespace = "$namespace

COMMAND="./cpd-linux -s repo.yaml -a db2oltp --verbose --target-registry-password $(oc whoami -t) --target-registry-username $(oc whoami) --insecure-skip-tls-verify --cluster-pull-prefix image-registry.openshift-image-registry.svc:5000/$namespace --transfer-image-to $(oc get route -n openshift-image-registry |tail -1|awk '{print $2}')/$namespace -n $namespace -c ibmc-file-gold-gid --accept-all-licenses --override override.yaml"

if [ $dry_run == "true" ]
then
	echo "******** DRYRUN *************"
	COMMAND=$COMMAND" --dry-run"
	$COMMAND
else
	echo "******** NO DRYRUN *************"
	$COMMAND
fi
exit_on_error $? 

# Create DB2 instance 
#oc exec $(oc get po -o name | grep zen-database-core | head -n 1 | cut -d'/' -f 2) -- /tools/validate.sh --installonly --dbtype db2oltp --db-name $db_name1 --dedicated false --storageclass $storage_class_name | tee db2wh_provision_validation.txt
#exit_on_error $?

#oc exec $(oc get po -o name | grep zen-database-core | head -n 1 | cut -d'/' -f 2) -- /tools/validate.sh --installonly --dbtype db2oltp --db-name $db_name2 --dedicated false --storageclass $storage_class_name | tee db2wh_provision_validation.txt
#exit_on_error $?


