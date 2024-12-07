app-install:
	cd src/lambda/hono-app && npm install

app-dev:
	cd src/lambda/hono-app && npm run dev

app-build:
	cd src/lambda/hono-app && npm run build

# run the built app to make sure it works as expected. LWA will use run.sh to start the app
app-preview:
	cd src/lambda/hono-app/dist && ./run.sh

tf-init:
	tofu init --upgrade

tf-plan:
	tofu plan

tf-apply:
	tofu apply

tf-destroy:
	tofu destroy
