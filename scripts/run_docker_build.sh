#!/usr/bin/env bash

# NOTE: This script has been adapted from content generated by github.com/conda-forge/conda-smithy

REPO_ROOT=$(cd "$(dirname "$0")/.."; pwd;)
IMAGE_NAME="pelson/obvious-ci:latest_x64"

config=$(cat <<CONDARC

channels:
 - conda-forge
 - defaults

show_channel_urls: True

CONDARC
)

cat << EOF | docker run -i \
                        -v ${REPO_ROOT}/recipes:/conda-recipes \
                        -a stdin -a stdout -a stderr \
                        $IMAGE_NAME \
                        bash || exit $?

if [ "${BINSTAR_TOKEN}" ];then
    export BINSTAR_TOKEN=${BINSTAR_TOKEN}
fi

export PYTHONUNBUFFERED=1
echo "$config" > ~/.condarc

# A lock sometimes occurs with incomplete builds. The lock file is stored in build_artefacts.
conda clean --lock

conda update --yes conda conda-build
conda install --yes anaconda-client conda-build-all
conda info

# We don't need to build the example recipe.
rm -rf /conda-recipes/example

# yum installs anything from a "yum_requirements.txt" file that isn't a blank line or comment.
find conda-recipes -mindepth 2 -maxdepth 2 -type f -name "yum_requirements.txt" \
    | xargs -n1 cat | grep -v -e "^#" -e "^$" | \
    xargs -r yum install -y

conda-build-all /conda-recipes --matrix-conditions "numpy >=1.9" "python >=2.7,<3|>=3.4"

EOF
