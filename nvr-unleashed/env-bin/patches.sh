#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

mkdir -p lib-patches

patches_apply() {
    find lib-patches/ -mindepth 1 -maxdepth 1 -type f | while IFS= read -r ENTRY; do
        NAME=$(basename -- "$ENTRY")
        NAME=${NAME%.patch}
        if [ ! -e "lib/$NAME/.git" ] || git -C "lib/$NAME" diff --quiet; then
            echo "applying '$ENTRY'"
            git -C "lib/$NAME" apply "$(pwd)/$ENTRY"
        else
            echo "not applying '$ENTRY', 'lib/$NAME' has uncommitted changes"
        fi
    done
}

patches_update() {
    find lib/ -mindepth 1 -maxdepth 1 -type d | while IFS= read -r ENTRY; do
        NAME=$(basename -- "$ENTRY")
        if ! git -C "$ENTRY" diff --quiet; then
            PATCH="lib-patches/$NAME.patch"
            echo "creating patch '$PATCH'"
            git -C "$ENTRY" diff -U1 >"$PATCH"
        else
            echo "no uncommitted changes for '$ENTRY'"
        fi
    done
}

patches_restore() {
    read -rp "discard all lib changes? [ENTER to continue]" NOP
    find lib/ -mindepth 1 -maxdepth 1 -type d | while IFS= read -r ENTRY; do
        git -C "$ENTRY" checkout -- .
    done
}

case "$1" in
    apply) patches_apply;;
    update) patches_update;;
    restore) patches_restore;;
    *)
        echo "usage: ${0##*/} apply/update/restore"
        exit 1
        ;;
esac
