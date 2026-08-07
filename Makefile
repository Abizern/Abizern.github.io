.PHONY: help clean build preview

.DEFAULT_GOAL := help

help: ## Show this list of commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

clean: ## Delete the content and public folders
	rm -rf content public

build: ## Delete the public folder and build the site with hugo
	rm -rf public
	hugo --gc --minify

preview: ## Run the local preview server with drafts
	hugo server -D
