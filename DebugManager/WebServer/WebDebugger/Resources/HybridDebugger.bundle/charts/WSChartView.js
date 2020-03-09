
window.setInterval(loop, 10000); //10s轮询间隔

//主标题
var title = {
    "style":{
        "color":"#abc123",
        "fontSize": "16px",
        "fontWeight": "regular"
    },
    "text": ""
};

//子标题
var subtitle = {
    "align": "left",
    "style": {
        "color": "#000000",
        "fontSize": "9px",
        "fontWeight": "regular"
    },
    "text": ""
};

//图表配置
var chart = {
    "polar": false, //极地图
    "type": "area", //图表类型 bar/line、area
    "panning": true, //平移
};

//数据列配置
var plotOptions = {
    "line": {},
    "series": {
        "marker": {
            "radius": 5
        },
        "stacking": "normal", //普通堆叠
    }
};

//提示框
var tooltip = {
    "enabled": true,
    "shared": true,
};

//x轴
var xAxis = {
    "labels": {
        "style": {
            "color": "#778899",
            "fontSize": "11px",
            "fontWeight": "thin"
        },
    },
    "tickmarkPlacement": "on",
    "type":"datetime",
};

//y轴
var yAxis = {
    "gridLineWidth": 1,
    "labels": {
        "style": {
            "color": "#778899",
            "fontSize": "11px",
            "fontWeight": "thin"
        },
        "format": "{value:.,0f}"
    },
    "title": {
        "text": "MB"
    },
    "lineWidth": 0
};

function createSender (series, titleName, subtitleName, xAxis_maxZoom) {
    title["text"] = titleName;
    subtitle["text"] = subtitleName;
    xAxis["maxZoom"] = xAxis_maxZoom;
    
    var sender = {
        title : title,
        subtitle : subtitle,
        xAxis : xAxis,
        yAxis : yAxis,
        chart : chart,
        plotOptions : plotOptions,
        tooltip : tooltip,
        series : series
    };
    
    return JSON.stringify(sender);
}

var receivedWidth = 0;
var receivedHeight = 500;
var isWKWebView = 1;

function loop (isFirst) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/chart/apm_read", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded", "Access-Control-Allow-Origin", "*");
    xhr.responseType = "json";
    xhr.onload = function () {
        console.log(xhr.response);
        var json = xhr.response;
        if (json.code == 200 && json.data) {
            var data = json.data;
            var sender = createSender(data.series, data.titleName, data.subtitleName, data.xAxis_maxZoom);
           
//            if (isFirst) {
                loadTheHighChartView(sender,receivedWidth,receivedHeight,isWKWebView);
//            } else {
//                onlyRefreshTheChartDataWithSeries(JSON.stringify(data.series));
//            }
        }
    };
    var timestamp = Math.round(new Date() / 1000); //精确到秒
    var param = JSON.stringify({type:"apm_memory", interval:timestamp});
    xhr.send(param);
}

