#!/bin/sh

git_dir="$HOME/pxe-clients-linux"
archive_dir="$HOME/archive/pxe-clients-linux"
log="$HOME/cron-archive.log"

# Files to put in the archive directory.
targz="$git_dir/archives/install_client_linux_archive-tftp.tar.gz"
script="$git_dir/src/install_client_linux_mise_en_place.sh"
versions="$git_dir/archives/versions.txt"

# Takes 3 arguments:
#
#   1. The path of the source file.
#   2. The commit ID.
#   3. The target directory (the archive directory).
#
copy_in () {
  local src="$1"
  local commit_id="$2"
  local archive_dir="$3"

  local name="${src##*/}"
  local shortname="${name%%.*}"        # name without the extension
  local extension="${name#$shortname}" # extension with the dot charater

  local target_pattern="${shortname}_*${extension}"
  local target_name="${shortname}_${commit_id}${extension}"
  local target="$archive_dir/${target_name}"
  local symlink="$archive_dir/$name"

  # Copy the source to archive.
  cp "$src" "$target"

  # Update the symlink.
  rm -f "$symlink"
  ln -s "$target_name" "$symlink"

  # Remove old file(s).
  find "$archive_dir" -maxdepth 1 -type f -name "$target_pattern" '!' -name "$target_name" -delete
}

exec >"$log" 2>&1
date
echo ''
set -x

[ -d "$archive_dir" ] || {
    echo "\`$archive_dir\` directory does not exist. End of the script."
    exit 1
}

cd "$git_dir" || {
    echo "\`$git_dir\` directory does not exist. End of the script."
    exit 1
}

echo '=> Update the git repository'
timeout --kill-after=10s 20s git pull || {
    echo "Impossible to update the git repository. End of the script."
    exit 1
}

# The last commit id (just the last 10 characters).
commit_id=$(git log --format="%H" -n 1 | sed -r 's/^(.{10}).*$/\1/')

n=$(find "$archive_dir" -maxdepth 1 -type f -name "*${commit_id}*" | wc -l)

if [ "$n" = '0' ]
then
    # Need to build a new archive to build.
    if (cd "$git_dir/src/" && './build-archive.sh')
    then
        copy_in "$targz"    "$commit_id" "$archive_dir"
        copy_in "$script"   "$commit_id" "$archive_dir"
        copy_in "$versions" "$commit_id" "$archive_dir"
    fi
    # Clean the git repository.
    git checkout "$targz" "$versions"
else
    echo 'Files already present in archive.'
fi


