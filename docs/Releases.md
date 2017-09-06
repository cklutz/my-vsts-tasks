# How to create a release

## About versions

The version of individual tasks and the version of the collection of them as a whole
is independent. That is, a task may be at version 1.0.3, but the collection of tasks
may be at version "rel-0.1.2". This is intentional.

## Step 1: Run local build, tests and packaging

    build-full.cmd

**Note:** This will also bump the patch-level version of every task by one.

## Step 2: Commit changes and assign a tag

    git commit -m "...."
    git tag rel-<version>

## Step 3: Push changes with tag

    git push origin rel-<version>

This triggers a CI build that will also create a GitHub release and
publish the "_packages\task.zip" as an artifact with it.

