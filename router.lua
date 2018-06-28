#!/usr/bin/env tarantool
local log = require('log')
local json = require('json')
require('strict').on()

-- Call a configuration provider
cfg = require('localcfg')
cfg.listen = 3301

-- Start the database with sharding
vshard = require('vshard')
assert(vshard, 'vshard is nil')
vshard.router.cfg(cfg)


local function add_user_ctrl(req)

    local user_id = assert(tonumber(req:query_param('user_id')), "user_id is nil")
    local name = assert(req:query_param('name'), "name is nil")

    local bucket_id = vshard.router.bucket_id(user_id)
    local success, err = vshard.router.callrw(bucket_id, 'storage_api.store_user', { bucket_id, user_id, name})
    
    if success then
        return {
            status = 200,
            headers = { ['content-type'] = 'text/json; charset=utf8' },
            body = json.encode({
                status = "success",
                message = "user was added"
            }) 
        }
    end

    return {
        status = 200,
        headers = { ['content-type'] = 'text/json; charset=utf8' },
        body = json.encode({
            status = "fail",
            message = err
        })  
    }
end

local function get_user_ctrl(req)

    local user_id = assert(tonumber(req:query_param('user_id')), "user_id is nil")

    local bucket_id = vshard.router.bucket_id(user_id)
    local user, err = vshard.router.callro(bucket_id, 'storage_api.retrieve_user', {user_id})
    if user then
        return {
            status = 200,
            headers = { ['content-type'] = 'text/json; charset=utf8' },
            body = json.encode({
                status = "success",
                message = "user was retrieved",
                data = user
            })  
        }
    end

    return {
        status = 200,
        headers = { ['content-type'] = 'text/json; charset=utf8' },
        body = json.encode({
            status = "fail",
            message = (err or "user was not found")
        })  
    }
end

local function handle_request(self, req)

    if req.method == "POST" then
        return add_user_ctrl(req)
    elseif req.method == "GET" then
        return get_user_ctrl(req)   
    end

    return {
        status = 200,
        headers = { ['content-type'] = 'text/json; charset=utf8' },
        body = json.encode({
            status = "fail",
            message = "unsupported method "..req.method
        }) 
    }
end

local httpd = require('http.server').new('127.0.0.1', 8585, {handler = handle_request})
httpd:start()