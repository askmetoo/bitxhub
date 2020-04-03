set -e

source x.sh

CURRENT_PATH=$(pwd)
PROJECT_PATH=$(dirname "${CURRENT_PATH}")
BUILD_PATH=${CURRENT_PATH}/build
GIT_COMMIT=$(git log --pretty=format:'%h' -n 1)
APP_VERSION=1.0.0-rc1-${GIT_COMMIT}

USERNAME=hyperchain
SERVER_BUILD_PATH="/home/hyperchain/bitxhub"

# help prompt message
function printHelp() {
  print_blue "Usage:  "
  echo "  deploy.sh <mode>"
  echo "    <mode> - one of 'deploy'"
  echo "      - 'deploy <bitxhub_addr> <node_num> <recompile(true or false)>' - deploy bitxhub to remote server"
  echo "  deploy.sh -h (print this message)"
}

function deploy() {
  if [ $1 ]; then
    BITXHUB_ADDR=$1
  fi

  if [ $2 ]; then
    NODE_NUM=$2
  fi

  if [ $3 ]; then
    RECOMPILE=$3
  fi

  print_blue "1. Generate config"
  bash config.sh "$NODE_NUM"

  print_blue "2. Compile bitxhub"
  if [[ $RECOMPILE == true ]]; then
    bash cross_compile.sh linux-amd64 ${PROJECT_PATH}
  else
    echo "Do not need compile"
  fi

  ## prepare deploy package
  cd "${CURRENT_PATH}"
  cp ../bin/bitxhub_linux-amd64 "${BUILD_PATH}"/bitxhub
  cp ../internal/plugins/build/*.so "${BUILD_PATH}"/
  tar cf build${APP_VERSION}.tar.gz build

  print_blue "3. Deploy bitxhub"
  cd "${CURRENT_PATH}"
  scp build${APP_VERSION}.tar.gz ${USERNAME}@"${BITXHUB_ADDR}":${SERVER_BUILD_PATH}
  scp boot_bitxhub.sh ${USERNAME}@"${BITXHUB_ADDR}":${SERVER_BUILD_PATH}

  ssh -t ${USERNAME}@"${BITXHUB_ADDR}" '
    cd '${SERVER_BUILD_PATH}'
    bash boot_bitxhub.sh 4
    tmux attach-session -t bitxhub
'
}

MODE=$1

if [ "$MODE" == "deploy" ]; then
  shift
  deploy $1 $2 $3
else
  printHelp
  exit 1
fi
