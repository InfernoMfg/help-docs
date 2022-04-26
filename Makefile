SHELL:=/bin/bash
in_cygwin := $(shell which cygpath 1> /dev/null 2> /dev/null;  echo $$?)
home_dir := $(shell echo "$$HOME")
curr_dir := $(shell pwd)

env=dev
region=us-east-1
bucket-name=inferno-mfg-corp-docs-dev
terraform-backend-region=us-east-1
terraform-backend-bucket=tf-state-infernomfg-$(terraform-backend-region)-$(env)
terraform-backend-key="tf-docs.tfstate"
app-name=docs

ifeq (0, $(in_cygwin))
	platform := "windows"
else
	platform := "unix"
endif

##########################################################################################
# run terraform directives from inside container (make docker, >>make plan)
##########################################################################################
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

gheconfig:
	git config --global url."https://$$GITHUB_PERSONAL_USERNAME:$$GITHUB_PERSONAL_TOKEN@github.com".insteadOf "https://github.com"

init: gheconfig check-env check-region clean-tf
	terraform init -backend-config="bucket=$(terraform-backend-bucket)" -backend-config="region=$(terraform-backend-region)"

clean-tf:
	rm -rf temp/
	rm -rf .terraform
	rm -rf .tfplan

plan: check-bucket-name check-env check-region init
	eval "$$(buildenv -e $(env) -d $(region))" && \
	terraform fmt && \
	terraform plan -out=$(env).tfplan -state="$(terraform-backend-key)" -var bucket_name=$(bucket-name)

apply: check-env check-region
	eval "$$(buildenv -e $(env) -d $(region))" && \
	terraform apply -state-out="$(terraform-backend-key)" $(env).tfplan 

##########################################################################################
# run serve/build/deploy-s3 commands from local machine
##########################################################################################
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
	
deploy-s3: check-bucket-name clean-docs build
ifeq ($(platform), "windows")
	@git config core.filemode false
	export AWS_HOME_FOR_DOCKER="$(shell echo "$(home_dir)/.aws" | sed -E 's/cygdrive/\//g')" && \
	export CURR_DIR_FOR_DOCKER="$(shell echo $(curr_dir) | sed -E 's/cygdrive/\//g')" && \
	docker-compose -f $(platform).yml run --rm --entrypoint "aws" $(platform) s3 sync --size-only --sse AES256 --acl public-read ./site/ s3://$(bucket-name)
endif
ifeq ($(platform), "unix")
	docker-compose -f $(platform).yml run --rm --entrypoint "aws" $(platform) s3 sync --size-only --sse AES256 --acl public-read ./site/ s3://$(bucket-name)
endif

clean-docs:
	rm -rf site/


##########################################################################################
check-bucket-name:
ifndef bucket-name
	$(error bucket-name is not defined)
endif

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