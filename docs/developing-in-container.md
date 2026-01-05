## How to develop this code base inside a container 
### AUTHOR: Cole
### DATE: 04 January 2026

There are lots of ways to develop inside a container, and we're not making a statement about which one is best. This is just a quick how-to for ourselves and anyone else who comes along who wants to develop part of the workflow and ensure that the containerization is being made use of. 

We put the `/.devcontainer/devcontainer.json` file in the repo so that VS Code can create a development container based off the tools needed to work with this codebase. There's a [nice tutorial](https://code.visualstudio.com/docs/devcontainers/tutorial) that shows users how to make use of the container when they're actually developing. 