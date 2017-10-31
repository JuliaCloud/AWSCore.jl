all:
	@echo "usage: make generate"
	@echo "       Generates package: ../../AWSSDK"

generate:
	JULIA_LOAD_PATH=. julia -e 'using AWSAPI; AWSAPI.generate_all()'

clean:
	rm -rf aws-sdk-js
