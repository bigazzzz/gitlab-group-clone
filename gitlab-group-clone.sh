#!/usr/bin/env bash

# use gitlab-group-clone.sh GROUP_ID

CREDENTIALS_FILE=gitlab-group-clone.secret
GITLAB_URL=$(jq -r '.gitlab_url' $CREDENTIALS_FILE)
PRIVATE_TOKEN=$(jq -r '.private_token' $CREDENTIALS_FILE)
TARGET_GROUP_ID=$1

if [ -z "$GITLAB_URL" ]; then
    echo "gitlab_url is empty. Use gitlab.com"
    GITLAB_URL="gitlab.com"
fi
if [ -z "$TARGET_GROUP_ID" ]; then
    echo "TARGET_GROUP_ID is empty"
    exit 1
fi
if [ -z "$PRIVATE_TOKEN" ]; then
    echo "private_token is empty"
    exit 1
fi

function git-clone() {
    GROUP_INFO=$(curl -s -X GET -H "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/api/v4/groups/$1")
    SUBGROUP_LIST=$(curl -s -X GET -H "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/api/v4/groups/$1/subgroups?per_page=100000000000000")
    GROUP_NAME=$(jq -r ".name" <<<"$GROUP_INFO")

    [[ -d $GROUP_NAME ]] || mkdir $GROUP_NAME
    cd $GROUP_NAME

    for repo in $(jq -r ".projects[].ssh_url_to_repo" <<<"$GROUP_INFO"); do
        git clone $repo
    done

    for subgroup in $(jq -r ".[].id" <<<"$SUBGROUP_LIST"); do
        git-clone $subgroup
    done

    cd ..
}

git-clone $TARGET_GROUP_ID
