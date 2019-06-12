;
(function($, window, document) {
    $.widget("poker.lobby", {
        options: {
            widthToHeight: 4 / 3,
            epochDiff: 0,
            inchan: {},
            colData: {
                1: ["Id", "int"],
                2: ["Stakes", "string"],
                3: ["Limit", "string"],
                4: ["Seats", "int"],
                5: ["Plrs", "string"],
                6: ["Wait", "int"],
                7: ["Avg Pot", "int"],
                8: ["Plrs/Flop", "int"],
                9: ["H/hr", "int"],
                10: ["Start", "int"],
                11: ["Game", "string"],
                12: ["Buy-In", "int"],
                13: ["State", "string"],
                14: ["Enrolled", "int"],
                15: ["Table", "int"],
                16: ["Speed", "string"],
                17: ["Login", "string"],
                18: ["Name", "string"],
                19: ["Location", "string"],
                20: ["Player", "string"],
                21: ["Chips", "int"],
                22: ["Seat", "int"],
                23: ["Block", "int"],
                24: ["Player Pool", "int"],
                25: ["Rank", "int"],
                26: ["Rating", "int"]
            },
            ringCols: [1, 11, 2, 3, 4, 5, 7, 8, 9],
            leaderCols: [25, 20, 26],
            socialCols: [17, 18, 19],
            hydraCols: [1, 11, 2, 3, 4, 24],
            loginData: {},
            ringData: {},
            fastData: {},
            gameState: {
                0: "Closed",
                1: "Registering",
                2: "Late Reg.",
                3: "Full",
                4: "Playing",
                6: "Complete"
            },
            gameTabs: {
                all: ["All", 1],
                dealers: ["Dealer's Choice", 1],
                holdem: ["Hold'em", 1],
                holdemjokers: ["Hold'em (Jokers Wild)", 1],
                pineapple: ["Pineapple", 1],
                crazypine: ["Crazy Pineapple", 1],
                omaha: ["Omaha", 1],
                omahahilo: ["Omaha Hi-Lo", 1],
                omahafive: ["5 Card Omaha", 2],
                omahafivehilo: ["5 Card Omaha Hi-Lo", 2],
                courcheval: ["Courcheval", 2],
                courchevalhilo: ["Courcheval Hi-Lo", 2],
                fivedraw: ["5 Card Draw", 2],
                drawjokers: ["5 Card Draw (Jokers Wild)", 2],
                drawdeuces: ["5 Card Draw (Deuces)", 3],
                singledraw27: ["2-7 Single Draw", 3],
                tripledraw27: ["2-7 Triple Draw", 3],
                singledrawa5: ["A-5 Single Draw", 3],
                tripledrawa5: ["A-5 Triple Draw", 3],
                sevenstud: ["7 Card Stud", 3],
                razz: ["Razz", 3],
                sevenstudhilo: ["7 Card Stud Hi-Lo", 4],
                sevenstudjokers: ["7 Card Stud (Jokers)", 4],
                highchicago: ["High Chicago", 4],
                ftq: ["Follow the Queen", 4],
                bitch: ["The Bitch", 4],
                badugi: ["Badugi", 4],
                badacey: ["Badacey", 4],
                badeucy: ["Badeucy", 4]
            }
        },
        _create: function() {
            var v = this,
                e = v.options,
                f = v.element;

            // leaderboard table
            $("#lobby-leader").append(v._buildTable(e.leaderCols));

            // login button
            //$("#lobby-login").html("Log-In").click(function() {
            //    $("#login-box").show();
            //    $("#login-name").focus()
            //});

            // logout button
            $("#lobby-logout").click(function() {
                $("#poker-main").main("logout")
            });

            // build game tabs
            $("#ring-info").append(v._buildTable(e.ringCols));

            // chat form
            var si = $("#social-input");
            $("#social-form").submit(function(m) {
                m.preventDefault();
                var y = /^[\w\s\.\,\?!@#\$%^&\*\(\)_]{0,30}$/;
                if (y.test(si.val())) {
                    $("#poker-main").main("write_channel", {
                        channel: 'main',
                        message: si.val()
                    })
                }
                si.val("")
            });

            // game tabs
            $.each(e.gameTabs, function(o, m) {
                f.find("#game-tabs" + m[1]).append($("<button />").attr({
                    id: o + "-tab",
                    info: o
                }).addClass("lobby-tab").html(m[0]))
            });

            // signup
            var na = $("#new-account");
            na.submit(function(f) {
                f.preventDefault();
                na.hide();
                if ($("#signup-pw").val() !== $("#signup-cp").val()) {
                    v.modal_message("Passwords don't match")
                } else {
                    var o = {
                        username: $("#signup-un").val(),
                        password: $("#signup-pw").val()
                    };
                    if ($("#signup-em").val()) {
                        o.email = h.val()
                    }
                    $("#poker-main").main("register", o)
                }
            });

            $("#new-account .modal-ok").html("OK").click(function() {
                $("#signup-form").submit()
            });
            $("new-account .modal-cancel").html("Cancel").click(function() {
                na.hide()
            });

            // clicking behavior
            f.on("click", "#tabs .lobby-tab", function() {
                    var m = $(this);
                    f.find("#tabs > [type=" + m.parent().attr("type") + "] .lobby-tab.select").removeClass("select");
                    m.addClass("select")
                })
                .on("click", "#tabs > [type=game] .lobby-tab", function() {
                    var y = $(this).attr("info");
                    var o = f.find(".tab-info.games tbody tr");
                    if (y == "all") {
                        o.show()
                    } else {
                        o.filter("[game_class=" + y + "]").show();
                        o.filter("[game_class!=" + y + "]").hide()
                    }

                })

                // highlighter 
                .on("click", ".tab-info tbody tr", function() {
                    var m = $(this);
                    m.siblings().removeClass("select");
                    m.addClass("select")
                })
                .on("click", "#ring-info tbody tr", function() {
                    var m = $(this).attr("table_id");
                    $("#poker-main").main("watch_table", {
                        table_id: m
                    })
                })
                // buton hoover
                .on("mouseenter", "button.lobby-tab", function() {
                    $(this).addClass("tab-hover")
                })
                .on("mouseleave", "button.lobby-tab", function() {
                    $(this).removeClass("tab-hover")
                });
            $(window).resize(function() {
                v.resizeLobby()
            });
            v.resizeLobby();
            $("#social-input").focus();


            /*
            FB.getLoginStatus(function(res) {
                if (res.status == 'connected') {
                    //FB.api('/me', {fields: "id,name,picture"}, function(res2) {
                    //alert(JSON.stringify(res2));
                    //  $("#poker-main").main("authorize", res2);
                    //});
                    $("#poker-main").main("authorize", res);
                };
            });
            // In your HTML:
            <input type="button" value="Login" onclick="FB.login();">
            <input type="button" value="Logout" onclick="FB.logout();">

            // In your onload method:
            FB.Event.subscribe('auth.login', login_event);
            FB.Event.subscribe('auth.logout', logout_event);
            // In your JavaScript code:
            var login_event = function(response) {
              console.log("login_event");
              console.log(response.status);
              console.log(response);
            }

            var logout_event = function(response) {
              console.log("logout_event");
              console.log(response.status);
              console.log(response);
            }
            */
        },
        _filter_money: function(f) {
            var e = this,
                i = e.options,
                g = e.element;
            var h = g.find(".tab-info.games.select tbody tr:visible");
            if (f == "real") {
                h.filter("[did!=1]").show();
                h.filter("[did=1]").hide()
            } else {
                if (f == "play") {
                    h.filter("[did=1]").show();
                    h.filter("[did!=1]").hide()
                }
            }
        },
        watch_table_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            $("#table-ring").append($("<div />").attr("id", "tring" + f.table_id).table_ring(f))
        },
        /*
                watch_tour_res: function(f) {
                    var e = this,
                        h = e.options,
                        g = e.element;
                    $.extend(f, {
                        tourData: h.tourData[f.tour_id],
                        tourClasses: h.tourClasses,
                        gameState: h.gameState,
                        gameTabs: h.gameTabs,
                        epochDiff: h.epochDiff
                    });
                    $("#tour-lobby").append($("<div />").attr("id", "tour" + f.tour_id).tour(f))
                },
        */
        _destroy: function() {},
        /*
                _buildRing: function(i) {
                    var q = this,
                        e = q.options,
                        f = q.element;
                    var m = f.find("#ring-box").attr("tid", i);
                    var l = e.ringData[i];
                    var r = l.small_blind + "/" + l.big_blind;
                    var j = l.game_class == "dealers" ? "--" : l.limit;
                    var p = e.gameTabs[l.game_class][0];
                    m.find(".box-header").html("(" + i + ") " + r + " " + j + " " + p);
                    var h = m.find("table tbody");
                    m.find(".box-footer").attr("tid", i);
                    h.children().remove();
                    var n = "";
                    $.each(e.ringData[i].plr_map, function(o, g) {
                        s = ++o;
                        n += "<tr><td>" + s + "</td><td>" + e.loginData[g.login_id].username + "</td><td>" + g.chips + "</td></tr>"
                    });
                    h.html(n);
                    m.show()
                },
        */
        destroy: function() {},
        register_res: function(g) {
            var f = this;
            var e;
            if (g.success) {
                e = "Registered! Welcome " + g.username + "!";
                f.login_success(g)
            } else {
                e = g.message
            }
            this.modal_message(e)
        },
        _buildLogin: function() {
            var g = this,
                l = g.options,
                i = g.element,
                j = i.find("#login-box"),
                e = $("<input />").attr({
                    id: "login-name",
                    name: "username",
                    placeholder: "Username",
                    type: "text",
                    maxlength: 12,
                    pattern: "[A-Za-z]([0-9a-zA-Z_]){3,12}"
                }).prop({
                    autofocus: true,
                    required: true
                }),
                h = $("<input />").attr({
                    id: "login-pass",
                    placeholder: "Password",
                    maxlength: 12,
                    name: "password",
                    type: "password"
                }).prop({
                    required: true
                });
            j.append($("<div />").addClass("modal-header").html("Log-In"), $("<form />").attr("id", "login-form").append($("<div />").attr("id", "label-name").html("Username:"), e, $("<div />").attr("id", "label-pass").html("Password:"), h).submit(function(f) {
                f.preventDefault();
                $("#poker-main").main("login", {
                    username: e.val(),
                    password: h.val()
                });
                j.hide()
            }), $("<button />").attr({
                id: "login-create"
            }).html("Create New Account").click(function() {
                j.hide();
                $("#new-account").show();
                $("#signup-name").focus()
            }), $("<button />").addClass("modal-ok").html("OK").click(function() {
                $("#login-form").submit()
            }), $("<button />").addClass("modal-cancel").html("Cancel").click(function() {
                j.hide()
            }))
        },
        _buildTable: function(h) {
            var e = this,
                i = e.options,
                g = e.element;
            var f = "";
            $.each(h, function(m, j) {
                var o = i.colData[j][0];
                var l = i.colData[j][1];
                f += '<th data-sort-dir="asc" data-sort="' + l + '">' + o + "</th>"
            });
            return $("<div/>").addClass("table-box").append($("<table />").append($("<thead />").append($("<tr>").html(f)), $("<tbody />")).stupidtable().bind("aftertablesort", function(l, n) {
                $this = $(this);
                //$this.find("tbody tr:visible:first").trigger("click");
                var j = $this.find("th");
                j.find(".arro").remove();
                var m = n.direction === "asc" ? "↑" : "↓";
                j.eq(n.column).append('<span class="arro">' + m + "</span>")
            }))
        },
        resizeLobby: function(g) {
            var h = this.options,
                //e = this.element,
                newWidth = window.innerWidth * .9,
                newHeight = window.innerHeight * .9,
                newWidthToHeight = newWidth / newHeight;

            if (newWidthToHeight > h.widthToHeight) {
                newWidth = newHeight * h.widthToHeight;
            } else { // window height is too high relative to desired game height
                newHeight = newWidth / h.widthToHeight;
            }
            this.element.css({
                height: newHeight + "px",
                width: newWidth + "px",
                marginTop: (-newHeight / 2) + "px",
                marginLeft: (-newWidth / 2) + "px",
                fontSize: (newWidth / 680) + "em"
            });
        },
        guest_login: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.epochDiff = (new Date).getTime() - (f.epoch * 1000);
            h.myData = {
                login_id: f.login_id,
                username: f.username,
                chips: f.chips
            };

            $("#lobby-username").html(h.myData.username);

            h.distance = f.timer;

            var counter = $("#lobby-countdown > span");
            h.clockTimer = setInterval(function() {
                h.distance -= 1;
                var days = Math.floor(h.distance / (86400));
                var hours = Math.floor((h.distance % (86400)) / (3600));
                var minutes = Math.floor((h.distance % 3600) / 60);
                var seconds = Math.floor(h.distance % 60);
                counter.html(days + 'd ' + hours + 'h ' + minutes + 'm ' + seconds + 's');
                //counter.html(h.distance);

                if (h.distance <= 0) {
                    clearInterval(h.clockTimer);
                }
            }, 1000);
            FB.getLoginStatus(function(res) {
                if (res.status == 'connected') {
                    //FB.api('/me', {fields: "id,name,picture"}, function(res2) {
                    //alert(JSON.stringify(res2));
                    //  $("#poker-main").main("authorize", res2);
                    //});
                    $("#poker-main").main("authorize", res);
                };
            });
            FB.Event.subscribe('auth.login', e.login_event);
            FB.Event.subscribe('auth.logout', e.logout_event);

        },
        login_event: function() {
            FB.getLoginStatus(function(res) {
                if (res.status == 'connected') {
                    //FB.api('/me', {fields: "id,name,picture"}, function(res2) {
                    //alert(JSON.stringify(res2));
                    //  $("#poker-main").main("authorize", res2);
                    //});
                    $("#poker-main").main("authorize", res);
                };
            });

           //$("#poker-main").main("authorize", res2);
        },
        logout_event: function() {
           $("#poker-main").main(["logout"]);
        },
        modal_message: function(i) {
            var h = this,
                f = this.element.find("#modal-box"),
                j = $("<div />").addClass("modal-mes").html(i),
                e = $("<button />").addClass("modal-ok center").html("OK"),
                g = f.width();
            f.append(j, e.click(function() {
                f.hide()
            })).show();
            setTimeout(function() {
                f.fadeOut(1200, function() {
                    $(this).children().remove()
                })
            }, 2000)
        },
        _buildCashier: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            g.append($("<div />").attr("id", "cashier").addClass("big-modal").append($("<div />").attr("id", "cash-head").html("CASHIER"), $("<div />").attr("id", "cash-close").click(function() {
                $("#cashier").hide()
            }), $("<div />").attr("id", "cash-one").append($("<div />").attr("id", "pers-head").addClass("head").html("Personal Information"), $("<div />").attr("id", "cash-user").addClass("cash-block").append($("<div />").addClass("cash-cat").html("Username:"), $("<div />").addClass("cash-det")), $("<div />").attr("id", "cash-email").addClass("cash-block").append($("<div />").addClass("cash-cat").html("Email:"), $("<div />").addClass("cash-det")), $("<div />").attr("id", "cash-deposit").addClass("cash-block").append($("<div />").addClass("cash-cat").html("Rating:"), $("<div />").addClass("cash-det").html("0"))), $("<div />").attr("id", "cash-two").append($("<div />").attr("id", "acct-head").addClass("head").html("Account Balance"), $("<div />").attr("id", "play-head").addClass("head").html("PLAY MONEY"), $("<div />").attr("id", "play-avail").addClass("cash-block").append($("<div />").addClass("cash-cat").html("Available:"), $("<div />").addClass("cash-det")), $("<div />").attr("id", "play-inplay").addClass("cash-block").append($("<div />").addClass("cash-cat").html("In Play:"), $("<div />").addClass("cash-det")), $("<div />").attr("id", "play-total").append($("<div />").addClass("cash-cat").html("Total:"), $("<div />").addClass("cash-det"))), $("<div />").attr("id", "cash-three").append($("<button />").attr("id", "cash-reload").html("Reload Chips").click(function() {
                $("#poker-main").main("reload")
            }), $("<button />").attr("id", "cash-leave").html("Leave Cashier").click(function() {
                $("#cashier").hide()
            }))))
        },
        _updateCashier: function() {
            var f = this,
                i = f.options,
                h = f.element;
            var g;
            var e = {
                username: function(j) {
                    $("#cash-user .cash-det").html(j)
                },
                email: function(j) {
                    $("#cash-email .cash-det").html(j)
                },
                chips: function(j) {
                    $("#real-avail .cash-det").html(0);
                    $("#play-avail .cash-det").html(j[1])
                },
                ring_play: function(l) {
                    var m = 0;
                    var j = 0;
                    $.each(l, function(o, n) {
                        if (i.ringData[o].director_id == 1) {
                            m += n
                        } else {
                            j += n
                        }
                    });
                    g = m + i.myData.chips[1];
                    $("#real-inplay .cash-det").html(j);
                    $("#real-total .cash-det").html(j);
                    $("#play-inplay .cash-det").html(m);
                    $("#play-total .cash-det").html(g)
                }
            };
            $.each(i.myData, function(j, l) {
                if (j in e) {
                    e[j](l)
                }
            });
            $("#cash-deposit .cash-det").html(g + "/" + i.myData.invested[1] + " = " + Math.round(g / i.myData.invested[1] * 1000) / 1000)
        },
        login_success: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            this.options.myData = f;
            //e._buildCashier();
            //g.find("#lobby-login").html("Cashier").off("click").click(function() {
            //    $("#poker-main").main("login_info")
            //});
            $("#lobby-username").html(h.myData.username)
        },
        login_res: function(f) {
            if (f.success) {
                this.login_success(f)
                //e.modal_message("Success! Welcome " + f.username + "!");
            }
        },
        authorize_res: function(f) {
            //alert(JSON.stringify(f));
            if (f.success) {
                //h.myData = f;
                //$("#lobby-username").html(h.myData.name);
                this.options.myData.username = f.name;
                this.login_success(f)
            }

        },
        login_update: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.myData = f
        },
        login_info_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            if (f.success) {
                h.myData = f;
                e._updateCashier();
                $("#cashier").show()
            } else {
                e.modal_message(f.message)
            }
        },
        join_channel_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.inchan[f.channel] = f.success ? true : false
        },
        unjoin_channel_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.inchan[f.channel] = f.success ? false : true
        },
        notify_message: function(g) {
            var f = this,
                l = f.options,
                h = f.element;
            /* don't block
                        if (l.loginData[g.from] && l.loginData[g.from]["block"]) {
                            return
                        }
            */
            var m = l.loginData[g.from];
            var i = m ? m.username : "Guest" + g.from;
            var j = m ? m.color : "black";
            var e = h.find("#" + g.channel + "-chat");

            e.append($("<div />").addClass("chat-msg").append($("<a />").addClass("chat-handle").html(i).css("color", j), $("<span />").html(": " + g.message)));
            e.animate({
                scrollTop: e[0].scrollHeight
            })
        },
        notify_leaders: function(f) {
            //alert(JSON.stringify(f));
            var table = $("#lobby-leader tbody");
/*
            table.empty();
            $.each(f.leaders, function(index, obj) {
                var row = $("<tr >").append("<td >").html(index + 1);
                $.each(obj, function(key, value) {
                    row.append($("<td >").html(value));
                });
                table.append(row);
            });
*/
        },
        notify_login: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            this.notify_logout(f);
            f.color = "rgb(" + Math.floor(Math.random() * 256) + "," + Math.floor(Math.random() * 256) + "," + Math.floor(Math.random() * 256) + ")";
            h.loginData[f.login_id] = f;
            /*
                        g.find("#social-info .table-box tbody").append($("<tr />").attr("login_id", f.login_id).append($("<td />").html(f.username), $("<td />").addClass("block yes").click(function() {
                            var i = $(this);
                            i.toggleClass("yes");
                            if (i.hasClass("yes")) {
                                h.loginData[f.login_id]["block"] = true;
                                i.html("Yes")
                            } else {
                                h.loginData[f.login_id]["block"] = false;
                                i.html("No")
                            }
                        }).click()))
            */
        },
        notify_logout: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            delete h.loginData[f.login_id];
            g.find("#social-info .table-box tbody tr[login_id=" + f.login_id + "]").remove()
        },
        /*
        // tournament related functions
                notify_create_tour: function(f) {
                    var e = this,
                        h = e.options,
                        g = e.element;
                    e.notify_destroy_tour(f);
                    e._add_tour(f)
                },
                notify_destroy_tour: function(e) {
                    delete this.options.tourData[e.tour_id];
                    this.element.find("#ltour" + e.tour_id).remove()
                },
                tour_snap: function(f) {
                    var e = this,
                        i = e.options,
                        h = e.element;
                    var g = h.find("#tour-info tbody");
                    g.empty();
                    $.each(f, function(j, l) {
                        e._add_tour(l)
                    })
                },
                _add_tour: function(l) {
                    var p = this,
                        f = p.options,
                        h = p.element;
                    var i = h.find("#tour-info tbody");
                    var g = (new Date(l.start_time * 1000 + f.epochDiff)).toString().split(/\s/);
                    var n = g[4].split(":");
                    l.start = g[1] + " " + g[2] + " " + n[0] + ":" + n[1];
                    var j = l.game_class == "dealers" ? "--" : l.limit;
                    l.desc = l.desc ? l.desc : j + " " + f.gameTabs[l.game_class][0];
                    var e = (new Date(l.end_time * 1000 + f.epochDiff)).toString().split(/\s/);
                    var m = e[4].split(":");
                    l.end = e[1] + " " + e[2] + " " + m[0] + ":" + m[1];
                    l.class_name = f.tourClasses[l.tour_class];
                    f.tourData[l.tour_id] = l;
                    $("<tr />").attr({
                        id: "ltour" + l.tour_id,
                        tour_id: l.tour_id,
                        did: l.director_id,
                        game_class: l.game_class
                    }).append($("<td />").html(l.tour_id), $("<td />").html(l.start), $("<td />").html(l.desc), $("<td />").html(l.buy_in + l.entry_fee), $("<td />").addClass("ltour-state"), $("<td />").addClass("ltour-enrolled")).appendTo(i);
                    p._update_tour_tab(l)
                },
                _update_tour_tab: function(j) {
                    var f = this,
                        i = f.options,
                        h = f.element;
                    var g = h.find("#ltour" + j.tour_id);
                    var e = {
                        state: function(l) {
                            g.find(".ltour-state").html(i.gameState[j.state])
                        },
                        enrolled: function(l) {
                            g.find(".ltour-enrolled").html(l)
                        }
                    };
                    $.each(j, function(l, m) {
                        if (l in e) {
                            e[l](m)
                        }
                    })
                },
        */
        ring_snap: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            $.each(f, function(j, l) {
                h.ringData[l.table_id] = l
            });
            e._build_ring_tab()
        },
        _build_ring_tab: function() {
            var e = this,
                h = e.options,
                g = e.element;
            var f = g.find("#ring-info tbody");
            f.empty();
            $.each(h.ringData, function(l, j) {
                var m = j.small_blind + "/" + j.big_blind;
                var i = j.game_class == "dealers" ? "--" : j.limit;
                $("<tr />").attr({
                    id: "lring" + l,
                    table_id: j.table_id,
                    did: j.director_id,
                    game_class: j.game_class
                }).addClass("lring").append($("<td />").addClass("table-id").html(j.table_id), $("<td />").html(h.gameTabs[j.game_class][0]), $("<td />").addClass().html(m), $("<td />").addClass().html(i), $("<td />").addClass().html(j.chair_count), $("<td />").addClass("plr-count"), $("<td />").addClass("avg-pot"), $("<td />").addClass("plrs-flop"), $("<td />").addClass("hhr")).appendTo(f);
                e._update_ring_tab(j);
            });
            // g.find("#play-tab").trigger("click"));
            g.find("#all-tab").trigger("click");
            g.find("#ring-info thead th:eq(5)").trigger("click");
        },
        notify_create_ring: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.ringData[f.table_id] = f;
            e._build_ring_tab()
        },
        notify_destroy_ring: function(e) {
            delete this.options.ringData[e.table_id];
            this.element.find("#lring" + e.table_id).remove()
        },
        /*
                notify_lt_update: function(f) {
                    var e = this,
                        h = e.options,
                        g = e.element;
                    $.extend(h.tourData[f.tour_id], f);
                    e._update_tour_tab(f)
                },
        */
        notify_lr_update: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            $.extend(h.ringData[f.table_id], f);
            e._update_ring_tab(f)
        },
        _update_ring_tab: function(g) {
            var f = this,
                j = f.options,
                i = f.element;
            var h = i.find("#lring" + g.table_id);
            /*
                        if (i.find("#ring-box").attr("tid") == g.table_id) {
                            h.trigger("click")
                        }
            */
            var e = {
                avg_pot: function(l) {
                    h.find(".avg-pot").html(l)
                },
                plrs_flop: function(l) {
                    h.find(".plrs-flop").html(l)
                },
                hhr: function(l) {
                    h.find(".hhr").html(l)
                },
                plr_map: function(m) {
                    var n = h.find(".plr-count");
                    var l = 0;
                    for (k in m) {
                        l++
                    }
                    n.html(l)
                }
            };
            $.each(g, function(l, m) {
                if (l in e) {
                    e[l](m)
                }
            })
        },
        _msgHandler: function(g, f) {
            var e = {};
            if (g in e) {
                e[g](f)
            }
        },
        _setOption: function(g, i) {
            var f = this,
                j = f.options,
                h = f.element;
            var e = {};
            if (g in e) {
                j[g] = i;
                e[g](i)
            }
        }
    })
})(jQuery, window, document);
