SHELL:=/bin/bash
in_cygwin := $(shell which cygpath 1> /dev/null 2> /dev/null;  echo $$?)
home_dir := $(shell echo "$$HOME")
curr_dir := $(shell pwd)

env=dev
region=us-east-1
app-name=help-docs

ifeq (0, $(in_cygwin))
	platform := "windows"
else
	platform := "unix"
endif

##########################################################################################
# run docker/serve/stop commands from local machine
##########################################################################################
docker: check-platform
ifeq ($(platform), "windows")
	@git config core.filemode false
	export AWS_HOME_FOR_DOCKER="$(shell echo "$(home_dir)/.aws" | sed -E 's/cygdrive/\//g')" && \
	export SSH_HOME_FOR_DOCKER="$(shell echo "$(home_dir)/.ssh" | sed -E 's/cygdrive/\//g')" && \
	export CURR_DIR_FOR_DOCKER="$(shell echo $(curr_dir) | sed -E 's/cygdrive/\//g')" && \
	export DOCKER_FROM_WINDOWS="1" && \
	docker-compose -f $(platform).yml run --rm $(platform)
endif
ifeq ($(platform), "unix")
	docker-compose -f $(platform).yml run --rm $(platform)
endif 

stop: 
	docker-compose down --remove-orphans

serve:
	docker-compose run --service-ports local_development_server

open-local:
	open http://0.0.0.0:7000/help-docs/

open:
	open https://infernomfg.github.io/help-docs/

##########################################################################################
# run build/deploy commands from docker container
##########################################################################################
build:
	@pip install -r ./requirements.txt
	@mkdocs build

prompt-for-passphrase:
	@echo ">>>>>>>>>>>>>>>>>>>> enter private key passphrase when prompted"

deploy:
	$(MAKE) fix-ssh-permissions
	@$(MAKE) clean-docs 
	@$(MAKE) build
	@$(MAKE) prompt-for-passphrase
	@eval `ssh-agent -s` && ssh-add /root/.ssh/id_ed25519 && mkdocs gh-deploy

fix-ssh-permissions:
ifdef DOCKER_FROM_WINDOWS
	chmod 0700 /root/.ssh/
	chmod 0600 /root/.ssh/id_ed25519
	chmod 0600 /root/.ssh/config
	chmod 0644 /root/.ssh/id_ed25519.pub
	chmod 0644 /root/.ssh/known_hosts
endif

clean-docs:
	@rm -rf site/


##########################################################################################
check-env:
ifndef env
	$(error env is not defined)
endif

check-region:
ifndef region
	$(error region is not defined)
endif

check-platform:
ifndef platform
	$(error platform is not defined)
endif
