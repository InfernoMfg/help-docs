# help-docs

## test
to test changes locally, navigate to the help-docs project folder and then run the serve directive:

```
make serve
```
then open [http://localhost:7000/help-docs/](http://localhost:7000/help-docs/) in browser  
```
make open-local
```

## deploy
ensure you are on the updated main branch before proceeding
```
git checkout main
git pull
```

to publish changes to [https://infernomfg.github.io/help-docs/](https://infernomfg.github.io/help-docs/), first enter the default docker container and then run the deploy directive:
```
make docker
make deploy
```
you will be prompted to enter your github ssh key passphrase.  copy/paste this into the terminal when prompted and then hit enter.

after the deploy completes, open the website in your browser and confirm the expected changes have taken effect.  you may need to wait a few minutes for changes to appear online.

```
make open
```
