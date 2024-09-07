use moka::sync::Cache;
use dashmap::DashMap;
use std::time::Duration;
use lazy_static::lazy_static;
use mlua::{Lua, UserData, UserDataFields, UserDataMethods};
use crate::engine::lua_engine::LuaEngine;
use crate::set_global_module;

lazy_static! {
     static ref GLOBAL_CACHE_MANAGER:CacheManager = CacheManager::new();
}

fn get_cache_manager() -> &'static CacheManager {
    return &GLOBAL_CACHE_MANAGER;
}

/// 定义CacheManager来管理不同appid的缓存实例
pub struct CacheManager {
    // 使用Arc包装DashMap以保证CacheManager可以在线程间安全共享
    caches: DashMap<String, Cache<String, String>>,
}

fn build_cache() -> Cache<String, String> {
    Cache::builder()
        .max_capacity(100000)
        // time_to_live（生存时间）参数设置缓存条目的固定存活时间。无论条目是否被访问，只要存活时间到期，条目就会被自动移除
        .time_to_live(Duration::from_secs(60 * 60 * 4)) // 最大存活4个小时
        // time_to_idle（闲置时间）参数设置条目在闲置状态下的存活时间。如果在指定的时间内条目没有被访问，它就会被移除。
        .time_to_idle(Duration::from_secs(60 * 60)) // 最大空闲1个小时
        // expire_after 参数允许对条目过期的策略进行更细粒度的控制，可以基于自定义逻辑确定条目何时过期。它可以同时包含 create, update 和 access 三种过期策略。
        // .expire_after(Duration::from_secs(30)) // 基于创建时间的过期策略，设置为30秒
        .build()
}

impl CacheManager {
    /// 创建新的CacheManager
    pub fn new() -> Self {
        CacheManager {
            caches: DashMap::new(),
        }
    }


    /// 获取指定appid的缓存实例，如果不存在则创建一个新的实例
    fn get_cache(&self, appid: &str) -> Cache<String, String> {
        self.caches
            .entry(appid.to_string()).or_insert_with(|| build_cache())  // 如果不存在该appid的缓存实例，则创建一个容量为100的缓存
            .clone()
    }

    /// 添加数据到指定appid的缓存
    pub fn insert(&self, appid: &str, key: String, value: String) {
        let cache = self.get_cache(appid);
        cache.insert(key, value);
    }

    pub fn contains(&self, appid: &str, key: &str) -> bool {
        let mut cache = self.get_cache(appid);
        cache.contains_key(key)
    }

    /// 从指定appid的缓存中获取数据
    pub fn get(&self, appid: &str, key: &str) -> Option<String> {
        let cache = self.get_cache(appid);
        if let Some(value) = cache.get(key) {
            return Some(value.clone());
        }
        None
    }

    /// 从指定appid的缓存中移除数据
    pub fn remove(&self, appid: &str, key: &str) {
        let cache = self.get_cache(appid);
        cache.invalidate(key);
    }

    /// 清空指定appid的缓存
    pub fn clear_app_cache(&self, appid: &str) {
        let cache = self.get_cache(appid);
        cache.invalidate_all();
    }

    pub fn clear_all(&self) {
        for entry in self.caches.iter() {
            entry.value().invalidate_all();
        }
    }
}


pub fn set(lua: &Lua, (key, value): (String, String)) -> mlua::Result<()> {
    let app_id: String = lua.globals().get("APP_ID").unwrap();
    get_cache_manager().insert(app_id.as_str(), key, value);
    return Ok(());
}


pub fn contains(lua: &Lua, (key): (String)) -> mlua::Result<bool> {
    let app_id: String = lua.globals().get("APP_ID").unwrap();
    let is_exist = get_cache_manager().contains(app_id.as_str(), key.as_str());
    Ok(is_exist)
}

pub fn get(lua: &Lua, (key): (String)) -> mlua::Result<String> {
    let app_id: String = lua.globals().get("APP_ID").unwrap();
    let value_option = get_cache_manager().get(app_id.as_str(), key.as_str());
    match value_option {
        Some(value) => Ok(value),
        None => Err(mlua::Error::runtime(format!("can not find key, key:{}", key)))
    }
}

pub fn remove(lua: &Lua, (key): (String)) -> mlua::Result<()> {
    let app_id: String = lua.globals().get("APP_ID").unwrap();
    get_cache_manager().remove(app_id.as_str(), key.as_str());
    Ok(())
}

pub fn clear_app_cache(lua: &Lua, (key): (String)) -> mlua::Result<()> {
    let app_id: String = lua.globals().get("APP_ID").unwrap();
    get_cache_manager().clear_app_cache(app_id.as_str());
    Ok(())
}


// 因为使用了全局缓存对象，mlua不支持rust的智能指针和引用传递，所以我们不能使用lua的table来封装缓存对象，而是使用静态方法的方式
// 用户在lua脚本中 使用 模块名称.方法名称 直接可以操作全局缓存对象
pub fn register_lua_module1(lua_engine: &LuaEngine) {
    set_global_module!(lua_engine,"module_cache",
        [],
        [("set", set),("contains", contains),("get",get),("remove",remove),("clear_app_cache",clear_app_cache)],
        []
        );
}


// 示例主程序

#[test]
fn cache_example() {
    // 创建缓存管理器实例
    let cache_manager = CacheManager::new();

    // 使用appid "app1" 缓存数据
    cache_manager.insert("app1", "key1".to_string(), "value1".to_string());

    // 使用appid "app2" 缓存数据
    cache_manager.insert("app2", "key2".to_string(), "value2".to_string());

    // 获取appid "app1" 的缓存数据
    if let Some(value) = cache_manager.get("app1", "key1") {
        println!("App1 Key1: {}", value);
    }

    // 获取appid "app2" 的缓存数据
    if let Some(value) = cache_manager.get("app2", "key2") {
        println!("App2 Key2: {}", value);
    }

    // 删除appid "app1" 的缓存数据
    cache_manager.remove("app1", "key1");

    // 清空appid "app2" 的缓存
    cache_manager.clear_app_cache("app2");
}
