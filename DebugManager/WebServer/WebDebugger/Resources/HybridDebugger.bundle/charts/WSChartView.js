
window.setInterval(loop, 20000); //20s轮询间隔

function loop () {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/chart/apm_read", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded", "Access-Control-Allow-Origin", "*");
    xhr.responseType = "json";
    xhr.onload = function () {
        console.log(xhr.response);
        var json = xhr.response;
        if (json.code == 200 && json.data.sender) {
            var data = json.data;
            var sender = data.sender?data.sender:{};
            var receivedWidth = data.receivedWidth?data.receivedWidth:'0';
            var receivedHeight = data.receivedHeight?data.receivedHeight:'0';
            var isWKWebView = data.isWKWebView?data.isWKWebView:'1';
            loadTheHighChartView(sender,receivedWidth,receivedHeight,isWKWebView);
        }
    };
    var timestamp = Math.round(new Date() / 1000); //精确到秒
    var param = JSON.stringify({type:"cpu", interval:timestamp});
    xhr.send(param);
}

