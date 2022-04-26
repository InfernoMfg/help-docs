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


docker: check-platform
ifeq ($(platform), "windows")
	@git config core.filemode false
	export AWS_HOME_FOR_DOCKER="$(shell echo "$(home_dir)/.aws" | sed -E 's/cygdrive/\//g')" && \
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

#see article on passing arguments to overridden entrypoint:
#https://oprearocks.medium.com/how-to-properly-override-the-entrypoint-using-docker-run-2e081e5feb9d
build:
	docker-compose build local_development_server
	rm -f ./docs/robots.txt
	docker-compose run --entrypoint "curl" local_development_server https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/robots.txt/robots.txt --output ./docs/robots.txt
	docker-compose run --entrypoint "mkdocs" local_development_server build
	cp site/error/index.html site/404.html
	
clean-docs:
	rm -rf site/


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