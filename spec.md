this is a repository that holds several essential components and configurarions between PCS. it has niri, zshrc, etc.

i want to create a bootstrap script that will run on a clean environment of debian, ubuntu or manjaro. it must install dependencies, copy zshrc, copy nvim config.

i want to have a way to test this bootstrap script. my suggestion is to create a foldwr bootstrap/ and inside it put three dockerfiles one for each system. 

the script iterate with the user, asking what he needes to install. the script will run on remote hosts, they can be a specific user or root user. consider handling both scenarios

lets begin. Your tasks
- create a folder bootstrap/
- create the script bootstrap.sh. it must install curl and zsh. Ask user what he would like to install.

- create a Dockerfile for debian 12. it must copy the script, use the script as entrypoint, the sceipt must support --no-interactive to run with default settings. the docker will execute the script and finish.
- create a makefile and add test target that builds and run and assert that the script worked.

