#!/usr/bin/env tarantool

require('strict').on()

-- Get instance name
local fio = require('fio')
local NAME = fio.basename(arg[0], '.lua')
local fiber = require('fiber')
local log = require('log')
local json = require('json')

-- Call a configuration provider
cfg = require('localcfg')
-- Name to uuid map
names = {
    ['storage_1_a'] = '8a274925-a26d-47fc-9e1b-af88ce939412',
    ['storage_1_b'] = '3de2e3e1-9ebe-4d0d-abb1-26d301b84633',
    ['storage_2_a'] = '1e02ae8a-afc0-4e91-ba34-843a356b8ed7',
    ['storage_2_b'] = '001688c3-66f8-4a31-8e19-036c17d489c2',
}

-- Start the database with sharding
vshard = require('vshard')
vshard.storage.cfg(cfg, names[NAME])

box.once("init", function()
    local user = box.schema.space.create('user')
    user:format({
        {'user_id', 'unsigned'},
        {'bucket_id', 'unsigned'},
        {'name', 'string'},
    })
    user:create_index('user_id', {parts = {'user_id'}})
    user:create_index('bucket_id', {parts = {'bucket_id'}, unique = false})

    box.snapshot()
    box.schema.user.grant('guest', 'read,write,execute', 'universe')
    box.schema.role.grant('public', 'execute', 'universe')
end)

local function store_user(bucket_id, user_id, name)
    local user = {user_id, bucket_id, name}
    log.info('store')
    log.info(json.encode(user))
    box.space.user:insert(user)
    return true
end

local function retrieve_user(user_id)
    log.info(user_id)
    local user = box.space.user:get(user_id)
    log.info(json.encode(user))
    return user
end

storage_api  = {
    store_user = store_user,
    retrieve_user = retrieve_user
}
