# Additional tasks for VSTS / TFS Build.

Most of the build and test infrastructure is copied from [Microsoft's VSTS Tasks](https://github.com/Microsoft/vsts-tasks).

Currently, there is only one task:

* _RunOpenCover_, runs vstest.console.exe as a target with OpenCover.Console.exe. Additionally, the relevant code can also be called from a PowerShell script build task (`RunOpenCover.ps1`). The actual task is just a wrapper (`RunOpenCoverTask.ps1`), together with the necessary meta data for UI, etc.

## Build

Once, install dependencies:

     npm install

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

     tfx build tasks upload --task-path .\_build\Tasks\RunOpenCoverTask

Make sure to update at least the patch version in your `task.json` everytime you
redeploy a new version.
