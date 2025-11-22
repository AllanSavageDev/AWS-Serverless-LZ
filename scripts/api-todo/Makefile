LAMBDA_SRC := lambda_handler.py
ZIP_FILE   := lambda_payload.zip
ENV_DIR    := ../../envs/test
DEPS_DIR   := tmp_deps

build:
	@echo "📦 Building Lambda package..."
	rm -rf $(DEPS_DIR) $(ZIP_FILE) __pycache__ >/dev/null 2>&1 || true
	pip3 install -r requirements.txt -t $(DEPS_DIR) >/dev/null
	cd $(DEPS_DIR) && zip -r9 ../$(ZIP_FILE) . >/dev/null
	zip -g $(ZIP_FILE) $(LAMBDA_SRC) *.py >/dev/null
	@echo "✅ Package ready for Lambda: $(ZIP_FILE)"

plan:
	cd $(ENV_DIR) && terraform plan -target=aws_lambda_function.t5-api-todo

apply:
	cd $(ENV_DIR) && terraform apply -target=aws_lambda_function.t5-api-todo -auto-approve



deploy: build apply

clean:
	rm -rf $(ZIP_FILE) $(DEPS_DIR)
