all:
	@echo "usage: make generate"
	@echo "       Generates packages: ../../AWSSDK and ../../Amazon*"

generate:
	julia -e 'using AWSAPI; AWSAPI.generate_all()'
