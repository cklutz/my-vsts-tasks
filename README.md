# Additional tasks for VSTS / TFS Build.

Most of the build and test infrastructure is copied from [Microsoft's VSTS Tasks](https://github.com/Microsoft/vsts-tasks).

Currently, there is only one task:

* [_RunOpenCover_](Tasks/RunOpenCover/README.md).

## Status

|   | Build & Test |
|---|:-----:|
|![Win](docs/images/win_med.png) **Windows**|[![Build status](https://ci.appveyor.com/api/projects/status/ddr94r6onjfjro23?svg=true)](https://ci.appveyor.com/project/cklutz/my-vsts-tasks)|

## Build

### Fast pass

To build and test everything, simply use:

     build-full.cmd

You will find packaged tasks in `_packages\tasks.zip`, from where you can [deploy/upload](#deploy-from-a-package) them.

### Manual steps

Once, install dependencies:

     npm install

To increment all task's patch level - required to allow upload of a new version to VSTS/TFS:

     node make.js bump

Build and test:

     npm run build
     npm test

Build a single task:

     node make.js build --task RunOpenCover
     node make.js test --task RunOpenCover

## Deploy a Build Task

### One time preparation

Use the [tfx-cli](https://github.com/Microsoft/tfs-cli) tool to upload and generally
manage build tasks for VSTS or an on premise TFS instance.

Install the tfx tool by `npm install -g tfx-cli`.

Afterwards make sure you login to your TFS / VSTS instance of choice, for example:

     tfx logon -u http://localhost:8080/tfs/MyCollection --token <token>

(You can create a token from your "Security" settings in TFS/VSTS). I recommend setting
the `TFX_TRACE` environment variable to `1` for all your work, because otherwise the
tfx utility is a little to quiet, especially and even when errors occur (e.g. a login
fails).

### Deployment

#### Deploy a local build

To deploy the result of a local build (e.g. from cloning this repo):

     tfx build tasks upload --task.path .\_build\Tasks\RunOpenCoverTask

Make sure to update at least the patch version in your `task.json` everytime you
redeploy a new version (e.g. via `node make.js bump`).

#### Deploy from a package

To deploy the result of a release's `tasks.zip`:

     7za x -o %TEMP%\tasks tasks.zip
     tfx build tasks upload --task.path %TEMP%\tasks\RunOpenCoverTask


