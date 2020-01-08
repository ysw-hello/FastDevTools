
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
    "type": "line", //图表类型 bar/line、area
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
        "text": "Byte"
    },
    "lineWidth": 0
};

//var series = [{
//              "data": [0, 0.19364817766693032, 0.38202014332566869, 0.55999999999999994, 0.72278760968653921, 0.86604444311897799, 0.98602540378443859, 1.0796926207859083, 1.1448077530122081, 1.1799999999999999, 1.1848077530122081, 1.1596926207859084, 1.1060254037844386, 1.0260444431189781, 0.9227876096865395, 0.80000000000000027, 0.66202014332566894, 0.51364817766693027, 0.3600000000000001, 0.20635182233306998, 0.057979856674331365, -0.080000000000000127, -0.20278760968653925, -0.30604444311897788, -0.38602540378443839, -0.43969262078590843, -0.464807753012208, -0.45999999999999996, -0.42480775301220808, -0.35969262078590836, -0.26602540378443906, -0.14604444311897813, -0.0027876096865395716, 0.16000000000000036, 0.33797985667433145, 0.52635182233306965, 0.71999999999999975, 0.91364817766692985, 1.1020201433256682, 1.2799999999999994, 1.4427876096865393, 1.5860444431189773, 1.7060254037844387, 1.7996926207859081, 1.864807753012208, 1.8999999999999999, 1.9048077530122081, 1.8796926207859079, 1.8260254037844392, 1.7460444431189788, 1.642787609686539],
//              "name": "2017",
//              },
//              {
//              "data": [1, 1.0148077530122079, 0.99969262078590848, 0.95602540378443868, 0.88604444311897801, 0.79278760968653939, 0.68000000000000016, 0.55202014332566884, 0.41364817766693041, 0.27000000000000007, 0.12635182233306969, -0.012020143325668697, -0.13999999999999985, -0.25278760968653935, -0.34604444311897792, -0.41602540378443847, -0.45969262078590833, -0.47480775301220801, -0.45999999999999996, -0.41480775301220807, -0.33969262078590845, -0.23602540378443859, -0.10604444311897798, 0.047212390313460584, 0.21999999999999953, 0.40797985667433145, 0.60635182233306972, 0.80999999999999983, 1.0136481776669299, 1.212020143325669, 1.3999999999999995, 1.5727876096865394, 1.7260444431189779, 1.8560254037844388, 1.9596926207859084, 2.034807753012208, 2.0800000000000001, 2.0948077530122085, 2.0796926207859086, 2.0360254037844392, 1.9660444431189781, 1.8727876096865401, 1.7599999999999998, 1.6320201433256696, 1.4936481776669306, 1.3500000000000003, 1.2063518223330703, 1.0679798566743302, 0.94000000000000072, 0.8272123903134615, 0.73395555688102165],
//              "name": "2018",
//              }
//              ];

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

