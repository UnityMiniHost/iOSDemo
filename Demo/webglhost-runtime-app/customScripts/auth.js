console.info("[Host] auth.js starts");

// 访问cusObj对象
cusObj.userId = "10001";

tj.login = function (obj) {
    tj.customCommand("TJLoginHost", {
        username: cusObj.userId,
        success: function(res) {
            console.info("[Host] TJLoginHost success res", res);
            obj.success(res);
        },
        fail: function(res) {
            console.info("[Host] TJLoginHost fail res", res);
            let apiRes = {
                errMsg: res.errorMsg,
                errno: res.errorCode
            };
            obj.fail(apiRes);
        },
        complete: function() {
            console.info("[Host] TJLoginHost complete");
            obj.complete();
        }
    })
};
