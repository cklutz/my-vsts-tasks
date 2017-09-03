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