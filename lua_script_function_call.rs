use mlua::prelude::*;
use mlua::{Function, Value as LuaValue};
use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use moka::future::Cache;
use once_cell::sync::OnceCell;
use crate::engine::lua_engine::LuaEngine;


lazy_static::lazy_static! {
   static ref GLOBAL_LUA_SCRIPT_CACHE: Cache<String, String>= {
            // 创建一个缓存，容量为 200，条目
    let cache = Cache::builder()
        .max_capacity(200)
        // time_to_live（生存时间）参数设置缓存条目的固定存活时间。无论条目是否被访问，只要存活时间到期，条目就会被自动移除
        .time_to_live(Duration::from_secs(60 * 60))// 最大存活60分钟
        // time_to_idle（闲置时间）参数设置条目在闲置状态下的存活时间。如果在指定的时间内条目没有被访问，它就会被移除。
        .time_to_idle(Duration::from_secs(60 * 30))// 最大空闲30分钟
        // expire_after 参数允许对条目过期的策略进行更细粒度的控制，可以基于自定义逻辑确定条目何时过期。它可以同时包含 create, update 和 access 三种过期策略。
        // .expire_after(Duration::from_secs(30)) // 基于创建时间的过期策略，设置为30秒
        .build();
   cache
  };
}


async fn load_script(path: &str) -> LuaResult<()> {
    if !GLOBAL_LUA_SCRIPT_CACHE.contains_key(path) {
        let script_content = std::fs::read_to_string(path).unwrap();
        GLOBAL_LUA_SCRIPT_CACHE.insert(path.to_string(), script_content).await;
    }
    Ok(())
}

fn get_script(path: &str) -> Option<&String> {
    GLOBAL_LUA_SCRIPT_CACHE.get(path)
}


#[derive(Deserialize)]
struct LuaPayload {
    path: String,
    function: String,
    args: Vec<JsonValue>,
}



fn json_to_lua_value(lua: &Lua, json_value: JsonValue) -> LuaResult<LuaValue> {
    match json_value {
        JsonValue::Null => Ok(LuaValue::Nil),
        JsonValue::Bool(b) => Ok(LuaValue::Boolean(b)),
        JsonValue::Number(n) => {
            if let Some(i) = n.as_i64() {
                Ok(LuaValue::Integer(i))
            } else if let Some(f) = n.as_f64() {
                Ok(LuaValue::Number(f))
            } else {
                Err(LuaError::RuntimeError("Invalid JSON number".to_string()))
            }
        }
        JsonValue::String(s) => Ok(LuaValue::String(lua.create_string(&s)?)),
        JsonValue::Array(arr) => {
            let tbl = lua.create_table()?;
            for (i, val) in arr.into_iter().enumerate() {
                tbl.set(i + 1, json_to_lua_value(lua, val)?)?;
            }
            Ok(LuaValue::Table(tbl))
        }
        JsonValue::Object(obj) => {
            let tbl = lua.create_table()?;
            for (k, val) in obj.into_iter() {
                tbl.set(k, json_to_lua_value(lua, val)?)?;
            }
            Ok(LuaValue::Table(tbl))
        }
    }
}



fn handle_lua_request(json_payload: &str) -> LuaResult<()> {
    let payload: LuaPayload = serde_json::from_str(json_payload)?;
    let lua = Lua::new();

    // 加载Lua脚本到缓存
    load_script(&payload.path)?;

    // 获取脚本内容
    let script_content = get_script(&payload.path).ok_or_else(|| {
        LuaError::RuntimeError(format!("Script not found: {}", payload.path))
    })?;

    // 执行脚本内容，获取返回的表
    let lua_table: LuaTable = lua.load(script_content.as_str()).eval()?;

    // 获取函数对象
    let func: LuaFunction = lua_table.get(payload.function)?;

    // 将JSON参数转换为Lua参数
    let lua_args = json_to_lua_value(&lua, payload.args)?;

    // 调用Lua函数
    func.call::<_, ()>(lua_args)?;

    Ok(())
}