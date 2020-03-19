// HASH MAP
function HashMap() {
    var e = [];
    return e.size = function () {
        return this.length
    }, e.isEmpty = function () {
        return 0 === this.length
    }, e.containsKey = function (e) {
        e += "";
        for (var t = 0; t < this.length; t++)
            if (this[t].key === e) return t;
        return -1
    }, e.get = function (e) {
        e += "";
        var t = this.containsKey(e);
        if (t > -1) return this[t].value
    }, e.put = function (e, t) {
        if (e += "", -1 !== this.containsKey(e)) return this.get(e);
        this.push({
            key: e,
            value: t
        })
    }, e.allKeys = function () {
        for (var e = [], t = 0; t < this.length; t++) e.push(this[t].key);
        return e
    }, e.allIntKeys = function () {
        for (var e = [], t = 0; t < this.length; t++) e.push(parseInt(this[t].key));
        return e
    }, e.remove = function (e) {
        e += "";
        var t = this.containsKey(e);
        t > -1 && this.splice(t, 1)
    }, e.clear = function () {
        for (var e = this.allKeys(), t = 0; t < e.length; t++) {
            var r = e[t];
            this.remove(r)
        }
    }, e
}


// Video Call Client

var server = null;



function VideoCall() {
    Janus.init({
        debug: true, callback: (function () {
            if (!Janus.isWebrtcSupported()) {
                alert("No WebRTC support... ");
                return;
            }
            this.server = "http://" + window.location.hostname + ":8088/janus";
            this._onMethods = new HashMap();
            console.log("Inited the Janus successfully!")
        }).bind(this)
    });
}
VideoCall.prototype.server = null;
VideoCall.prototype.janus = null;
VideoCall.prototype.plugin = null;
VideoCall.prototype._onMethods = null;
VideoCall.prototype.myname = null;
VideoCall.prototype.peername = null;
VideoCall.prototype.isConnected = false;
VideoCall.prototype.isAttached = false;
VideoCall.prototype.jsep = {
    offer: null,
    answer: null
};

// on 
VideoCall.prototype.on = function (e, t) {
    this._onMethods.put(e, t);
}

VideoCall.prototype.callOnEvent = function (e, t) {
    var r = this._onMethods.get(e);
    r ? t ? r.call(this, t) : r.call(this) : console.log("Please implement event: " + e)
}

