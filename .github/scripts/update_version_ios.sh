#!/bin/zsh
commit=$1
versioncode="$(($2 + 10))"

commit=$(gsed '/*/p' <<< $commit)
version=$(gsed 's/[^0-9.]*\([0-9.]*\).*/\1/' <<< $commit)

if [[ $version =~ [A-Za-z_] ]]; then
    echo "Wrong version number in commit message!"
    echo "Commit message was: $commit"
    echo "Version was: $version"
    echo ""
    echo "Push a new commit with a message like this: \"1.2.3 - New Release\""
    echo "Example commit command:"
    echo "git commit -m \"1.2.3 - New Release\""
    exit 1
else
    echo "Version: $version"
    echo "Versioncode: $versioncode"
    gsed -i "s/^version":" .*$/version":" $version+$versioncode/" pubspec.yaml
    gsed -n '/version:/p' pubspec.yaml
fi