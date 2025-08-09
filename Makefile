.PHONY: dash

# run dashboard service
dash:
	cd dashboard && npm i && npm run build && node dist/index.js
