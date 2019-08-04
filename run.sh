#!/usr/bin/env bash

# set -x

RANCHER_VERSION=latest
RANCHEROS_ISO=file:///Users/lothar/Documents/GitHub/rancher/iso/latest/rancheros.iso

MACHINES="master01 master02 master03 worker01 worker02 worker03"

#2345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################

admin_password=`date +%s | shasum -a 256| base64 | head -c 8`

rancher_image="rancher/rancher:${RANCHER_VERSION}"
curl_image="appropriate/curl"
jq_image="stedolan/jq"

#2345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################

echo "... killing and removing existing machines"
docker-machine kill       rancher ${MACHINES} &>/dev/null
docker-machine rm --force rancher ${MACHINES} &>/dev/null
echo "... machines killed and removed"

echo "... creating rancher machine"
docker-machine create \
        -d virtualbox \
        --virtualbox-boot2docker-url ${RANCHEROS_ISO} \
        rancher &>/dev/null
echo "... rancher machine created"
echo "... preparing rancher machine"
RANCHER_IP=`docker-machine ip rancher`
eval $(docker-machine env rancher)
echo "... ... pulling images"
docker pull ${rancher_image} &>/dev/null
docker pull ${curl_image}    &>/dev/null
docker pull ${jq_image}      &>/dev/null
echo "... ... starting rancher"
docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v /opt/rancher:/var/lib/rancher ${rancher_image} &>/dev/null
echo "... ... waiting for rancher"
while true; do
  docker run --rm --net=host ${curl_image} -sLk https://${RANCHER_IP}/ping &>/dev/null && break
  sleep 5
done
echo "... ... login to rancher"
while true; do
    LOGINTOKEN=$(docker run --rm --net=host ${curl_image} -s "https://${RANCHER_IP}/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure | docker run --rm -i ${jq_image} -r .token)
    if [ "${LOGINTOKEN}" != "null" ]; then
        break
    else
        sleep 5
    fi
done
echo "... ... logged in as admin/admin"
docker run --rm --net=host ${curl_image} -s "https://${RANCHER_IP}/v3/users?action=changepassword" -H 'content-type: application/json' -H "Authorization: Bearer ${LOGINTOKEN}" --data-binary '{"currentPassword":"admin","newPassword":"'${admin_password}'"}' --insecure
echo "... ... changed to ${admin_password}"
echo "... ... creating APITOKEN"
APITOKEN=$(docker run --rm --net=host ${curl_image} -s "https://${RANCHER_IP}/v3/token" -H 'content-type: application/json' -H "Authorization: Bearer ${LOGINTOKEN}" --data-binary '{"type":"token","description":"automation"}' --insecure | docker run --rm -i ${jq_image} -r .token)
echo "... ... APITOKEN created"
echo "... ... configuring server-url"
docker run --rm --net=host ${curl_image} -s "https://${RANCHER_IP}/v3/settings/server-url" -H 'content-type: application/json' -H "Authorization: Bearer ${APITOKEN}" -X PUT --data-binary '{"name":"server-url","value":"'https://${RANCHER_IP}'"}' --insecure &>/dev/null
echo "... ... server-url configured"
echo "... ... creating CLUSTERID"
CLUSTERID=$(docker run --rm --net=host ${curl_image} -s "https://${RANCHER_IP}/v3/cluster" -H 'content-type: application/json' -H "Authorization: Bearer ${APITOKEN}" --data-binary '{"dockerRootDir":"/var/lib/docker","enableNetworkPolicy":false,"type":"cluster","rancherKubernetesEngineConfig":{"kubernetesVersion":"'$k8s_version'","addonJobTimeout":30,"ignoreDockerVersion":true,"sshAgentAuth":false,"type":"rancherKubernetesEngineConfig","authentication":{"type":"authnConfig","strategy":"x509"},"network":{"options":{"flannelBackendType":"vxlan"},"plugin":"canal","canalNetworkProvider":{"iface":"eth1"}},"ingress":{"type":"ingressConfig","provider":"nginx"},"monitoring":{"type":"monitoringConfig","provider":"metrics-server"},"services":{"type":"rkeConfigServices","kubeApi":{"podSecurityPolicy":false,"type":"kubeAPIService"},"etcd":{"creation":"12h","extraArgs":{"heartbeat-interval":500,"election-timeout":5000},"retention":"72h","snapshot":false,"type":"etcdService","backupConfig":{"enabled":true,"intervalHours":12,"retention":6,"type":"backupConfig"}}}},"localClusterAuthEndpoint":{"enabled":true,"type":"localClusterAuthEndpoint"},"name":"tinysetup"}' --insecure | docker run --rm -i ${jq_image} -r .id)
echo "... ... CLUSTERID created"
echo "... ... creating CLUSTERREGISTRATIONTOKEN"
CLUSTERREGISTRATIONTOKEN=$(docker run --rm --net=host ${curl_image} -s "https://${RANCHER_IP}/v3/clusterregistrationtoken" -H 'content-type: application/json' -H "Authorization: Bearer ${APITOKEN}" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'${CLUSTERID}'"}' --insecure)
echo "... ... CLUSTERREGISTRATIONTOKEN created"
echo "... ... creating NODECOMMAND"
NODECOMMAND=$(docker run --rm --net=host ${curl_image} -s "https://${RANCHER_IP}/v3/clusterregistrationtoken" -H 'content-type: application/json' -H "Authorization: Bearer ${APITOKEN}" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'${CLUSTERID}'"}' --insecure | docker run --rm -i ${jq_image} -r .nodeCommand)
echo "... ... NODECOMMAND created"

for i in ${MACHINES}
do
    echo "... ... creating $i and starting agent"
    docker-machine create \
        -d virtualbox \
        --virtualbox-boot2docker-url ${RANCHEROS_ISO} \
        $i &>/dev/null
    IP=`docker-machine ip $i`
    IPFLAGS="--address ${IP} --internal-address ${IP}"
    case $i in
    master*)
        ROLES="--etcd --controlplane"
        ;;
    worker*)
        ROLES="--worker"
        ;;
    *)
        echo "... I seem to be running with an nonexistent role $i."
        exit
        ;;
    esac
    docker-machine ssh $i "${NODECOMMAND} ${IPFLAGS} ${ROLES}" &>/dev/null
    echo "... ... $i created and agent started"
    sleep 60
done

echo "... all machines created and agents started"

echo http://${RANCHER_IP}
echo admin / ${admin_password}

open http://${RANCHER_IP}