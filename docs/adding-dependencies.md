## How to add dependencies (packages or otherwise) to this code base
### AUTHOR: Cole
### DATE: 04 January 2026

We need to be able to keep a running version of this repository that has all the required packages to run the project on the actual main branch. When we're adding an R package (as the easiest example) to our workflow, the following protocol should be used: 

1. First, one should be on a development branch -- no code development should happen on the main branch 
2. If you're trialing a package, inside the container terminal just use something like `pak::pkg_install("newpackage")` and you'll have access in the current sesssion to that package. Note though, that that package will NOT be permanent in the container. As you're working, keep track somehow of what packages you're trialing, and which ones you'll need to keep longer term.
3. Once you're happy with the packages / suite of tools you're using to do a task and are ready to make a pull request, add all the new packages to the `DESCRIPTION` file and rebuild the container. This can be done easily in VS Code with the command palette and then `Dev Containers: Rebuild Container`
4. Test that the new installs work and everything is working fine!