!function() {
    window.debuggerBridge = {
        version: "1.0.0"
    };
    
    var callbackPool = {};
    var ack_no = 1;
    
    window.debuggerBridge.isJson = function(obj) {
        var isjson = typeof(obj) == "object" && Object.prototype.toString.call(obj).toLowerCase() == "[object object]" && !obj.length;
        return isjson;
    }
    window.debuggerBridge.invoke = function(_action, _data, _callback) {
        var rndKey = 'cbk_' + new Date().getTime();
        
        //兼容处理 _data与_callback顺序混乱的问题
        if (!debuggerBridge.isjson(_data)) {
            var third = _data;
            if (debuggerBridge.isjson(_callback)) {
                _data = _callback;
            }
            if (typeof third == 'function') {
                _callback = third;
            }
        }
        
        var fullParam = {
            action: _action,
            param: _data
        };
        
        if (_callback) { //如果有回调函数。
            var rndKey = 'cbk_' + ack_no++;
            fullParam.callbackKey = rndKey;
            callbackPool[rndKey] = _callback;
        }

        fullParam = JSON.stringify(fullParam, function(key, val) {
                               if (typeof val === 'function') {
                                   return val + '';
                               }
                                return val;
                               });
        try{
            window.webkit.messageHandlers.HybridDebuggerMessageName.postMessage(fullParam);
        } catch(ex) {
            window.webkit.messageHandlers.HybridDebuggerMessageName.postMessage(ex.toString());
        }
        
    }
    var reqs = {};
    window.debuggerBridge.on = function(_action, _callback) {
        reqs[_action + ""] = _callback;
    }
    window.debuggerBridge.__fire = function(_action, _data) {
        var func = reqs[_action + ""];
        if (typeof func == 'function') {
            func(_data);
        }
    }
    window.debuggerBridge.__callback = function(_callbackKey, _param) {
        var func = callbackPool[_callbackKey];
        if (typeof func == 'function') {
            func(_param);
            // 释放,只用一次
            callbackPool[_callbackKey] = nil;
        }
    }
}(window);
