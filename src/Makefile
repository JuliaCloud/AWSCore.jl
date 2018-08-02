all:
	@echo "usage: make generate"
	@echo "       Generates package: ../../AWSSDK"

generate:
	julia07  -e 'push!(LOAD_PATH, "."); using AWSAPI; AWSAPI.generate_all()'

clean:
	rm -rf aws-sdk-js
