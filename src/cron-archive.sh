#!/bin/sh

git_dir="$HOME/pxe-clients-linux"
archive_dir="$HOME/archive/pxe-clients-linux"
log="$HOME/cron-archive.log"
targz_shortname='install_client_linux_archive-tftp'
targz_name="$targz_shortname.tar.gz"
targz_src="$git_dir/archives/$targz_name"
version_txt="$git_dir/archives/versions.txt"
targz_symlink="$archive_dir/$targz_name"
commit_pattern='COMMIT_ID'
targz_target="$archive_dir/${targz_shortname}_${commit_pattern}.tar.gz"
targz_pattern="${targz_shortname}_*.tar.gz"

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

targz_target=$(printf '%s' "$targz_target" | sed "s/$commit_pattern/$commit_id/")
targz_target_name="${targz_target##*/}"

if [ ! -f "$targz_target" ]
then
    # New archive to build and put in the site.
    if (cd "${git_dir}/src/" && './build-archive.sh')
    then
        cp -a "$targz_src" "$targz_target"
        rm -f "$targz_symlink"
        ln -s "$targz_target_name" "$targz_symlink"
    fi
fi

# Cleaning.
git checkout "$targz_src" "$version_txt"
find "$archive_dir" -type f -name "$targz_pattern" ! -name "$targz_target_name" -delete


