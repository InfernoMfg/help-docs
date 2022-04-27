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
	docker-compose -f $(platform).yml run --rm $(platform)
endif
ifeq ($(platform), "unix")
	docker-compose -f $(platform).yml run --rm $(platform)
endif 

stop: 
	docker-compose down --remove-orphans

serve:
	docker-compose run --service-ports local_development_server

##########################################################################################
# run build/deploy commands from docker container
##########################################################################################
build:
	@pip install -r ./requirements.txt
	@mkdocs build

prompt-for-passphrase:
	@echo ">>>>>>>>>>>>>>>>>>>> enter private key passphrase when prompted"

deploy:
	chmod 600 /root/.ssh/
	@$(MAKE) clean-docs 
	@$(MAKE) build
	@$(MAKE) prompt-for-passphrase
	@eval `ssh-agent -s` && ssh-add /root/.ssh/id_ed25519 && mkdocs gh-deploy
	
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