#!/bin/bash
#
# Launch one or more Elasticsearch nodes via the Docker image,
# to form a cluster suitable for running the REST API tests.
#
# Export the STACK_VERSION variable, eg. '8.0.0-SNAPSHOT'
# Export the NODES variable to start more than 1 node, Default to 1
# Export the PORT variable to bind tcp port of service, Default to 9200
#
# @see https://container-library.elastic.co/r/elasticsearch/elasticsearch
# @source https://github.com/elastic/elastic-github-actions (With a few modifications)

set -euxo pipefail

if [[ -z $STACK_VERSION ]]; then
  echo -e "\033[31;1mERROR:\033[0m Required environment variable [STACK_VERSION] not set\033[0m"
  exit 1
fi

PORT="${PORT:-9200}"
NODES="${NODES:-1}"
MAJOR_VERSION=`echo ${STACK_VERSION} | cut -c 1`
DOCKER_NETWORK="esse"
DOCKER_IMAGE="${DOCKER_IMAGE:-docker.elastic.co/elasticsearch/elasticsearch}"

for (( node=1; node<=${NODES-1}; node++ ))
do
  port_com=$((9300 + $node - 1))
  UNICAST_HOSTS+="es$node:${port_com},"
done

environment=($(cat <<-END
  --env cluster.name=docker-elasticsearch
  --env cluster.routing.allocation.disk.threshold_enabled=false
  --env bootstrap.memory_lock=true
  --env xpack.security.enabled=false
END
))

if [ "x${MAJOR_VERSION}" == 'x6' ]; then
  environment+=($(cat <<-END
    --env xpack.license.self_generated.type=basic
    --env discovery.zen.minimum_master_nodes=${NODES}
END
  ))
elif [ "x${MAJOR_VERSION}" == 'x7' ] || [ "x${MAJOR_VERSION}" == 'x8' ]; then
  environment+=($(cat <<-END
    --env xpack.license.self_generated.type=basic
    --env action.destructive_requires_name=false
    --env discovery.seed_hosts=es1
END
  ))
fi


function cleanup_network {
  if [[ "$(docker network ls -q -f name=$1)" ]]; then
    echo -e "\033[34;1mINFO:\033[0m Removing network $1\033[0m"
    (docker network rm "$1") || true
  fi
}

cleanup_network "$DOCKER_NETWORK"
docker network create "$DOCKER_NETWORK"

for (( node=1; node<=${NODES-1}; node++ ))
do
  port=$((PORT + $node - 1))
  port_com=$((9300 + $node - 1))
  docker run \
    --rm \
    --env "node.name=es${node}" \
    --env "discovery.zen.ping.unicast.hosts=${UNICAST_HOSTS}" \
    --env "discovery.zen.minimum_master_nodes=${NODES}" \
    --env "http.port=${port}" \
    --env "ES_JAVA_OPTS=-Xms1g -Xmx1g -da:org.elasticsearch.xpack.ccr.index.engine.FollowingEngineAssertions" \
    "${environment[@]}" \
    --ulimit nofile=65536:65536 \
    --ulimit memlock=-1:-1 \
    --publish "${port}:${port}" \
    --publish "${port_com}:${port_com}" \
    --detach \
    --network="$DOCKER_NETWORK" \
    --name="es${node}" \
    ${DOCKER_IMAGE}:${STACK_VERSION}
done

docker run \
  --network="$DOCKER_NETWORK" \
  --rm \
  appropriate/curl \
  --max-time 120 \
  --retry 120 \
  --retry-delay 1 \
  --retry-connrefused \
  --show-error \
  --silent \
  http://es1:$PORT

sleep 10

echo "Elasticsearch up and running"
