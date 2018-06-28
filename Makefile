all: stop clean start enter

init: 
	ln -sf "$(shell pwd)/storage.lua" "$(shell pwd)/storage_1_a.lua" 
	ln -sf "$(shell pwd)/storage.lua" "$(shell pwd)/storage_1_b.lua" 
	ln -sf "$(shell pwd)/storage.lua" "$(shell pwd)/storage_2_a.lua" 
	ln -sf "$(shell pwd)/storage.lua" "$(shell pwd)/storage_2_b.lua" 
	
start:
	tarantoolctl start storage_1_a
	tarantoolctl start storage_1_b
	tarantoolctl start storage_2_a
	tarantoolctl start storage_2_b
	tarantoolctl start router
	@echo "Waiting cluster to start"
	@sleep 1
	echo "vshard.router.bootstrap()" | tarantoolctl enter router

stop:
	tarantoolctl stop storage_1_a
	tarantoolctl stop storage_1_b
	tarantoolctl stop storage_2_a
	tarantoolctl stop storage_2_b
	tarantoolctl stop router

enter:
	tarantoolctl enter router

logcat:
	tail -f data/*.log

clean:
	rm -rf data/

.PHONY: console test deploy clean
