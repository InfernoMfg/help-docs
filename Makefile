SHELL:=/bin/bash
in_cygwin := $(shell which cygpath 1> /dev/null 2> /dev/null;  echo $$?)
home_dir := $(shell echo "$$HOME")
curr_dir := $(shell pwd)

env=dev
region=us-east-1
app-name=help-docs
gh-deployment-branch=gh-pages

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
# run build/deploy/gh commands from docker container
##########################################################################################
build:
	@rm -f ./docs/robots.txt
	@curl https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/robots.txt/robots.txt --output ./docs/robots.txt
	@pip install -r ./requirements.txt
	@mkdocs build

gh-auth: check-env 
	eval "$$(buildenv -e $(env) -d $(region))" && \
	export GHE_TOKEN=`aws ssm get-parameters --with-decrypt --name "$$GHE_TOKEN_SSM_PATH"  | jq -r .Parameters[0].Value` && \
	echo "$$GHE_TOKEN" | gh auth login --with-token && \
	gh auth status

gh-logout: 
	gh auth logout && \
	gh auth status || true


deploy: 
	@$(MAKE) clean-docs 
	@$(MAKE) build
	@echo ">>>> enter private key passphrase when prompted"
	@eval `ssh-agent -s` && ssh-add /root/.ssh/id_ed25519 && mkdocs gh-deploy && $(MAKE) manually-deploy-404-page

manually-deploy-404-page: 
	git fetch --all
	git checkout $(gh-deployment-branch)
	git checkout origin/gh-deployment -- site/404/index.html 
	cp site/404/index.html site/404.html
	git config user.name "$$GITHUB_PERSONAL_USERNAME"
	git config user.email "$$GITHUB_PERSONAL_USERNAME@users.noreply.github.com"
	git branch --set-upstream-to origin/$(gh-deployment-branch)
	git add site/404.html
	git commit -m "override 404 page"
	git push -f

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