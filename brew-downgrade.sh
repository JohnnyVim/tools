#!/usr/bin/env bash

set -e

readonly formula=$1
readonly version=$2
readonly formula_path="Formula/$formula.rb"

if [ -z "$formula" ] || [ "$formula" = "--help" ] || [ "$formula" = "-h" ]; then
  echo "./brew-downgrade.sh <formula_name>            list available versions"
  echo "./brew-downgrade.sh <formula_name> <version>  install specified version"
  exit 0
fi

cd "$(brew --repository homebrew/homebrew-core)"

if [ ! -f "$formula_path" ]; then
  echo "Unknown formula; Typo in \"$formula\"?"
  exit 1
fi

if [ -z "$version" ]; then
  git log --pretty=oneline --abbrev-commit "$formula_path" | grep -o '[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*' | sort -ruV | sed -n '$!p'
  exit 0
fi

readonly brew_info=$(brew info "$formula" --json)
readonly current_version=$(jq -r '.[].linked_keg' <<<"$brew_info")

if [ "$current_version" = "$version" ]; then
  echo "Version $version is already installed."
  exit 0
fi

mapfile -t installed_version < <(jq -r '.[].installed[].version' <<<"$brew_info")
for i in "${installed_version[@]}"; do
  if [ "$i" = "$version" ]; then
    echo "Switching to version $version"
    brew switch "$formula" "$version"
    brew pin "$formula" >/dev/null
    exit 0
  fi
done

readonly commit=$(git log --pretty=oneline --abbrev-commit "$formula_path" | sed -n "/${version//./\.}/{p;q;}" | cut -d ' ' -f 1)
if [ -z "$commit" ]; then
  echo "Specified version ($version) is not available"
  exit 1
fi
git checkout "$commit" "$formula_path"
brew unlink "$formula"
brew install "$formula"
brew pin "$formula" >/dev/null
git checkout master "$formula_path"
