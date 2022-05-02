# help-docs

## test
to test changes locally, navigate to the help-docs project folder and then run the serve directive:

```
make serve
```
then open [http://localhost:7000/help-docs/](http://localhost:7000/help-docs/) in browser  

## deploy
to publish changes to [https://infernomfg.github.io/help-docs/](https://infernomfg.github.io/help-docs/), first enter the default docker container and then run the deploy directive:
```
make docker
make deploy
```
you will be prompted to enter your github ssh key passphrase.  copy/paste this into the terminal when prompted and then hit enter.

