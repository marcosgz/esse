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

set -o errexit
set -o nounset
set -o pipefail

if [[ -z $STACK_VERSION ]]; then
  echo -e "\033[31;1mERROR:\033[0m Required environment variable [STACK_VERSION] not set\033[0m"
  exit 1
fi

PORT="${PORT:-9200}"
NODES="${NODES:-1}"
SERVICE_TYPE="${SERVICE_TYPE:-elasticsearch}" # elasticsearch or opensearch
SERVICE_HEAP_SIZE="${SERVICE_HEAP_SIZE:-512m}"
MAJOR_VERSION=`echo ${STACK_VERSION} | cut -c 1`
DOCKER_NETWORK="esse"
DOCKER_IMAGE="${DOCKER_IMAGE:-docker.elastic.co/elasticsearch/elasticsearch}"
WAIT_FOR_URL="https://github.com/eficode/wait-for/releases/download/v2.2.3/wait-for"
ROOT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")"; cd ../ ; pwd -P )
WAIT_FOR_PATH="${ROOT_PATH}/tmp/wait-for"

for (( node=1; node<=${NODES-1}; node++ )) do
  port_com=$((9300 + $node - 1))
  UNICAST_HOSTS+="${SERVICE_TYPE}${node}:${port_com},"
  HOSTS+="${SERVICE_TYPE}${node},"
done
UNICAST_HOSTS=${UNICAST_HOSTS::-1}
HOSTS=${HOSTS::-1}

trace() {
	(
		set -x
		"$@"
	)
}

install_wait_for() {
	curl -fsSL -o "${WAIT_FOR_PATH}" "$WAIT_FOR_URL"
	chmod +x "${WAIT_FOR_PATH}"
	"${WAIT_FOR_PATH}" --version
}

start_docker_services() {
  local servicesHosts=()
  for (( node=1; node<=${NODES-1}; node++ )) do
    port=$((PORT + $node - 1))
    port_com=$((9300 + $node - 1))
    servicesHosts+=("0.0.0.0:${port}")

    docker rm -f "${SERVICE_TYPE}${node}" || true
    echo -e "\033[34;1mINFO:\033[0m Starting ${SERVICE_TYPE}${node} on port ${port} and ${port_com}"
    docker run \
      --rm \
      --env "node.name=${SERVICE_TYPE}${node}" \
      --env "http.port=${port}" \
      "${environment[@]}" \
      --ulimit nofile=65536:65536 \
      --ulimit memlock=-1:-1 \
      --publish "${port}:${port}" \
      --publish "${port_com}:${port_com}" \
      --detach \
      --network="$DOCKER_NETWORK" \
      --name="${SERVICE_TYPE}${node}" \
      ${DOCKER_IMAGE}:${STACK_VERSION}
  done

  local serviceHost
	for serviceHost in "${servicesHosts[@]}"; do
    echo -e "\033[34;1mINFO:\033[0m Waiting for ${serviceHost} to be available"
    "${WAIT_FOR_PATH}" -t 10 "$serviceHost" -- echo "Service ${serviceHost} is up"
  done
}

function cleanup_network {
  if [[ "$(docker network ls -q -f name=$1)" ]]; then
    echo -e "\033[34;1mINFO:\033[0m Removing network $1\033[0m"
    (docker network rm "$1") || true
  fi
}

function create_network {
  cleanup_network "$1"
  echo -e "\033[34;1mINFO:\033[0m Creating network $1\033[0m"
  docker network create "$1" || true
}


environment=($(cat <<-END
  --env cluster.name=docker-${SERVICE_TYPE}
  --env cluster.routing.allocation.disk.threshold_enabled=false
  --env bootstrap.memory_lock=true
END
))

case "${SERVICE_TYPE}-${MAJOR_VERSION}" in
  elasticsearch-1|elasticsearch-2|elasticsearch-5)
    environment+=($(cat <<-END
        --env xpack.security.enabled=false
        --env discovery.zen.ping.unicast.hosts=${UNICAST_HOSTS}
        --env "ES_JAVA_OPTS=-Xms${SERVICE_HEAP_SIZE} -Xmx${SERVICE_HEAP_SIZE}"
END
    ))
    environment+=(--env "ES_JAVA_OPTS=-Xms${SERVICE_HEAP_SIZE} -Xmx${SERVICE_HEAP_SIZE}")
    ;;
  elasticsearch-6)
    environment+=($(cat <<-END
        --env xpack.security.enabled=false
        --env xpack.license.self_generated.type=basic
        --env discovery.zen.ping.unicast.hosts=${UNICAST_HOSTS}
        --env discovery.zen.minimum_master_nodes=${NODES}
END
    ))
    environment+=(--env "ES_JAVA_OPTS=-Xms${SERVICE_HEAP_SIZE} -Xmx${SERVICE_HEAP_SIZE}")
    ;;
  elasticsearch-7|elasticsearch-8)
    environment+=($(cat <<-END
      --env xpack.security.enabled=false
      --env xpack.license.self_generated.type=basic
      --env action.destructive_requires_name=false
      --env discovery.seed_hosts=${HOSTS}
END
    ))
    environment+=(--env "ES_JAVA_OPTS=-Xms${SERVICE_HEAP_SIZE} -Xmx${SERVICE_HEAP_SIZE}")
    if [ "x${NODES}" == "x1" ]; then
      environment+=(--env discovery.type=single-node)
    else
      environment+=(--env cluster.initial_master_nodes=${HOSTS})
    fi
    ;;
  opensearch-1|opensearch-2)
    environment+=($(cat <<-END
      --env bootstrap.memory_lock=true
      --env plugins.security.disabled=true
      --env discovery.seed_hosts=${HOSTS}
END
    ))
    environment+=(--env "OPENSEARCH_JAVA_OPTS=-Xms${SERVICE_HEAP_SIZE} -Xmx${SERVICE_HEAP_SIZE}")
    if [ "x${NODES}" == "x1" ]; then
      environment+=(--env discovery.type=single-node)
    else
      environment+=(--env cluster.initial_master_nodes=${HOSTS})
    fi
    ;;
  *)
    echo -e "\033[31;1mERROR:\033[0m Unknown service type [${SERVICE_TYPE}] and/or version [${STACK_VERSION}]"
    exit 1
    ;;
esac

trace create_network "$DOCKER_NETWORK"
trace install_wait_for
trace start_docker_services
