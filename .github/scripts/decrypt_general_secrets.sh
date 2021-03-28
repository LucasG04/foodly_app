#!/bin/sh

gpg --quiet --batch --yes --decrypt --passphrase="$ANDROID_KEYS_SECRET_PASSPHRASE" --output lib/utils/secrets.dart lib/utils/secrets.dart.gpg