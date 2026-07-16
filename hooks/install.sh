#!/bin/sh
# Enable shared git hooks for this repository.
# Run once after cloning: sh hooks/install.sh

git config core.hooksPath hooks
echo "Git hooksPath set to 'hooks/'. Pre-commit gdformat is now active."