// connect
VideoCall.prototype.connect = function () {
    console.log("server " + this.server);
    var self = this;
    self.janus = new Janus(
        {
            server: this.server,
            success: function () {
                self.isConnected = true;
                // Attach to VideoCall plugin
                self.janus.attach(
                    {
                        plugin: "janus.plugin.videocall",
                        opaqueId: "videocalltest-" + Janus.randomString(12),
                        success: function (pluginHandle) {
                            self.plugin = pluginHandle;
                            self.isAttached = true;
                            self.callOnEvent('connected');
                            Janus.log("Plugin attached! (" + self.plugin.getPlugin() + ", id=" + self.plugin.getId() + ")");
                        },
                        onlocalstream: function (stream) {
                            Janus.log("onlocalstream");
                            self.callOnEvent('addlocalstream', stream);
                        },
                        onremotestream: function (stream) {
                            Janus.log("onremotestream");
                            self.callOnEvent('addremotestream', stream);
                        },
                        onmessage: function (msg, jsep) {
                            Janus.debug(" ::: Got a message :::");
                            Janus.debug(msg);
                            var result = msg["result"];
                            if (result !== null && result !== undefined) {
                                if (result["event"] !== undefined && result["event"] !== null) {
                                    var event = result["event"];
                                    if (event === 'connected') {
                                        self.callOnEvent('connected');
                                        Janus.lengthog("Successfully connected!")
                                    }
                                    else if (event === 'registered') {
                                        self.myname = result["username"];
                                        self.callOnEvent('registered', self.myname);
                                        Janus.log("Successfully registered as " + self.myname + "!");
                                    } else if (event === 'calling') {
                                        Janus.log("Waiting for the peer to answer...");
                                        self.callOnEvent('calling');
                                    } else if (event === 'incomingcall') {
                                        Janus.log("Incoming call from " + result["username"] + "!");
                                        self.peername = result["username"];
                                        self.jsep.answer = jsep;
                                        self.callOnEvent('incomingcall', self.peername);
                                    } else if (event === 'accepted') {
                                        var peer = result["username"];
                                        if (peer === null || peer === undefined) {
                                            Janus.log("Call started!");
                                        } else {
                                            Janus.log(peer + " accepted the call!");
                                            self.peername = peer;
                                        }
                                        // Video call can start
                                        if (jsep)
                                            self.plugin.handleRemoteJsep({ jsep: jsep });
                                        // self.plugin.send({
                                        //     "message": {
                                        //         "request": "set",
                                        //         //"record": true, 
                                        //         "time": 5
                                        //         //"filename": "/home/bangtv2/MySpace/Working/Develop/video-call/plugins/recordings"
                                        //     }
                                        // });
                                        self.callOnEvent('answered');

                                    } else if (event === 'update') {
                                        // An 'update' event may be used to provide renegotiation attempts
                                        if (jsep) {
                                            if (jsep.type === "answer") {
                                                self.plugin, handleRemoteJsep({ jsep: jsep });
                                            } else {
                                                self.plugin, createAnswer(
                                                    {
                                                        jsep: jsep,
                                                        media: { data: true },	// Let's negotiate data channels as well
                                                        success: function (jsep) {
                                                            Janus.debug("Got SDP!");
                                                            Janus.debug(jsep);
                                                            var body = { "request": "set" };
                                                            self.plugin, send({ "message": body, "jsep": jsep });
                                                        },
                                                        error: function (error) {
                                                            Janus.error("WebRTC error:", error);
                                                            bootbox.alert("WebRTC error... " + JSON.stringify(error));
                                                        }
                                                    });
                                            }
                                        }
                                    } else if (event === 'hangup') {
                                        Janus.log("Call hung up by " + result["username"] + " (" + result["reason"] + ")!");
                                        self.plugin.hangup();
                                    }
                                    else if (event === "timeout") {
                                        Janus.log("The call timeout. Hangup by user " + result["username"]);
                                        //doHangup();
                                    }
                                }
                            } else {
                                // FIXME Error?
                                var error = msg["error"];
                                bootbox.alert(error);
                                if (error.indexOf("already taken") > 0) {
                                    // FIXME Use status codes...
                                    $('#username').removeAttr('disabled').val("");
                                    $('#register').removeAttr('disabled').unbind('click').click(registerUsername);
                                }
                                // TODO Reset status
                                self.plugin, hangup();
                                if (spinner !== null && spinner !== undefined)
                                    spinner.stop();
                                $('#waitingvideo').remove();
                                $('#videos').hide();
                                $('#peer').removeAttr('disabled').val('');
                                $('#call').removeAttr('disabled').html('Call')
                                    .removeClass("btn-danger").addClass("btn-success")
                                    .unbind('click').click(doCall);
                                $('#toggleaudio').attr('disabled', true);
                                $('#togglevideo').attr('disabled', true);
                                $('#bitrate').attr('disabled', true);
                                $('#curbitrate').hide();
                                $('#curres').hide();
                                if (bitrateTimer !== null && bitrateTimer !== null)
                                    clearInterval(bitrateTimer);
                                bitrateTimer = null;
                            }
                        },
                        error: function (error) {
                            Janus.error("  -- Error attaching plugin...", error);
                            bootbox.alert("  -- Error attaching plugin... " + error);
                        }
                    });
            },
            error: function (error) {
                Janus.error(error);
                console.log("Attached plugin failed!")
            },
            destroyed: function () {
                window.location.reload();
            }
        });
    if (!self.isConnected) {
        console.log('Janus Connected');
    }
}

// register user
VideoCall.prototype.register = function (username) {
    var register = { "request": "register", "username": username };
    this.plugin.send({ "message": register });
}

// make call
VideoCall.prototype.makeCall = function (peer, options) {
    // Call this user
    var self = this;
    this.plugin.createOffer(
        {
            media: { data: false },
            stream: options.stream ? options.stream : null,
            success: function (jsep) {
                Janus.debug("Got SDP!");
                Janus.debug(jsep);
                self.jsep.offer = jsep;
                var body = { "request": "call", "username": peer };
                self.plugin.send({ "message": body, "jsep": jsep });
            },
            error: function (error) {
                Janus.error("WebRTC error...", error);
                bootbox.alert("WebRTC error... " + error);
            }
        });
}

VideoCall.prototype.answer = function (options) {
    var self = this;
    this.plugin.createAnswer(
        {
            jsep: self.jsep.answer,
            media: { data: false },	
            stream: options.stream ? options.stream : null,
            success: function (jsep) {
                Janus.debug("Got SDP!");
                Janus.debug(jsep);
                self.jsep.offer = jsep;
                var body = { "request": "accept" };
                self.plugin.send({ "message": body, "jsep": jsep });
                options.success();
            },
            error: function (error) {
                options.error(error);
            }
        });
}

VideoCall.prototype.reject = function () {
    this.hangup();
}

VideoCall.prototype.hangup = function () {
    var hangup = { "request": "hangup" };
	this.plugin.send({ "message": hangup });
	this.plugin.hangup();
}



